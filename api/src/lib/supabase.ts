import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import type { AppConfig } from "../config.js";

export function createSupabaseAdmin(config: AppConfig): SupabaseClient {
  return createClient(config.SUPABASE_URL, config.SUPABASE_SERVICE_ROLE_KEY, {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  });
}
