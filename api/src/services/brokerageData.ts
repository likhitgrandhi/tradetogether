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

    const candidates = [
      ...positions.map((position) => this.positionToCandidate(user.id, account, position)),
      ...optionHoldings.map((holding) => this.optionToCandidate(user.id, account, holding)),
      ...activities
        .map((activity) => this.activityToClosedCandidate(user.id, account, activity))
        .filter((candidate): candidate is JsonRecord => candidate !== null)
    ];

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
      .select("id, side, status, quantity, entry_price, exit_price, mark_price, realized_pnl, unrealized_pnl, return_percent, provider_source_type, created_at, instruments(symbol, name)")
      .eq("seek_user_id", user.id)
      .order("created_at", { ascending: false });

    if (error) {
      throw new Error(`Failed to load trade candidates: ${error.message}`);
    }

    return ((data ?? []) as JsonRecord[]).map((candidate) => {
      const instrument = asRecord(candidate.instruments);
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
        symbol: firstString(instrument.symbol) ?? "UNKNOWN",
        instrument_name: firstString(instrument.name)
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

  private positionToCandidate(
    seekUserId: string,
    account: BrokerageAccountRecord,
    raw: JsonRecord
  ): JsonRecord {
    const symbol = symbolFrom(raw) ?? "UNKNOWN";
    const quantity = numberFrom(raw.units, raw.quantity, raw.shares);
    const entryPrice = numberFrom(raw.average_purchase_price, raw.averagePrice, raw.cost_basis);
    const markPrice = numberFrom(raw.price, raw.market_value_price, raw.last_price);
    const unrealizedPnl = numberFrom(raw.open_pnl, raw.unrealized_pnl, raw.unrealizedPnL);

    return {
      seek_user_id: seekUserId,
      brokerage_account_id: account.id,
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

  private optionToCandidate(
    seekUserId: string,
    account: BrokerageAccountRecord,
    raw: JsonRecord
  ): JsonRecord {
    const symbol = symbolFrom(raw) ?? "OPTION";
    const quantity = numberFrom(raw.units, raw.quantity, raw.contracts);
    const entryPrice = numberFrom(raw.average_purchase_price, raw.averagePrice, raw.cost_basis);
    const markPrice = numberFrom(raw.price, raw.market_value_price, raw.last_price);
    const unrealizedPnl = numberFrom(raw.open_pnl, raw.unrealized_pnl, raw.unrealizedPnL);

    return {
      seek_user_id: seekUserId,
      brokerage_account_id: account.id,
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

  private activityToClosedCandidate(
    seekUserId: string,
    account: BrokerageAccountRecord,
    raw: JsonRecord
  ): JsonRecord | null {
    const action = firstString(raw.action, raw.type, raw.transaction_type)?.toLowerCase();
    const symbol = symbolFrom(raw);
    if (!symbol || !action || !["sell", "sold", "trade"].some((term) => action.includes(term))) {
      return null;
    }

    const tradeDate = firstString(raw.trade_date, raw.settlement_date, raw.date, raw.created_at);
    const price = numberFrom(raw.price, raw.execution_price, raw.net_amount);

    return {
      seek_user_id: seekUserId,
      brokerage_account_id: account.id,
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
}

function asRecord(value: unknown): JsonRecord {
  return value !== null && typeof value === "object" ? (value as JsonRecord) : {};
}

function firstString(...values: unknown[]): string | null {
  for (const value of values) {
    if (typeof value === "string" && value.length > 0) {
      return value;
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
  const optionSymbol = asRecord(raw.option_symbol);
  return firstString(raw.symbol, raw.ticker, symbol.symbol, symbol.raw_symbol, security.symbol, optionSymbol.symbol);
}

function percentReturn(entryPrice?: number, markPrice?: number): number | undefined {
  if (!entryPrice || markPrice === undefined) {
    return undefined;
  }
  return ((markPrice - entryPrice) / entryPrice) * 100;
}
