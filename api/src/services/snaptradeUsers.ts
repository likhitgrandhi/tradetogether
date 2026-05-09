import type { SupabaseClient } from "@supabase/supabase-js";
import type { AppConfig } from "../config.js";
import { decryptSecret, encryptSecret } from "../lib/crypto.js";
import type { AuthenticatedUser } from "../types.js";
import type { SnapTradeGateway } from "./snaptradeGateway.js";

export type StoredSnapTradeUser = {
  seek_user_id: string;
  snaptrade_user_id: string;
  encrypted_user_secret: string;
  created_at: string;
  updated_at: string;
};

export type SnapTradeUserResult = {
  snapTradeUserId: string;
  created: boolean;
};

export type SnapTradeCredentials = {
  snapTradeUserId: string;
  userSecret: string;
};

export class SnapTradeUserService {
  constructor(
    private readonly db: SupabaseClient,
    private readonly snaptrade: SnapTradeGateway,
    private readonly config: AppConfig
  ) {}

  async ensureRegisteredUser(user: AuthenticatedUser): Promise<SnapTradeUserResult> {
    const existing = await this.findStoredUser(user.id);
    if (existing) {
      return {
        snapTradeUserId: existing.snaptrade_user_id,
        created: false
      };
    }

    const snapTradeUserId = this.toSnapTradeUserId(user.id);
    const registered = await this.snaptrade.registerUser(snapTradeUserId);
    const encryptedSecret = encryptSecret(
      registered.userSecret,
      this.config.SNAPTRADE_USER_SECRET_ENCRYPTION_KEY
    );

    const { error } = await this.db.from("snaptrade_users").insert({
      seek_user_id: user.id,
      snaptrade_user_id: registered.userId,
      encrypted_user_secret: encryptedSecret
    });

    if (error) {
      throw new Error(`Failed to store SnapTrade user: ${error.message}`);
    }

    return {
      snapTradeUserId: registered.userId,
      created: true
    };
  }

  async createPortalLink(user: AuthenticatedUser): Promise<{
    redirectURI: string;
    sessionId?: string;
    snapTradeUserId: string;
  }> {
    await this.ensureRegisteredUser(user);
    const stored = await this.getStoredUser(user.id);
    const userSecret = decryptSecret(
      stored.encrypted_user_secret,
      this.config.SNAPTRADE_USER_SECRET_ENCRYPTION_KEY
    );
    const portal = await this.snaptrade.createPortalLink({
      userId: stored.snaptrade_user_id,
      userSecret,
      customRedirect: `${this.config.IOS_DEEP_LINK_SCHEME}://snaptrade/callback`
    });

    return {
      redirectURI: portal.redirectURI,
      sessionId: portal.sessionId,
      snapTradeUserId: stored.snaptrade_user_id
    };
  }

  async getCredentials(user: AuthenticatedUser): Promise<SnapTradeCredentials> {
    await this.ensureRegisteredUser(user);
    const stored = await this.getStoredUser(user.id);
    return {
      snapTradeUserId: stored.snaptrade_user_id,
      userSecret: decryptSecret(
        stored.encrypted_user_secret,
        this.config.SNAPTRADE_USER_SECRET_ENCRYPTION_KEY
      )
    };
  }

  private async findStoredUser(seekUserId: string): Promise<StoredSnapTradeUser | null> {
    const { data, error } = await this.db
      .from("snaptrade_users")
      .select("*")
      .eq("seek_user_id", seekUserId)
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to load SnapTrade user: ${error.message}`);
    }

    return data as StoredSnapTradeUser | null;
  }

  private async getStoredUser(seekUserId: string): Promise<StoredSnapTradeUser> {
    const user = await this.findStoredUser(seekUserId);
    if (!user) {
      throw new Error("SnapTrade user was not created");
    }
    return user;
  }

  private toSnapTradeUserId(seekUserId: string): string {
    return `seek_${seekUserId.replaceAll("-", "")}`;
  }
}
