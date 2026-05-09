import type { FastifyInstance } from "fastify";
import type { AppConfig } from "../config.js";
import type { SnapTradeGateway } from "../services/snaptradeGateway.js";

export function registerHealthRoutes(
  app: FastifyInstance,
  deps: { config: AppConfig; snaptrade: SnapTradeGateway }
) {
  app.get("/", async () => {
    return {
      name: "GrowHouse API",
      online: true,
      health: "/health",
      webhook: "/webhooks/snaptrade"
    };
  });

  app.get("/config/mobile", async () => {
    return {
      apiBaseURL: deps.config.API_BASE_URL,
      supabaseURL: deps.config.SUPABASE_URL,
      supabaseAnonKey: deps.config.SUPABASE_ANON_KEY,
      iosDeepLinkScheme: deps.config.IOS_DEEP_LINK_SCHEME,
      authConfigured: deps.config.SUPABASE_ANON_KEY.length > 0
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
