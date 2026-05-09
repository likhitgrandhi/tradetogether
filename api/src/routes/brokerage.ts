import type { FastifyInstance } from "fastify";
import { z } from "zod";
import type { BrokerageDataService } from "../services/brokerageData.js";

const syncAccountParams = z.object({
  accountId: z.string().uuid()
});

export function registerBrokerageRoutes(
  app: FastifyInstance,
  deps: { brokerageData: BrokerageDataService }
) {
  app.get(
    "/brokerage/connections",
    {
      preHandler: app.requireAuth
    },
    async (request) => {
      return { connections: await deps.brokerageData.listConnections(request.authUser!) };
    }
  );

  app.post(
    "/brokerage/connections/sync",
    {
      preHandler: app.requireAuth
    },
    async (request) => {
      return deps.brokerageData.syncConnectionsAndAccounts(request.authUser!);
    }
  );

  app.get(
    "/brokerage/accounts",
    {
      preHandler: app.requireAuth
    },
    async (request) => {
      return { accounts: await deps.brokerageData.listAccounts(request.authUser!) };
    }
  );

  app.post(
    "/brokerage/accounts/:accountId/sync",
    {
      preHandler: app.requireAuth
    },
    async (request) => {
      const params = syncAccountParams.parse(request.params);
      return deps.brokerageData.syncAccountTradeCandidates(request.authUser!, params.accountId);
    }
  );

  app.get(
    "/trade-candidates",
    {
      preHandler: app.requireAuth
    },
    async (request) => {
      return { candidates: await deps.brokerageData.listTradeCandidates(request.authUser!) };
    }
  );
}
