import type { FastifyInstance } from "fastify";
import type { SnapTradeGateway } from "../services/snaptradeGateway.js";

export function registerHealthRoutes(
  app: FastifyInstance,
  deps: { snaptrade: SnapTradeGateway }
) {
  app.get("/", async () => {
    return {
      name: "GrowHouse API",
      online: true,
      health: "/health",
      webhook: "/webhooks/snaptrade"
    };
  });

  app.get("/health", async () => {
    const snaptrade = await deps.snaptrade.checkStatus();
    return {
      api: {
        online: true
      },
      snaptrade
    };
  });
}
