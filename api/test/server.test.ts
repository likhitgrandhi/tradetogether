import { describe, expect, it, vi } from "vitest";
import type { AppConfig } from "../src/config.js";
import { createServer } from "../src/server.js";
import type { SnapTradeGateway } from "../src/services/snaptradeGateway.js";

const testConfig: AppConfig = {
  NODE_ENV: "test",
  PORT: 4000,
  API_BASE_URL: "http://localhost:4000",
  IOS_DEEP_LINK_SCHEME: "seek",
  SUPABASE_URL: "https://example.supabase.co",
  SUPABASE_SERVICE_ROLE_KEY: "service-role",
  SNAPTRADE_CLIENT_ID: "client-id",
  SNAPTRADE_CONSUMER_KEY: "consumer-key",
  SNAPTRADE_USER_SECRET_ENCRYPTION_KEY: Buffer.alloc(32, 1).toString("base64")
};

class MemorySnapTradeUsersTable {
  rows = new Map<string, Record<string, unknown>>();

  from(table: string) {
    if (table !== "snaptrade_users") {
      throw new Error(`Unexpected table ${table}`);
    }

    return {
      select: () => ({
        eq: (_column: string, value: string) => ({
          maybeSingle: async () => ({
            data: this.rows.get(value) ?? null,
            error: null
          })
        })
      }),
      insert: async (row: Record<string, unknown>) => {
        this.rows.set(String(row.seek_user_id), {
          ...row,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        });
        return { error: null };
      }
    };
  }
}

function authHeader(token = "valid-token") {
  return {
    authorization: `Bearer ${token}`
  };
}

describe("api server", () => {
  it("returns API and SnapTrade health", async () => {
    const snaptrade: SnapTradeGateway = {
      checkStatus: vi.fn().mockResolvedValue({ online: true, version: 153 }),
      registerUser: vi.fn(),
      createPortalLink: vi.fn()
    };
    const app = await createServer({
      config: testConfig,
      db: new MemorySnapTradeUsersTable() as never,
      snaptrade,
      authenticate: async () => ({ id: "user-1", email: "u@example.com" })
    });

    const response = await app.inject({ method: "GET", url: "/health" });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({
      api: { online: true },
      snaptrade: { online: true, version: 153 }
    });
  });

  it("registers an authenticated SnapTrade user once", async () => {
    const snaptrade: SnapTradeGateway = {
      checkStatus: vi.fn(),
      registerUser: vi.fn().mockResolvedValue({
        userId: "seek_user1",
        userSecret: "snaptrade-secret"
      }),
      createPortalLink: vi.fn()
    };
    const app = await createServer({
      config: testConfig,
      db: new MemorySnapTradeUsersTable() as never,
      snaptrade,
      authenticate: async () => ({ id: "user-1", email: "u@example.com" })
    });

    const first = await app.inject({
      method: "POST",
      url: "/snaptrade/users",
      headers: authHeader()
    });
    const second = await app.inject({
      method: "POST",
      url: "/snaptrade/users",
      headers: authHeader()
    });

    expect(first.statusCode).toBe(201);
    expect(second.statusCode).toBe(200);
    expect(first.json()).toEqual({ snapTradeUserId: "seek_user1", created: true });
    expect(second.json()).toEqual({ snapTradeUserId: "seek_user1", created: false });
    expect(snaptrade.registerUser).toHaveBeenCalledTimes(1);
  });

  it("creates a read-only connection portal link without exposing the user secret", async () => {
    const snaptrade: SnapTradeGateway = {
      checkStatus: vi.fn(),
      registerUser: vi.fn().mockResolvedValue({
        userId: "seek_user1",
        userSecret: "snaptrade-secret"
      }),
      createPortalLink: vi.fn().mockResolvedValue({
        redirectURI: "https://app.snaptrade.com/snapTrade/redeemToken?token=test",
        sessionId: "session-1"
      })
    };
    const app = await createServer({
      config: testConfig,
      db: new MemorySnapTradeUsersTable() as never,
      snaptrade,
      authenticate: async () => ({ id: "user-1", email: "u@example.com" })
    });

    const response = await app.inject({
      method: "POST",
      url: "/snaptrade/portal-link",
      headers: authHeader()
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({
      redirectURI: "https://app.snaptrade.com/snapTrade/redeemToken?token=test",
      sessionId: "session-1",
      snapTradeUserId: "seek_user1"
    });
    expect(JSON.stringify(response.json())).not.toContain("snaptrade-secret");
    expect(snaptrade.createPortalLink).toHaveBeenCalledWith({
      userId: "seek_user1",
      userSecret: "snaptrade-secret",
      customRedirect: "seek://snaptrade/callback"
    });
  });

  it("rejects SnapTrade routes without auth", async () => {
    const app = await createServer({
      config: testConfig,
      db: new MemorySnapTradeUsersTable() as never,
      snaptrade: {
        checkStatus: vi.fn(),
        registerUser: vi.fn(),
        createPortalLink: vi.fn()
      },
      authenticate: async () => null
    });

    const response = await app.inject({ method: "POST", url: "/snaptrade/users" });

    expect(response.statusCode).toBe(401);
  });
});
