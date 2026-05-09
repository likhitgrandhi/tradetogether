import "dotenv/config";
import { z } from "zod";

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().positive().default(4000),
  API_BASE_URL: z.string().url().default("http://localhost:4000"),
  IOS_DEEP_LINK_SCHEME: z.string().min(1).default("seek"),
  SUPABASE_URL: z.string().url(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
  SNAPTRADE_CLIENT_ID: z.string().min(1),
  SNAPTRADE_CONSUMER_KEY: z.string().min(1),
  SNAPTRADE_USER_SECRET_ENCRYPTION_KEY: z.string().min(16),
  SNAPTRADE_WEBHOOK_SIGNING_SECRET: z.string().optional(),
  TWELVE_DATA_API_KEY: z.string().optional()
});

export type AppConfig = z.infer<typeof envSchema>;

export function loadConfig(overrides: Partial<NodeJS.ProcessEnv> = {}): AppConfig {
  return envSchema.parse({ ...process.env, ...overrides });
}
