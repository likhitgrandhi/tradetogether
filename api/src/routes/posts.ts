import type { SupabaseClient } from "@supabase/supabase-js";
import type { FastifyInstance } from "fastify";
import { z } from "zod";
import type { AuthenticatedUser, JsonRecord } from "../types.js";

const createPostBody = z.object({
  body: z.string().trim().min(1).max(2000),
  verifiedTradeCandidateId: z.string().uuid().optional(),
  visibility: z.enum(["public", "followers", "private"]).default("public")
});

export function registerPostRoutes(app: FastifyInstance, deps: { db: SupabaseClient }) {
  app.get("/feed", async () => {
    const posts = await loadPosts(deps.db, (query) =>
      query
        .eq("visibility", "public")
        .order("created_at", { ascending: false })
        .limit(50)
    );

    return { posts };
  });

  app.get(
    "/posts/mine",
    {
      preHandler: app.requireAuth
    },
    async (request) => {
      const posts = await loadPosts(deps.db, (query) =>
        query
          .eq("author_id", request.authUser!.id)
          .order("created_at", { ascending: false })
          .limit(50)
      );

      return { posts };
    }
  );

  app.post(
    "/posts",
    {
      preHandler: app.requireAuth
    },
    async (request, reply) => {
      const parsedBody = createPostBody.safeParse(request.body);
      if (!parsedBody.success) {
        return reply.code(400).send({ error: "Invalid post body" });
      }

      const body = parsedBody.data;
      const source = body.verifiedTradeCandidateId ? "verified_snaptrade" : "manual";

      if (body.verifiedTradeCandidateId) {
        const { data: candidate, error: candidateError } = await deps.db
          .from("verified_trade_candidates")
          .select("id, status")
          .eq("id", body.verifiedTradeCandidateId)
          .eq("seek_user_id", request.authUser!.id)
          .maybeSingle();

        if (candidateError) {
          throw new Error(`Failed to verify trade candidate: ${candidateError.message}`);
        }
        if (!candidate) {
          return reply.code(404).send({ error: "Trade candidate not found" });
        }
        if (String((candidate as JsonRecord).status).toLowerCase() !== "open") {
          return reply.code(400).send({ error: "Only open verified trades can be posted" });
        }
      }

      const { data, error } = await deps.db
        .from("posts")
        .insert({
          author_id: request.authUser!.id,
          verified_trade_candidate_id: body.verifiedTradeCandidateId ?? null,
          source,
          body: body.body,
          visibility: body.visibility
        })
        .select("*")
        .single();

      if (error) {
        throw new Error(`Failed to create post: ${error.message}`);
      }

      const post = await loadPostById(deps.db, request.authUser!, String((data as JsonRecord).id));
      return reply.code(201).send({ post });
    }
  );
}

type PostQuery = {
  eq: (column: string, value: unknown) => PostQuery;
  order: (column: string, options: { ascending: boolean }) => PostQuery;
  limit: (count: number) => PostQuery;
  then: PromiseLike<{ data: unknown[] | null; error: { message: string } | null }>["then"];
};

async function loadPosts(
  db: SupabaseClient,
  apply: (query: PostQuery) => PostQuery
): Promise<JsonRecord[]> {
  const query = db
    .from("posts")
    .select("*, verified_trade_candidates(*, instruments(*))");
  const { data, error } = await apply(query);

  if (error) {
    throw new Error(`Failed to load posts: ${error.message}`);
  }

  return normalizePosts(db, (data ?? []) as JsonRecord[]);
}

async function loadPostById(
  db: SupabaseClient,
  user: AuthenticatedUser,
  postId: string
): Promise<JsonRecord> {
  const { data, error } = await db
    .from("posts")
    .select("*, verified_trade_candidates(*, instruments(*))")
    .eq("id", postId)
    .eq("author_id", user.id)
    .maybeSingle();

  if (error) {
    throw new Error(`Failed to load post: ${error.message}`);
  }
  if (!data) {
    throw new Error("Post not found after create");
  }

  return (await normalizePosts(db, [data as JsonRecord]))[0];
}

async function normalizePosts(db: SupabaseClient, rows: JsonRecord[]): Promise<JsonRecord[]> {
  const authorIds = [...new Set(rows.map((row) => asString(row.author_id)).filter(Boolean))] as string[];
  const profiles = await loadProfiles(db, authorIds);

  return rows.map((row) => {
    const authorId = asString(row.author_id) ?? "";
    const profile = profiles.get(authorId);
    const candidate = asRecord(row.verified_trade_candidates);
    const instrument = asRecord(candidate?.instruments);

    return {
      id: row.id,
      author: {
        id: authorId,
        handle: asString(profile?.handle) ?? "@trader",
        display_name: asString(profile?.display_name) ?? "Trader",
        avatar_url: asString(profile?.avatar_url)
      },
      source: row.source,
      body: row.body,
      visibility: row.visibility,
      created_at: row.created_at,
      verified_trade: candidate
        ? {
            id: candidate.id,
            symbol: asString(instrument?.symbol) ?? "UNKNOWN",
            instrument_name: asString(instrument?.name),
            side: candidate.side,
            status: candidate.status,
            quantity: candidate.quantity,
            entry_price: candidate.entry_price,
            mark_price: candidate.mark_price,
            exit_price: candidate.exit_price,
            realized_pnl: candidate.realized_pnl,
            unrealized_pnl: candidate.unrealized_pnl,
            return_percent: candidate.return_percent,
            provider_source_type: candidate.provider_source_type
          }
        : null
    };
  });
}

async function loadProfiles(db: SupabaseClient, authorIds: string[]): Promise<Map<string, JsonRecord>> {
  if (authorIds.length === 0) {
    return new Map();
  }

  const { data, error } = await db
    .from("app_profiles")
    .select("id, handle, display_name, avatar_url")
    .in("id", authorIds);

  if (error) {
    throw new Error(`Failed to load post authors: ${error.message}`);
  }

  return new Map(((data ?? []) as JsonRecord[]).map((profile) => [String(profile.id), profile]));
}

function asRecord(value: unknown): JsonRecord | null {
  if (Array.isArray(value)) {
    return asRecord(value[0]);
  }
  if (value && typeof value === "object") {
    return value as JsonRecord;
  }
  return null;
}

function asString(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value : undefined;
}
