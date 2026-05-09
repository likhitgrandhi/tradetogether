import type { SupabaseClient } from "@supabase/supabase-js";
import type { FastifyInstance } from "fastify";
import { z } from "zod";

const createPostBody = z.object({
  body: z.string().min(1).max(2000),
  verifiedTradeCandidateId: z.string().uuid().optional(),
  visibility: z.enum(["public", "followers", "private"]).default("public")
});

export function registerPostRoutes(app: FastifyInstance, deps: { db: SupabaseClient }) {
  app.get("/feed", async () => {
    const { data, error } = await deps.db
      .from("posts")
      .select("*, verified_trade_candidates(*, instruments(*))")
      .eq("visibility", "public")
      .order("created_at", { ascending: false })
      .limit(50);

    if (error) {
      throw new Error(`Failed to load feed: ${error.message}`);
    }

    return { posts: data ?? [] };
  });

  app.post(
    "/posts",
    {
      preHandler: app.requireAuth
    },
    async (request, reply) => {
      const body = createPostBody.parse(request.body);
      const source = body.verifiedTradeCandidateId ? "verified_snaptrade" : "manual";

      if (body.verifiedTradeCandidateId) {
        const { data: candidate, error: candidateError } = await deps.db
          .from("verified_trade_candidates")
          .select("id")
          .eq("id", body.verifiedTradeCandidateId)
          .eq("seek_user_id", request.authUser!.id)
          .maybeSingle();

        if (candidateError) {
          throw new Error(`Failed to verify trade candidate: ${candidateError.message}`);
        }
        if (!candidate) {
          return reply.code(404).send({ error: "Trade candidate not found" });
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

      return reply.code(201).send({ post: data });
    }
  );
}
