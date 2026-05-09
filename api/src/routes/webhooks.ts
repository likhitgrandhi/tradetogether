import crypto from "node:crypto";
import type { SupabaseClient } from "@supabase/supabase-js";
import type { FastifyInstance } from "fastify";
import type { AppConfig } from "../config.js";
import type { JsonRecord } from "../types.js";

export function registerWebhookRoutes(
  app: FastifyInstance,
  deps: { db: SupabaseClient; config: AppConfig }
) {
  app.post("/webhooks/snaptrade", async (request, reply) => {
    const payload = asRecord(request.body);
    if (!verifySignature(deps.config.SNAPTRADE_WEBHOOK_SIGNING_SECRET, payload, request.headers)) {
      return reply.code(401).send({ error: "Invalid webhook signature" });
    }

    const providerEventId = firstString(payload.id, payload.event_id, payload.webhook_id);
    const eventType = firstString(payload.event_type, payload.type);

    const { error } = await deps.db.from("snaptrade_webhook_events").upsert(
      {
        provider_event_id: providerEventId,
        event_type: eventType,
        payload
      },
      { onConflict: "provider_event_id" }
    );

    if (error) {
      throw new Error(`Failed to store webhook event: ${error.message}`);
    }

    return { received: true };
  });
}

function verifySignature(
  secret: string | undefined,
  payload: JsonRecord,
  headers: Record<string, string | string[] | undefined>
): boolean {
  if (!secret) {
    return true;
  }

  const signature = firstHeader(headers["snaptrade-signature"], headers["x-snaptrade-signature"], headers["x-signature"]);
  if (!signature) {
    return false;
  }

  const digest = crypto
    .createHmac("sha256", secret)
    .update(JSON.stringify(payload))
    .digest("hex");

  const normalizedSignature = signature.startsWith("sha256=")
    ? signature.slice("sha256=".length)
    : signature;

  const expected = Buffer.from(digest);
  const actual = Buffer.from(normalizedSignature);
  return expected.length === actual.length && crypto.timingSafeEqual(expected, actual);
}

function firstHeader(...values: Array<string | string[] | undefined>): string | null {
  for (const value of values) {
    if (typeof value === "string" && value.length > 0) {
      return value;
    }
    if (Array.isArray(value) && typeof value[0] === "string") {
      return value[0];
    }
  }
  return null;
}

function asRecord(value: unknown): JsonRecord {
  return value !== null && typeof value === "object" ? (value as JsonRecord) : {};
}

function firstString(...values: unknown[]): string | null {
  for (const value of values) {
    if (typeof value === "string" && value.length > 0) {
      return value;
    }
  }
  return null;
}
