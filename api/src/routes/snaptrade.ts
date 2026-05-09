import type { FastifyInstance } from "fastify";
import type { SnapTradeUserService } from "../services/snaptradeUsers.js";

export function registerSnapTradeRoutes(
  app: FastifyInstance,
  deps: { snaptradeUsers: SnapTradeUserService }
) {
  app.post(
    "/snaptrade/users",
    {
      preHandler: app.requireAuth
    },
    async (request, reply) => {
      const result = await deps.snaptradeUsers.ensureRegisteredUser(request.authUser!);
      return reply.code(result.created ? 201 : 200).send(result);
    }
  );

  app.post(
    "/snaptrade/portal-link",
    {
      preHandler: app.requireAuth
    },
    async (request) => {
      return deps.snaptradeUsers.createPortalLink(request.authUser!);
    }
  );
}
