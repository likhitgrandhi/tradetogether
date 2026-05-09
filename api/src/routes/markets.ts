import type { FastifyInstance } from "fastify";
import { z } from "zod";
import type { MarketDataService } from "../services/marketData.js";

const symbolParams = z.object({
  symbol: z.string().min(1).max(24)
});

const candlesQuery = z.object({
  interval: z.string().optional(),
  outputsize: z.coerce.number().int().positive().max(500).optional()
});

export function registerMarketRoutes(
  app: FastifyInstance,
  deps: { marketData: MarketDataService }
) {
  app.get("/markets/:symbol/quote", async (request) => {
    const params = symbolParams.parse(request.params);
    return { quote: await deps.marketData.getQuote(params.symbol) };
  });

  app.get("/markets/:symbol/candles", async (request) => {
    const params = symbolParams.parse(request.params);
    const query = candlesQuery.parse(request.query);
    return deps.marketData.getCandles({
      symbol: params.symbol,
      interval: query.interval,
      outputsize: query.outputsize
    });
  });

  app.get("/markets/:symbol/overview", async (request) => {
    const params = symbolParams.parse(request.params);
    return deps.marketData.getOverview(params.symbol);
  });
}
