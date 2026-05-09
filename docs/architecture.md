# GrowHouse Architecture

## Product Shape

GrowHouse is an iOS-first social trading app. The app should keep the feed fast and social, but never treat a claimed trade as verified unless it came from a connected brokerage account.

## Runtime Services

- iOS app: SwiftUI client for feed, profiles, market pages, brokerage connection, and posting verified trades.
- API: Fastify TypeScript service that owns auth validation, SnapTrade calls, feed writes, and server-side secrets.
- Supabase Postgres: primary app database for profiles, connections, accounts, instruments, verified trade candidates, posts, sync jobs, and webhook events.
- Supabase Auth: user identity and JWT issuer for the iOS app.
- SnapTrade: brokerage connection portal plus account, position, option, and activity data.
- Future market data provider: Polygon, Twelve Data, or Finnhub for live quote/chart pages.
- Future AI service: server-side overview generation for stock movement and trade thesis checks.

## Data Flow

1. User signs in with Supabase Auth in the iOS app.
2. iOS sends the Supabase access token to the GrowHouse API.
3. API validates the token with Supabase, registers the user with SnapTrade, and stores the SnapTrade user secret encrypted.
4. API creates a read-only SnapTrade portal link.
5. User connects a brokerage in the portal.
6. API syncs brokerage connections and accounts.
7. API syncs positions, option holdings, and account activities into verified trade candidates.
8. User selects a verified candidate and publishes a post.
9. Feed reads public posts; profile credibility is calculated from closed verified candidates over time.

## Scaling Notes

- Keep SnapTrade credentials server-side only.
- Use service-role Supabase credentials only in the API environment.
- Run account syncs through background jobs before launch scale. `sync_jobs` is already in the schema so BullMQ, Trigger.dev, or Supabase queues can slot in cleanly.
- Store raw provider payloads beside normalized fields. This lets us ship fast while preserving data for better normalization later.
- Split market data and AI summaries into cached server endpoints. Never call paid quote or model APIs directly from iOS.
- Use database uniqueness on provider IDs so repeated webhooks and manual syncs are idempotent.
- Compute win rate from closed verified candidates, not manual posts.

## Next External Keys

- Supabase project URL and service-role key.
- Supabase anon key for the iOS auth layer.
- A Supabase test user email/password for local end-to-end brokerage sync.
- SnapTrade client ID and consumer key.
- A 32-byte base64 encryption key for stored SnapTrade user secrets.
- Optional SnapTrade webhook signing secret.
- Market data API key when we turn stock pages from mock data into live quote/chart pages.
- OpenAI API key when we add AI stock movement summaries.
