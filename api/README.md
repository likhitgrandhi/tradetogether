# GrowHouse API

Fastify backend for real brokerage data, SnapTrade account linking, and verified trade posting.

## Local Setup

1. Copy `.env.example` to `.env`.
2. Fill Supabase anon, Supabase service-role, and SnapTrade credentials.
3. Generate `SNAPTRADE_USER_SECRET_ENCRYPTION_KEY`:

```sh
openssl rand -base64 32
```

4. Install and run:

```sh
npm install
npm run dev
```

## Database

Apply `../supabase/migrations/202605090001_initial_real_data.sql` to a Supabase project before running the API. The backend uses the service-role key server-side only; the iOS app should send a normal Supabase user access token to protected endpoints.

## Current Endpoints

- `GET /health`
  - Checks API availability and SnapTrade API status.
- `GET /markets/:symbol/quote`
  - Returns a live quote through Twelve Data when `TWELVE_DATA_API_KEY` is set.
- `GET /markets/:symbol/candles`
  - Returns chart candles. Query supports `interval` and `outputsize`.
- `GET /markets/:symbol/overview`
  - Returns a first-pass movement summary. This is the API boundary where the AI thesis engine will plug in.
- `POST /snaptrade/users`
  - Requires `Authorization: Bearer <supabase_access_token>`.
  - Idempotently registers the authenticated user with SnapTrade.
  - Stores the generated SnapTrade user secret encrypted in Postgres.
- `POST /snaptrade/portal-link`
  - Requires `Authorization: Bearer <supabase_access_token>`.
  - Creates a short-lived read-only SnapTrade Connection Portal URL.
  - Uses `growhouse://snaptrade/callback` as the native iOS redirect in deployed environments.
- `POST /brokerage/connections/sync`
  - Pulls SnapTrade connections and accounts into local tables.
- `GET /brokerage/connections`
  - Lists the authenticated user's linked brokerages.
- `GET /brokerage/accounts`
  - Lists the authenticated user's brokerage accounts.
- `POST /brokerage/accounts/:accountId/sync`
  - Pulls positions, option holdings, and recent activities for the account.
  - Creates verified trade candidates for open positions and closed activity.
- `GET /trade-candidates`
  - Lists verified account-derived trades ready to post.
- `POST /posts`
  - Creates a manual post or a `verified_snaptrade` post tied to one of the user's candidates.
- `GET /feed`
  - Public feed endpoint for the social timeline.
- `POST /webhooks/snaptrade`
  - Stores SnapTrade webhook payloads for async processing. If `SNAPTRADE_WEBHOOK_SIGNING_SECRET` is set, the route verifies an HMAC SHA-256 signature.

## iOS Wiring

The iOS app reads public mobile configuration from:

- `GET /config/mobile`

Users should only see the onboarding screens for email/password sign in and SnapTrade connection. They should never need to paste API URLs or Supabase keys into the app.

`SUPABASE_ANON_KEY` is intentionally returned by `/config/mobile` because it is the public browser/mobile key Supabase clients use for user auth. Keep `SUPABASE_SERVICE_ROLE_KEY` server-side only.

## Checks

```sh
npm run build
npm test
npm audit --omit=dev
```
