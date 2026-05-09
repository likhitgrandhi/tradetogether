import type { SupabaseClient } from "@supabase/supabase-js";
import type {
  AuthenticatedUser,
  BrokerageAccountRecord,
  BrokerageConnectionRecord,
  JsonRecord
} from "../types.js";
import type { SnapTradeGateway } from "./snaptradeGateway.js";
import type { SnapTradeUserService } from "./snaptradeUsers.js";

export class BrokerageDataService {
  constructor(
    private readonly db: SupabaseClient,
    private readonly snaptrade: SnapTradeGateway,
    private readonly snaptradeUsers: SnapTradeUserService
  ) {}

  async listConnections(user: AuthenticatedUser): Promise<BrokerageConnectionRecord[]> {
    const { data, error } = await this.db
      .from("brokerage_connections")
      .select("id, seek_user_id, provider, provider_connection_id, brokerage_slug, brokerage_name, disabled")
      .eq("seek_user_id", user.id)
      .order("created_at", { ascending: false });

    if (error) {
      throw new Error(`Failed to load connections: ${error.message}`);
    }

    return (data ?? []) as BrokerageConnectionRecord[];
  }

  async listAccounts(user: AuthenticatedUser): Promise<BrokerageAccountRecord[]> {
    const { data, error } = await this.db
      .from("brokerage_accounts")
      .select("id, seek_user_id, brokerage_connection_id, provider, provider_account_id, account_name, account_number_mask, account_type, currency_code")
      .eq("seek_user_id", user.id)
      .order("created_at", { ascending: false });

    if (error) {
      throw new Error(`Failed to load accounts: ${error.message}`);
    }

    return (data ?? []) as BrokerageAccountRecord[];
  }

  async removeConnection(
    user: AuthenticatedUser,
    connectionId: string
  ): Promise<{ removed: true }> {
    const connection = await this.getConnection(user, connectionId);
    const credentials = await this.snaptradeUsers.getCredentials(user);

    await this.snaptrade.removeConnection({
      userId: credentials.snapTradeUserId,
      userSecret: credentials.userSecret,
      authorizationId: connection.provider_connection_id
    });

    const { error } = await this.db
      .from("brokerage_connections")
      .delete()
      .eq("seek_user_id", user.id)
      .eq("id", connectionId);

    if (error) {
      throw new Error(`Failed to remove connection: ${error.message}`);
    }

    return { removed: true };
  }

  async syncConnectionsAndAccounts(user: AuthenticatedUser): Promise<{
    connections: BrokerageConnectionRecord[];
    accounts: BrokerageAccountRecord[];
  }> {
    const credentials = await this.snaptradeUsers.getCredentials(user);
    const rawConnections = await this.snaptrade.listConnections({
      userId: credentials.snapTradeUserId,
      userSecret: credentials.userSecret
    });

    const connectionRows = rawConnections.map((connection) =>
      this.mapConnection(user.id, connection)
    );

    if (connectionRows.length > 0) {
      const { error } = await this.db
        .from("brokerage_connections")
        .upsert(connectionRows, { onConflict: "provider,provider_connection_id" });

      if (error) {
        throw new Error(`Failed to sync connections: ${error.message}`);
      }
    }

    const connections = await this.listConnections(user);
    const accounts: BrokerageAccountRecord[] = [];

    for (const connection of connections) {
      const rawAccounts = await this.snaptrade.listAccounts({
        userId: credentials.snapTradeUserId,
        userSecret: credentials.userSecret,
        authorizationId: connection.provider_connection_id
      });
      const accountRows = rawAccounts.map((account) =>
        this.mapAccount(user.id, connection.id, account)
      );

      if (accountRows.length > 0) {
        const { error } = await this.db
          .from("brokerage_accounts")
          .upsert(accountRows, { onConflict: "provider,provider_account_id" });

        if (error) {
          throw new Error(`Failed to sync accounts: ${error.message}`);
        }
      }
    }

    accounts.push(...(await this.listAccounts(user)));

    return { connections, accounts };
  }

  async syncAccountTradeCandidates(
    user: AuthenticatedUser,
    accountId: string
  ): Promise<{ createdOrUpdated: number }> {
    const account = await this.getAccount(user, accountId);
    const credentials = await this.snaptradeUsers.getCredentials(user);

    const [positions, optionHoldings, activities] = await Promise.all([
      this.snaptrade.listPositions({
        userId: credentials.snapTradeUserId,
        userSecret: credentials.userSecret,
        accountId: account.provider_account_id
      }),
      this.snaptrade.listOptionHoldings({
        userId: credentials.snapTradeUserId,
        userSecret: credentials.userSecret,
        accountId: account.provider_account_id
      }),
      this.snaptrade.listActivities({
        userId: credentials.snapTradeUserId,
        userSecret: credentials.userSecret,
        accountId: account.provider_account_id,
        limit: 100
      })
    ]);

    const candidates: JsonRecord[] = [];

    for (const position of positions) {
      candidates.push(await this.positionToCandidate(user.id, account, position));
    }

    for (const holding of optionHoldings) {
      candidates.push(await this.optionToCandidate(user.id, account, holding));
    }

    for (const activity of activities) {
      const candidate = await this.activityToClosedCandidate(user.id, account, activity);
      if (candidate) {
        candidates.push(candidate);
      }
    }

    if (candidates.length === 0) {
      return { createdOrUpdated: 0 };
    }

    const { error } = await this.db
      .from("verified_trade_candidates")
      .upsert(candidates, { onConflict: "provider,provider_source_type,provider_source_id" });

    if (error) {
      throw new Error(`Failed to sync trade candidates: ${error.message}`);
    }

    return { createdOrUpdated: candidates.length };
  }

  async listTradeCandidates(user: AuthenticatedUser): Promise<JsonRecord[]> {
    const { data, error } = await this.db
      .from("verified_trade_candidates")
      .select("id, side, status, quantity, entry_price, exit_price, mark_price, realized_pnl, unrealized_pnl, return_percent, provider_source_type, created_at, raw, instruments(symbol, name)")
      .eq("seek_user_id", user.id)
      .order("created_at", { ascending: false });

    if (error) {
      throw new Error(`Failed to load trade candidates: ${error.message}`);
    }

    return ((data ?? []) as JsonRecord[]).map((candidate) => {
      const instrument = asRecord(candidate.instruments);
      const raw = asRecord(candidate.raw);
      return {
        id: candidate.id,
        side: candidate.side,
        status: candidate.status,
        quantity: candidate.quantity,
        entry_price: candidate.entry_price,
        exit_price: candidate.exit_price,
        mark_price: candidate.mark_price,
        realized_pnl: candidate.realized_pnl,
        unrealized_pnl: candidate.unrealized_pnl,
        return_percent: candidate.return_percent,
        provider_source_type: candidate.provider_source_type,
        created_at: candidate.created_at,
        symbol: firstString(instrument.symbol, symbolFrom(raw)) ?? "UNKNOWN",
        instrument_name: firstString(instrument.name, instrumentNameFrom(raw), symbolFrom(raw))
      };
    });
  }

  private async getAccount(
    user: AuthenticatedUser,
    accountId: string
  ): Promise<BrokerageAccountRecord> {
    const { data, error } = await this.db
      .from("brokerage_accounts")
      .select("*")
      .eq("seek_user_id", user.id)
      .eq("id", accountId)
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to load account: ${error.message}`);
    }
    if (!data) {
      throw new Error("Account not found");
    }

    return data as BrokerageAccountRecord;
  }

  private async getConnection(
    user: AuthenticatedUser,
    connectionId: string
  ): Promise<BrokerageConnectionRecord> {
    const { data, error } = await this.db
      .from("brokerage_connections")
      .select("*")
      .eq("seek_user_id", user.id)
      .eq("id", connectionId)
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to load connection: ${error.message}`);
    }
    if (!data) {
      throw new Error("Connection not found");
    }

    return data as BrokerageConnectionRecord;
  }

  private mapConnection(seekUserId: string, raw: JsonRecord): JsonRecord {
    const brokerage = asRecord(raw.brokerage);
    const providerConnectionId = firstString(
      raw.id,
      raw.authorizationId,
      raw.authorization_id,
      raw.brokerage_authorization_id
    );

    if (!providerConnectionId) {
      throw new Error("SnapTrade connection did not include an id");
    }

    return {
      seek_user_id: seekUserId,
      provider: "snaptrade",
      provider_connection_id: providerConnectionId,
      brokerage_slug: firstString(brokerage.slug, brokerage.id, raw.brokerage_slug),
      brokerage_name: firstString(brokerage.name, raw.brokerage_name, raw.name),
      connection_type: "read",
      disabled: Boolean(raw.disabled ?? raw.is_disabled ?? false),
      disabled_at: firstString(raw.disabled_at, raw.disabledAt) ?? null,
      raw
    };
  }

  private mapAccount(
    seekUserId: string,
    brokerageConnectionId: string,
    raw: JsonRecord
  ): JsonRecord {
    const providerAccountId = firstString(raw.id, raw.account_id, raw.number);
    if (!providerAccountId) {
      throw new Error("SnapTrade account did not include an id");
    }
    const meta = asRecord(raw.meta);

    return {
      seek_user_id: seekUserId,
      brokerage_connection_id: brokerageConnectionId,
      provider: "snaptrade",
      provider_account_id: providerAccountId,
      account_name: firstString(raw.name, raw.account_name, meta.name),
      account_number_mask: firstString(raw.number, raw.account_number, raw.mask),
      account_type: firstString(raw.type, raw.account_type),
      currency_code: firstString(raw.currency, raw.currency_code),
      sync_status: {},
      raw
    };
  }

  private async positionToCandidate(
    seekUserId: string,
    account: BrokerageAccountRecord,
    raw: JsonRecord
  ): Promise<JsonRecord> {
    const symbol = symbolFrom(raw) ?? "UNKNOWN";
    const instrumentId = await this.upsertInstrument(raw, "position");
    const quantity = numberFrom(raw.units, raw.quantity, raw.shares);
    const entryPrice = numberFrom(raw.average_purchase_price, raw.averagePrice, raw.cost_basis);
    const markPrice = numberFrom(raw.price, raw.market_value_price, raw.last_price);
    const unrealizedPnl = numberFrom(raw.open_pnl, raw.unrealized_pnl, raw.unrealizedPnL);

    return {
      seek_user_id: seekUserId,
      brokerage_account_id: account.id,
      instrument_id: instrumentId,
      provider: "snaptrade",
      provider_source_type: "position",
      provider_source_id: `${account.provider_account_id}:${symbol}`,
      side: quantity === undefined || quantity >= 0 ? "long" : "short",
      status: "open",
      quantity,
      entry_price: entryPrice,
      mark_price: markPrice,
      unrealized_pnl: unrealizedPnl,
      return_percent: percentReturn(entryPrice, markPrice),
      raw
    };
  }

  private async optionToCandidate(
    seekUserId: string,
    account: BrokerageAccountRecord,
    raw: JsonRecord
  ): Promise<JsonRecord> {
    const symbol = symbolFrom(raw) ?? "OPTION";
    const instrumentId = await this.upsertInstrument(raw, "option_position");
    const quantity = numberFrom(raw.units, raw.quantity, raw.contracts);
    const entryPrice = numberFrom(raw.average_purchase_price, raw.averagePrice, raw.cost_basis);
    const markPrice = numberFrom(raw.price, raw.market_value_price, raw.last_price);
    const unrealizedPnl = numberFrom(raw.open_pnl, raw.unrealized_pnl, raw.unrealizedPnL);

    return {
      seek_user_id: seekUserId,
      brokerage_account_id: account.id,
      instrument_id: instrumentId,
      provider: "snaptrade",
      provider_source_type: "option_position",
      provider_source_id: `${account.provider_account_id}:option:${symbol}`,
      side: quantity === undefined || quantity >= 0 ? "long" : "short",
      status: "open",
      quantity,
      entry_price: entryPrice,
      mark_price: markPrice,
      unrealized_pnl: unrealizedPnl,
      return_percent: percentReturn(entryPrice, markPrice),
      raw
    };
  }

  private async activityToClosedCandidate(
    seekUserId: string,
    account: BrokerageAccountRecord,
    raw: JsonRecord
  ): Promise<JsonRecord | null> {
    const action = firstString(raw.action, raw.type, raw.transaction_type)?.toLowerCase();
    const symbol = symbolFrom(raw);
    if (!symbol || !action || !["sell", "sold", "trade"].some((term) => action.includes(term))) {
      return null;
    }

    const tradeDate = firstString(raw.trade_date, raw.settlement_date, raw.date, raw.created_at);
    const price = numberFrom(raw.price, raw.execution_price, raw.net_amount);
    const instrumentId = await this.upsertInstrument(raw, "activity");

    return {
      seek_user_id: seekUserId,
      brokerage_account_id: account.id,
      instrument_id: instrumentId,
      provider: "snaptrade",
      provider_source_type: "activity",
      provider_source_id: firstString(raw.id, raw.activity_id) ?? `${account.provider_account_id}:activity:${symbol}:${tradeDate ?? Date.now()}`,
      side: action.includes("short") ? "short" : "long",
      status: "closed",
      quantity: numberFrom(raw.units, raw.quantity),
      exit_price: price,
      realized_pnl: numberFrom(raw.realized_pnl, raw.pnl, raw.profit),
      closed_at: tradeDate,
      raw
    };
  }

  private async upsertInstrument(
    raw: JsonRecord,
    sourceType: "position" | "option_position" | "activity"
  ): Promise<string | null> {
    const instrument = instrumentFrom(raw, sourceType);
    if (!instrument) {
      return null;
    }

    const { data, error } = await this.db
      .from("instruments")
      .upsert(instrument, { onConflict: "provider,provider_symbol_id" })
      .select("id")
      .single();

    if (error) {
      throw new Error(`Failed to upsert instrument: ${error.message}`);
    }

    return firstString(asRecord(data).id);
  }
}

function asRecord(value: unknown): JsonRecord {
  return value !== null && typeof value === "object" ? (value as JsonRecord) : {};
}

function firstString(...values: unknown[]): string | null {
  for (const value of values) {
    if (typeof value === "string") {
      const trimmed = value.trim();
      if (trimmed.length > 0) {
        return trimmed;
      }
    }
    if (typeof value === "number") {
      return String(value);
    }
  }
  return null;
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

function symbolFrom(raw: JsonRecord): string | null {
  const symbol = asRecord(raw.symbol);
  const security = asRecord(raw.security);
  const universalSymbol = asRecord(raw.universal_symbol);
  const optionSymbol = asRecord(raw.option_symbol);
  const underlying = asRecord(raw.underlying_symbol);
  const instrument = asRecord(raw.instrument);
  return firstString(
    raw.symbol,
    raw.ticker,
    raw.symbol_symbol,
    raw.raw_symbol,
    symbol.symbol,
    symbol.raw_symbol,
    symbol.ticker,
    security.symbol,
    security.raw_symbol,
    universalSymbol.symbol,
    universalSymbol.raw_symbol,
    optionSymbol.symbol,
    optionSymbol.raw_symbol,
    underlying.symbol,
    underlying.raw_symbol,
    instrument.symbol,
    instrument.raw_symbol
  );
}

function instrumentFrom(
  raw: JsonRecord,
  sourceType: "position" | "option_position" | "activity"
): JsonRecord | null {
  const symbol = symbolFrom(raw);
  if (!symbol) {
    return null;
  }

  const providerSymbolId = providerSymbolIdFrom(raw, sourceType, symbol);
  const assetClass = assetClassFrom(raw, sourceType);
  const exchangeCode = exchangeCodeFrom(raw);
  const currencyCode = currencyCodeFrom(raw);

  return {
    provider: "snaptrade",
    provider_symbol_id: providerSymbolId,
    symbol,
    raw_symbol: rawSymbolFrom(raw) ?? symbol,
    name: instrumentNameFrom(raw) ?? symbol,
    asset_class: assetClass,
    exchange_code: exchangeCode,
    currency_code: currencyCode,
    polygon_ticker: polygonTickerFrom(symbol, assetClass),
    option_type: assetClass === "option" ? optionTypeFrom(raw) : null,
    strike_price: assetClass === "option" ? optionStrikeFrom(raw) : null,
    expiration_date: assetClass === "option" ? optionExpirationFrom(raw) : null,
    raw
  };
}

function providerSymbolIdFrom(
  raw: JsonRecord,
  sourceType: "position" | "option_position" | "activity",
  symbol: string
): string {
  const symbolRecord = asRecord(raw.symbol);
  const security = asRecord(raw.security);
  const universalSymbol = asRecord(raw.universal_symbol);
  const optionSymbol = asRecord(raw.option_symbol);
  const underlying = asRecord(raw.underlying_symbol);
  const instrument = asRecord(raw.instrument);
  return firstString(
    raw.symbol_id,
    raw.security_id,
    symbolRecord.id,
    security.id,
    universalSymbol.id,
    optionSymbol.id,
    underlying.id,
    instrument.id
  ) ?? `${sourceType}:${symbol}`;
}

function rawSymbolFrom(raw: JsonRecord): string | null {
  const symbol = asRecord(raw.symbol);
  const security = asRecord(raw.security);
  const universalSymbol = asRecord(raw.universal_symbol);
  const optionSymbol = asRecord(raw.option_symbol);
  return firstString(
    raw.raw_symbol,
    raw.symbol_symbol,
    symbol.raw_symbol,
    security.raw_symbol,
    universalSymbol.raw_symbol,
    optionSymbol.raw_symbol
  );
}

function instrumentNameFrom(raw: JsonRecord): string | null {
  const symbol = asRecord(raw.symbol);
  const security = asRecord(raw.security);
  const universalSymbol = asRecord(raw.universal_symbol);
  const optionSymbol = asRecord(raw.option_symbol);
  const underlying = asRecord(raw.underlying_symbol);
  const instrument = asRecord(raw.instrument);
  return firstString(
    raw.name,
    raw.description,
    raw.symbol_description,
    raw.security_name,
    symbol.name,
    symbol.description,
    symbol.symbol_description,
    security.name,
    security.description,
    universalSymbol.name,
    universalSymbol.description,
    optionSymbol.name,
    optionSymbol.description,
    underlying.name,
    underlying.description,
    instrument.name,
    instrument.description
  );
}

function assetClassFrom(
  raw: JsonRecord,
  sourceType: "position" | "option_position" | "activity"
): string {
  if (sourceType === "option_position") {
    return "option";
  }

  const symbol = asRecord(raw.symbol);
  const security = asRecord(raw.security);
  const universalSymbol = asRecord(raw.universal_symbol);
  const optionSymbol = asRecord(raw.option_symbol);
  const text = firstString(
    raw.asset_class,
    raw.security_type,
    raw.instrument_type,
    raw.type,
    symbol.type,
    security.type,
    universalSymbol.type,
    optionSymbol.type
  )?.toLowerCase();

  if (!text) {
    return "equity";
  }
  if (text.includes("option")) {
    return "option";
  }
  if (text.includes("future")) {
    return "future";
  }
  if (text.includes("crypto")) {
    return "crypto";
  }
  if (text.includes("cash") || text.includes("currency")) {
    return "cash";
  }
  if (text.includes("fund") || text.includes("etf")) {
    return "fund";
  }
  return "equity";
}

function exchangeCodeFrom(raw: JsonRecord): string | null {
  const symbol = asRecord(raw.symbol);
  const security = asRecord(raw.security);
  const universalSymbol = asRecord(raw.universal_symbol);
  const exchange = asRecord(raw.exchange);
  return firstString(
    raw.exchange_code,
    raw.exchange,
    raw.listing_exchange,
    symbol.exchange_code,
    symbol.exchange,
    security.exchange_code,
    security.exchange,
    universalSymbol.exchange_code,
    universalSymbol.exchange,
    exchange.code,
    exchange.mic_code,
    exchange.name
  );
}

function currencyCodeFrom(raw: JsonRecord): string | null {
  const symbol = asRecord(raw.symbol);
  const security = asRecord(raw.security);
  const universalSymbol = asRecord(raw.universal_symbol);
  return firstString(
    raw.currency,
    raw.currency_code,
    symbol.currency,
    symbol.currency_code,
    security.currency,
    security.currency_code,
    universalSymbol.currency,
    universalSymbol.currency_code
  );
}

function polygonTickerFrom(symbol: string, assetClass: string): string | null {
  if (assetClass !== "equity" && assetClass !== "fund") {
    return null;
  }
  return symbol;
}

function optionTypeFrom(raw: JsonRecord): string | null {
  const optionSymbol = asRecord(raw.option_symbol);
  const text = firstString(raw.option_type, raw.type, optionSymbol.option_type, optionSymbol.type)?.toLowerCase();
  if (!text) {
    return null;
  }
  if (text.includes("call")) {
    return "call";
  }
  if (text.includes("put")) {
    return "put";
  }
  return text;
}

function optionStrikeFrom(raw: JsonRecord): number | undefined {
  const optionSymbol = asRecord(raw.option_symbol);
  return numberFrom(raw.strike_price, raw.strike, optionSymbol.strike_price, optionSymbol.strike);
}

function optionExpirationFrom(raw: JsonRecord): string | null {
  const optionSymbol = asRecord(raw.option_symbol);
  const value = firstString(
    raw.expiration_date,
    raw.expiry_date,
    raw.expiration,
    raw.expiry,
    optionSymbol.expiration_date,
    optionSymbol.expiry_date,
    optionSymbol.expiration,
    optionSymbol.expiry
  );
  if (!value) {
    return null;
  }
  const dateOnly = value.match(/^\d{4}-\d{2}-\d{2}/)?.[0];
  return dateOnly ?? null;
}

function percentReturn(entryPrice?: number, markPrice?: number): number | undefined {
  if (!entryPrice || markPrice === undefined) {
    return undefined;
  }
  return ((markPrice - entryPrice) / entryPrice) * 100;
}
