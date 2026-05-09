import type { AppConfig } from "../config.js";
import type { JsonRecord } from "../types.js";

export type MarketQuote = {
  symbol: string;
  name?: string;
  price?: number;
  change?: number;
  percentChange?: number;
  currency?: string;
  exchange?: string;
  raw: JsonRecord;
};

export type MarketCandle = {
  datetime: string;
  open: number;
  high: number;
  low: number;
  close: number;
  volume?: number;
};

export class MarketDataService {
  constructor(private readonly config: AppConfig) {}

  async getQuote(symbol: string): Promise<MarketQuote> {
    const apiKey = this.requireApiKey();
    const url = this.twelveDataURL("/quote", { symbol, apikey: apiKey });
    const raw = await this.fetchJson(url);

    return {
      symbol: firstString(raw.symbol) ?? symbol.toUpperCase(),
      name: firstString(raw.name),
      price: numberFrom(raw.close, raw.price),
      change: numberFrom(raw.change),
      percentChange: numberFrom(raw.percent_change),
      currency: firstString(raw.currency),
      exchange: firstString(raw.exchange),
      raw
    };
  }

  async getCandles(input: {
    symbol: string;
    interval?: string;
    outputsize?: number;
  }): Promise<{ symbol: string; interval: string; values: MarketCandle[] }> {
    const apiKey = this.requireApiKey();
    const interval = input.interval ?? "1day";
    const url = this.twelveDataURL("/time_series", {
      symbol: input.symbol,
      interval,
      outputsize: String(input.outputsize ?? 60),
      apikey: apiKey
    });
    const raw = await this.fetchJson(url);
    const values = Array.isArray(raw.values) ? raw.values : [];

    return {
      symbol: firstString(asRecord(raw.meta).symbol) ?? input.symbol.toUpperCase(),
      interval,
      values: values.map((value) => {
        const record = asRecord(value);
        return {
          datetime: firstString(record.datetime) ?? "",
          open: numberFrom(record.open) ?? 0,
          high: numberFrom(record.high) ?? 0,
          low: numberFrom(record.low) ?? 0,
          close: numberFrom(record.close) ?? 0,
          volume: numberFrom(record.volume)
        };
      })
    };
  }

  async getOverview(symbol: string): Promise<{
    symbol: string;
    summary: string;
    movingAsExpected: boolean | null;
    quote: MarketQuote;
  }> {
    const quote = await this.getQuote(symbol);
    const percent = quote.percentChange;
    const movingAsExpected = percent === undefined ? null : Math.abs(percent) < 3;
    const summary = percent === undefined
      ? `${quote.symbol} is ready for review once live quote data returns.`
      : `${quote.symbol} is ${percent >= 0 ? "up" : "down"} ${Math.abs(percent).toFixed(2)}% on the latest quote. Treat this as a market-data summary until the AI thesis engine is connected.`;

    return {
      symbol: quote.symbol,
      summary,
      movingAsExpected,
      quote
    };
  }

  private requireApiKey(): string {
    if (!this.config.TWELVE_DATA_API_KEY) {
      throw new Error("TWELVE_DATA_API_KEY is not configured");
    }
    return this.config.TWELVE_DATA_API_KEY;
  }

  private twelveDataURL(path: string, query: Record<string, string>): URL {
    const url = new URL(`https://api.twelvedata.com${path}`);
    for (const [key, value] of Object.entries(query)) {
      url.searchParams.set(key, value);
    }
    return url;
  }

  private async fetchJson(url: URL): Promise<JsonRecord> {
    const response = await fetch(url);
    const data = await response.json() as JsonRecord;
    if (!response.ok || firstString(data.status) === "error") {
      throw new Error(firstString(data.message) ?? `Market data request failed: ${response.status}`);
    }
    return data;
  }
}

function asRecord(value: unknown): JsonRecord {
  return value !== null && typeof value === "object" ? (value as JsonRecord) : {};
}

function firstString(...values: unknown[]): string | undefined {
  for (const value of values) {
    if (typeof value === "string" && value.length > 0) {
      return value;
    }
  }
  return undefined;
}

function numberFrom(...values: unknown[]): number | undefined {
  for (const value of values) {
    if (typeof value === "number" && Number.isFinite(value)) {
      return value;
    }
    if (typeof value === "string") {
      const parsed = Number(value.replaceAll(",", ""));
      if (Number.isFinite(parsed)) {
        return parsed;
      }
    }
  }
  return undefined;
}
