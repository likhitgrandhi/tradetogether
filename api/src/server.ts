import cors from "@fastify/cors";
import Fastify, {
  type FastifyInstance,
  type FastifyReply,
  type FastifyRequest
} from "fastify";
import type { SupabaseClient } from "@supabase/supabase-js";
import { loadConfig, type AppConfig } from "./config.js";
import { createSupabaseAdmin } from "./lib/supabase.js";
import { registerHealthRoutes } from "./routes/health.js";
import { registerBrokerageRoutes } from "./routes/brokerage.js";
import { registerMarketRoutes } from "./routes/markets.js";
import { registerPostRoutes } from "./routes/posts.js";
import { registerSnapTradeRoutes } from "./routes/snaptrade.js";
import { registerWebhookRoutes } from "./routes/webhooks.js";
import { BrokerageDataService } from "./services/brokerageData.js";
import { MarketDataService } from "./services/marketData.js";
import { SnapTradeSdkGateway, type SnapTradeGateway } from "./services/snaptradeGateway.js";
import { SnapTradeUserService } from "./services/snaptradeUsers.js";
import type { AuthenticatedUser } from "./types.js";

export type AppDeps = {
  config?: AppConfig;
  db?: SupabaseClient;
  snaptrade?: SnapTradeGateway;
  authenticate?: (token: string) => Promise<AuthenticatedUser | null>;
};

export async function createServer(deps: AppDeps = {}): Promise<FastifyInstance> {
  const config = deps.config ?? loadConfig();
  const db = deps.db ?? createSupabaseAdmin(config);
  const snaptrade = deps.snaptrade ?? new SnapTradeSdkGateway(config);
  const authenticate = deps.authenticate ?? createSupabaseAuthenticator(db);
  const snaptradeUsers = new SnapTradeUserService(db, snaptrade, config);
  const brokerageData = new BrokerageDataService(db, snaptrade, snaptradeUsers);
  const marketData = new MarketDataService(config);

  const app = Fastify({
    logger: config.NODE_ENV !== "test"
  });

  await app.register(cors, {
    origin: true,
    credentials: true
  });

  app.decorate("requireAuth", async (request: FastifyRequest, reply: FastifyReply) => {
    const authorization = request.headers.authorization;
    const token = authorization?.startsWith("Bearer ")
      ? authorization.slice("Bearer ".length)
      : undefined;

    if (!token) {
      return reply.code(401).send({ error: "Missing bearer token" });
    }

    const user = await authenticate(token);
    if (!user) {
      return reply.code(401).send({ error: "Invalid bearer token" });
    }

    request.authUser = user;
  });

  registerHealthRoutes(app, { config, snaptrade });
  registerMarketRoutes(app, { marketData });
  registerSnapTradeRoutes(app, { snaptradeUsers });
  registerBrokerageRoutes(app, { brokerageData });
  registerPostRoutes(app, { db });
  registerWebhookRoutes(app, { db, config });

  return app;
}

function createSupabaseAuthenticator(db: SupabaseClient) {
  return async (token: string): Promise<AuthenticatedUser | null> => {
    const { data, error } = await db.auth.getUser(token);
    if (error || !data.user) {
      return null;
    }

    return {
      id: data.user.id,
      email: data.user.email
    };
  };
}

declare module "fastify" {
  interface FastifyInstance {
    requireAuth: (request: FastifyRequest, reply: FastifyReply) => Promise<void>;
  }
}
