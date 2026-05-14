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
  SUPABASE_ANON_KEY: "anon-key",
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

class MemorySocialDb {
  posts: Record<string, unknown>[] = [];
  profiles: Record<string, unknown>[] = [];
  candidates: Record<string, unknown>[] = [];

  from(table: string) {
    return new MemorySocialQuery(this, table);
  }
}

class MemorySocialQuery {
  private filters: Array<(row: Record<string, unknown>) => boolean> = [];
  private limitCount?: number;
  private orderColumn?: string;
  private orderAscending = true;

  constructor(
    private readonly db: MemorySocialDb,
    private readonly table: string
  ) {}

  select() {
    return this;
  }

  eq(column: string, value: unknown) {
    this.filters.push((row) => row[column] === value);
    return this;
  }

  in(column: string, values: unknown[]) {
    this.filters.push((row) => values.includes(row[column]));
    return this;
  }

  order(column: string, options: { ascending: boolean }) {
    this.orderColumn = column;
    this.orderAscending = options.ascending;
    return this;
  }

  limit(count: number) {
    this.limitCount = count;
    return this;
  }

  insert(row: Record<string, unknown>) {
    if (this.table !== "posts") {
      throw new Error(`Unexpected insert into ${this.table}`);
    }

    const created = {
      id: `post-${this.db.posts.length + 1}`,
      created_at: new Date(Date.now() + this.db.posts.length).toISOString(),
      updated_at: new Date(Date.now() + this.db.posts.length).toISOString(),
      ...row
    };
    this.db.posts.push(created);

    return {
      select: () => ({
        single: async () => ({ data: created, error: null })
      })
    };
  }

  async maybeSingle() {
    return { data: this.rows()[0] ?? null, error: null };
  }

  then<TResult1 = { data: Record<string, unknown>[]; error: null }, TResult2 = never>(
    onfulfilled?: ((value: { data: Record<string, unknown>[]; error: null }) => TResult1 | PromiseLike<TResult1>) | null,
    onrejected?: ((reason: unknown) => TResult2 | PromiseLike<TResult2>) | null
  ) {
    return Promise.resolve({ data: this.rows(), error: null }).then(onfulfilled, onrejected);
  }

  private rows() {
    let rows = this.baseRows().filter((row) => this.filters.every((filter) => filter(row)));
    if (this.orderColumn) {
      rows = [...rows].sort((left, right) => {
        const leftValue = String(left[this.orderColumn!] ?? "");
        const rightValue = String(right[this.orderColumn!] ?? "");
        return this.orderAscending ? leftValue.localeCompare(rightValue) : rightValue.localeCompare(leftValue);
      });
    }
    if (this.limitCount !== undefined) {
      rows = rows.slice(0, this.limitCount);
    }
    return rows.map((row) => this.enrich(row));
  }

  private baseRows() {
    switch (this.table) {
      case "posts":
        return this.db.posts;
      case "app_profiles":
        return this.db.profiles;
      case "verified_trade_candidates":
        return this.db.candidates;
      default:
        throw new Error(`Unexpected table ${this.table}`);
    }
  }

  private enrich(row: Record<string, unknown>) {
    if (this.table !== "posts") {
      return row;
    }

    const candidateId = row.verified_trade_candidate_id;
    const candidate = this.db.candidates.find((item) => item.id === candidateId);
    return {
      ...row,
      verified_trade_candidates: candidate ?? null
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
      createPortalLink: vi.fn(),
      removeConnection: vi.fn()
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

  it("returns public mobile app configuration", async () => {
    const app = await createServer({
      config: testConfig,
      db: new MemorySnapTradeUsersTable() as never,
      snaptrade: {
        checkStatus: vi.fn(),
        registerUser: vi.fn(),
        createPortalLink: vi.fn(),
        removeConnection: vi.fn()
      },
      authenticate: async () => ({ id: "user-1", email: "u@example.com" })
    });

    const response = await app.inject({ method: "GET", url: "/config/mobile" });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({
      apiBaseURL: "http://localhost:4000",
      supabaseURL: "https://example.supabase.co",
      supabaseAnonKey: "anon-key",
      iosDeepLinkScheme: "seek",
      authConfigured: true
    });
  });

  it("registers an authenticated SnapTrade user once", async () => {
    const snaptrade: SnapTradeGateway = {
      checkStatus: vi.fn(),
      registerUser: vi.fn().mockResolvedValue({
        userId: "seek_user1",
        userSecret: "snaptrade-secret"
      }),
      createPortalLink: vi.fn(),
      removeConnection: vi.fn()
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
      }),
      removeConnection: vi.fn()
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
        createPortalLink: vi.fn(),
        removeConnection: vi.fn()
      },
      authenticate: async () => null
    });

    const response = await app.inject({ method: "POST", url: "/snaptrade/users" });

    expect(response.statusCode).toBe(401);
  });

  it("creates a manual post with auth", async () => {
    const db = new MemorySocialDb();
    db.profiles.push({ id: "user-1", handle: "@likhit", display_name: "Likhit" });
    const app = await createServer({
      config: testConfig,
      db: db as never,
      snaptrade: emptySnaptrade(),
      authenticate: async () => ({ id: "user-1", email: "u@example.com" })
    });

    const response = await app.inject({
      method: "POST",
      url: "/posts",
      headers: authHeader(),
      payload: { body: "Watching breadth improve." }
    });

    expect(response.statusCode).toBe(201);
    expect(response.json().post).toMatchObject({
      source: "manual",
      body: "Watching breadth improve.",
      author: { id: "user-1", handle: "@likhit", display_name: "Likhit" },
      verified_trade: null
    });
  });

  it("rejects empty post bodies", async () => {
    const app = await createServer({
      config: testConfig,
      db: new MemorySocialDb() as never,
      snaptrade: emptySnaptrade(),
      authenticate: async () => ({ id: "user-1", email: "u@example.com" })
    });

    const response = await app.inject({
      method: "POST",
      url: "/posts",
      headers: authHeader(),
      payload: { body: "" }
    });

    expect(response.statusCode).toBe(400);
  });

  it("rejects verified candidates not owned by the user", async () => {
    const db = new MemorySocialDb();
    const candidateId = "11111111-1111-4111-8111-111111111111";
    db.candidates.push({ id: candidateId, seek_user_id: "other-user", status: "open" });
    const app = await createServer({
      config: testConfig,
      db: db as never,
      snaptrade: emptySnaptrade(),
      authenticate: async () => ({ id: "user-1", email: "u@example.com" })
    });

    const response = await app.inject({
      method: "POST",
      url: "/posts",
      headers: authHeader(),
      payload: { body: "Posting my active trade.", verifiedTradeCandidateId: candidateId }
    });

    expect(response.statusCode).toBe(404);
  });

  it("rejects closed verified candidates", async () => {
    const db = new MemorySocialDb();
    const candidateId = "22222222-2222-4222-8222-222222222222";
    db.candidates.push({ id: candidateId, seek_user_id: "user-1", status: "closed" });
    const app = await createServer({
      config: testConfig,
      db: db as never,
      snaptrade: emptySnaptrade(),
      authenticate: async () => ({ id: "user-1", email: "u@example.com" })
    });

    const response = await app.inject({
      method: "POST",
      url: "/posts",
      headers: authHeader(),
      payload: { body: "Posting my active trade.", verifiedTradeCandidateId: candidateId }
    });

    expect(response.statusCode).toBe(400);
  });

  it("returns public feed newest first", async () => {
    const db = new MemorySocialDb();
    db.profiles.push({ id: "user-1", handle: "@likhit", display_name: "Likhit" });
    db.posts.push(
      { id: "old", author_id: "user-1", source: "manual", body: "Old", visibility: "public", created_at: "2026-01-01T00:00:00.000Z" },
      { id: "private", author_id: "user-1", source: "manual", body: "Private", visibility: "private", created_at: "2026-01-03T00:00:00.000Z" },
      { id: "new", author_id: "user-1", source: "manual", body: "New", visibility: "public", created_at: "2026-01-02T00:00:00.000Z" }
    );
    const app = await createServer({
      config: testConfig,
      db: db as never,
      snaptrade: emptySnaptrade(),
      authenticate: async () => ({ id: "user-1", email: "u@example.com" })
    });

    const response = await app.inject({ method: "GET", url: "/feed" });

    expect(response.statusCode).toBe(200);
    expect(response.json().posts.map((post: { id: string }) => post.id)).toEqual(["new", "old"]);
  });

  it("returns only authenticated user's posts", async () => {
    const db = new MemorySocialDb();
    db.profiles.push({ id: "user-1", handle: "@likhit", display_name: "Likhit" });
    db.posts.push(
      { id: "mine", author_id: "user-1", source: "manual", body: "Mine", visibility: "public", created_at: "2026-01-01T00:00:00.000Z" },
      { id: "other", author_id: "user-2", source: "manual", body: "Other", visibility: "public", created_at: "2026-01-02T00:00:00.000Z" }
    );
    const app = await createServer({
      config: testConfig,
      db: db as never,
      snaptrade: emptySnaptrade(),
      authenticate: async () => ({ id: "user-1", email: "u@example.com" })
    });

    const response = await app.inject({
      method: "GET",
      url: "/posts/mine",
      headers: authHeader()
    });

    expect(response.statusCode).toBe(200);
    expect(response.json().posts.map((post: { id: string }) => post.id)).toEqual(["mine"]);
  });
});

function emptySnaptrade(): SnapTradeGateway {
  return {
    checkStatus: vi.fn(),
    registerUser: vi.fn(),
    createPortalLink: vi.fn(),
    removeConnection: vi.fn()
  };
}
