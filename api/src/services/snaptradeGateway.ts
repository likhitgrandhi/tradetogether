import { Snaptrade } from "snaptrade-typescript-sdk";
import type { AppConfig } from "../config.js";
import type {
  JsonRecord,
  SnapTradePortalLink,
  SnapTradeRegisteredUser,
  SnapTradeStatus
} from "../types.js";

export interface SnapTradeGateway {
  checkStatus(): Promise<SnapTradeStatus>;
  registerUser(userId: string): Promise<SnapTradeRegisteredUser>;
  createPortalLink(input: {
    userId: string;
    userSecret: string;
    customRedirect: string;
  }): Promise<SnapTradePortalLink>;
  listConnections(input: { userId: string; userSecret: string }): Promise<JsonRecord[]>;
  removeConnection(input: {
    userId: string;
    userSecret: string;
    authorizationId: string;
  }): Promise<void>;
  listAccounts(input: {
    userId: string;
    userSecret: string;
    authorizationId: string;
  }): Promise<JsonRecord[]>;
  listPositions(input: {
    userId: string;
    userSecret: string;
    accountId: string;
  }): Promise<JsonRecord[]>;
  listOptionHoldings(input: {
    userId: string;
    userSecret: string;
    accountId: string;
  }): Promise<JsonRecord[]>;
  listActivities(input: {
    userId: string;
    userSecret: string;
    accountId: string;
    startDate?: string;
    endDate?: string;
    limit?: number;
  }): Promise<JsonRecord[]>;
}

export class SnapTradeSdkGateway implements SnapTradeGateway {
  private readonly client: Snaptrade;

  constructor(config: AppConfig) {
    this.client = new Snaptrade({
      clientId: config.SNAPTRADE_CLIENT_ID,
      consumerKey: config.SNAPTRADE_CONSUMER_KEY
    });
  }

  async checkStatus(): Promise<SnapTradeStatus> {
    const response = await this.client.apiStatus.check();
    return response.data as SnapTradeStatus;
  }

  async registerUser(userId: string): Promise<SnapTradeRegisteredUser> {
    const response = await this.client.authentication.registerSnapTradeUser({ userId });
    return response.data as SnapTradeRegisteredUser;
  }

  async createPortalLink(input: {
    userId: string;
    userSecret: string;
    customRedirect: string;
  }): Promise<SnapTradePortalLink> {
    const response = await this.client.authentication.loginSnapTradeUser({
      userId: input.userId,
      userSecret: input.userSecret,
      immediateRedirect: false,
      customRedirect: input.customRedirect,
      connectionType: "read",
      showCloseButton: false,
      darkMode: true,
      connectionPortalVersion: "v4"
    });

    return response.data as SnapTradePortalLink;
  }

  async listConnections(input: { userId: string; userSecret: string }): Promise<JsonRecord[]> {
    const response = await this.client.connections.listBrokerageAuthorizations({
      userId: input.userId,
      userSecret: input.userSecret
    });
    return asRecords(response.data);
  }

  async removeConnection(input: {
    userId: string;
    userSecret: string;
    authorizationId: string;
  }): Promise<void> {
    await this.client.connections.removeBrokerageAuthorization({
      authorizationId: input.authorizationId,
      userId: input.userId,
      userSecret: input.userSecret
    });
  }

  async listAccounts(input: {
    userId: string;
    userSecret: string;
    authorizationId: string;
  }): Promise<JsonRecord[]> {
    const response = await this.client.connections.listBrokerageAuthorizationAccounts({
      authorizationId: input.authorizationId,
      userId: input.userId,
      userSecret: input.userSecret
    });
    return asRecords(response.data);
  }

  async listPositions(input: {
    userId: string;
    userSecret: string;
    accountId: string;
  }): Promise<JsonRecord[]> {
    const response = await this.client.accountInformation.getUserAccountPositions({
      userId: input.userId,
      userSecret: input.userSecret,
      accountId: input.accountId
    });
    return asRecords(response.data);
  }

  async listOptionHoldings(input: {
    userId: string;
    userSecret: string;
    accountId: string;
  }): Promise<JsonRecord[]> {
    const response = await this.client.options.listOptionHoldings({
      userId: input.userId,
      userSecret: input.userSecret,
      accountId: input.accountId
    });
    return asRecords(response.data);
  }

  async listActivities(input: {
    userId: string;
    userSecret: string;
    accountId: string;
    startDate?: string;
    endDate?: string;
    limit?: number;
  }): Promise<JsonRecord[]> {
    const response = await this.client.accountInformation.getAccountActivities({
      accountId: input.accountId,
      userId: input.userId,
      userSecret: input.userSecret,
      startDate: input.startDate,
      endDate: input.endDate,
      limit: input.limit ?? 100
    });
    const data = response.data as JsonRecord | JsonRecord[];
    if (Array.isArray(data)) {
      return asRecords(data);
    }
    return asRecords(data.data ?? data.activities ?? data.items ?? []);
  }
}

function asRecords(value: unknown): JsonRecord[] {
  return Array.isArray(value)
    ? value.filter((item): item is JsonRecord => item !== null && typeof item === "object")
    : [];
}
