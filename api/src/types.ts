import type { User } from "@supabase/supabase-js";

export type AuthenticatedUser = Pick<User, "id" | "email">;

export type JsonRecord = Record<string, unknown>;

declare module "fastify" {
  interface FastifyRequest {
    authUser?: AuthenticatedUser;
  }
}

export type SnapTradeStatus = {
  online: boolean;
  timestamp?: string;
  version?: number;
};

export type SnapTradePortalLink = {
  redirectURI: string;
  sessionId?: string;
};

export type SnapTradeRegisteredUser = {
  userId: string;
  userSecret: string;
};

export type BrokerageConnectionRecord = {
  id: string;
  seek_user_id: string;
  provider: string;
  provider_connection_id: string;
  brokerage_slug: string | null;
  brokerage_name: string | null;
  disabled: boolean;
  raw: JsonRecord;
};

export type BrokerageAccountRecord = {
  id: string;
  seek_user_id: string;
  brokerage_connection_id: string;
  provider: string;
  provider_account_id: string;
  account_name: string | null;
  account_number_mask: string | null;
  account_type: string | null;
  currency_code: string | null;
  raw: JsonRecord;
};
