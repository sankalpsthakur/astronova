# Astronova Analytics Integration

Self-contained operator + developer manual for Astronova's analytics, flags,
feedback, and server-log instrumentation. This document is the source of truth
for what events fire, how they are transported, and how privacy is enforced.

- North-star: paid users getting recurring chart/oracle value.
- Privacy posture: default-on telemetry with Settings opt-out. Turning off
  `Share Anonymous Usage` drops portfolio events, clears buffered portfolio
  events, rotates/removes the local analytics UUID, and stops Smartlook
  recording/event forwarding for the current app session when the Smartlook SDK
  is actually linked.
- Local analytics interface: `PortfolioAnalytics` (Swift shim at
  `client/AstronovaApp/Analytics/PortfolioAnalytics.swift`) and
  `portfolio_analytics` (Python module at `server/portfolio_analytics.py`).
- Smartlook status: the Swift package reference exists in the project, but
  `SmartlookAnalytics` is not linked to the `AstronovaApp` target in the
  current repo state. Treat Smartlook runtime recording/events as not active
  unless a source worker links the SDK and re-verifies it.

## Two-tier model

Astronova captures two parallel signal streams:

1. **Tier 1 — Server & network logs**. Backend `server/app.py` installs the
   `portfolio_analytics.install(app, app_id="astronova")` middleware which
   emits exactly one JSON line per request on stdout. Render forwards stdout
   to a BetterStack drain. Errors duplicate into Sentry. The iOS client
   wraps `URLSession` so every `network_request` carries the same
   `request_id` the server logs.
2. **Tier 2 — Clickstream + replay**. `PortfolioAnalytics.shared.track(...)`
   buffers events on the client and POSTs them to
   `https://telemetry.iosapps.io/v1/events` every 30s or 100 events. PostHog
   captures session replay behind the same opt-out gate.

## Event vocabulary

This table is the allowed event vocabulary. New event names are forbidden
until they land in `PortfolioEvent` (Swift) and in this table. Subscription
lifecycle events are partially emitted by the local StoreKit bridge; see
[`SUBSCRIPTION_EVENTS.md`](SUBSCRIPTION_EVENTS.md).

### Lifecycle

| Event           | Properties                                | Consumer                  |
|-----------------|-------------------------------------------|---------------------------|
| `app_open`      | `cold_start`, `first_session`             | FTUE funnel step 1        |
| `session_start` | `acquisition_source`                      | DAU / WAU dashboards      |
| `session_end`   | `duration_seconds`                        | Session-length cohorts    |
| `screen_view`   | `screen`, `from_screen`                   | Heatmap correlation       |

### Network

| Event             | Properties                                                | Consumer            |
|-------------------|-----------------------------------------------------------|---------------------|
| `network_request` | `method`, `route`, `status`, `latency_ms`, `request_id`   | p50/p95 dashboards  |
| `network_error`   | `route`, `error_class`, `error_message`, `attempt`        | Error-rate alerts   |
| `app_error`       | `error_class`, `screen`, `is_fatal`                       | Sentry correlation  |

### Astronova-specific actions

| Event                    | When                                       | Notes                                    |
|--------------------------|--------------------------------------------|------------------------------------------|
| `chart_viewed`           | User opens a natal/transit chart           | `chart_kind`, `first_only` activation    |
| `oracle_session_started` | Oracle conversation begins                 | `oracle_kind` property                   |
| `oracle_message_sent`    | Oracle message dispatched                  | `oracle_kind`, `transit_id`              |
| `feature_used`           | Generic — oracle, transit drill-in, etc.   | `feature` property required              |
| `cosmic_diary_entry_created` | Diary entry persisted                  | Deferred feature; event wired early      |
| `future_letter_scheduled` | Future-letter scheduled                   | Deferred feature; event wired early      |

### Monetization

| Event                  | Properties                                | Notes                                |
|------------------------|-------------------------------------------|--------------------------------------|
| `paywall_shown`        | `paywall_id`, `build`, `trigger`          |                                      |
| `paywall_dismissed`    | `paywall_id`                              |                                      |
| `paywall_converted`    | `paywall_id`, `product_id`                | Baseline `paywall_to_paid = 0.08`    |
| `trial_started`        | `product_id`                              | Defined target; not emitted today    |
| `subscription_started` | `product_id`, `price_minor`, `currency`   | Emitted on direct purchase only      |
| `subscription_renewed` | `product_id`                              | Transaction updates; deduplicated    |
| `subscription_lapsed`  | `product_id`, `reason`                    | Opportunistic status read; deduplicated |
| `iap_purchased`        | `product_id`, `amount`, `currency`        | Consumables & report SKUs            |

### Growth

| Event               | Properties           |
|---------------------|----------------------|
| `referral_sent`     | `channel`            |
| `referral_redeemed` | `inviter_id`         |
| `feature_used`      | `feature` (required) |

### Feedback & reviews

| Event                  | Properties                          |
|------------------------|-------------------------------------|
| `review_prompt_shown`  | `peak` — which `PeakMoment` fired   |
| `nps_shown`            | `surface`                           |
| `nps_submitted`        | `score` (0-10), `comment_len`       |
| `nps_dismissed`        | `surface`                           |

### Experiments

| Event                 | Properties                                   |
|-----------------------|----------------------------------------------|
| `experiment_exposure` | `experiment`, `variant`                      |
| `experiment_outcome`  | `experiment`, `variant`, `metric`, `value`   |

### FTUE funnel (single event)

`ftue_step` with properties: `step_index` (Int, 1-based), `step_name` (slug),
`total_steps` (Int), `time_since_install_seconds` (Int), `ftue_label`
(`ftue_step_<n>_<name>`). Dashboard: PostHog funnel "FTUE — app=astronova".

### Astronova custom event properties

| Property        | On events       | Example value               |
|-----------------|-----------------|-----------------------------|
| `oracle_kind`   | `feature_used`  | `transit`, `daily`, `natal` |
| `chart_kind`    | `chart_viewed`  | `natal`, `transit`, `synastry` |
| `paywall_id`    | paywall events  | `astronova_cosmic_v3`       |
| `transit_id`    | `feature_used`  | `mercury-cancer-2026-05`    |

## Naming rules

- `snake_case` for event names and property keys.
- Object-first, verb-past pattern: `card_reviewed`, not `review_card`.
- Properties never repeat the envelope (`app_id`, `user_id`, `session_id`).
- No PII anywhere: no emails, no birth dates, no chart subject names, no free
  text from forms. Length, not content (`comment_len`).

## Server log schema

`server/portfolio_analytics.py` writes one JSON object per request to stdout.

| Field              | Type      | Source                                  |
|--------------------|-----------|-----------------------------------------|
| `ts`               | ISO-8601  | wall clock at log time                  |
| `level`            | enum      | `debug`/`info`/`warn`/`error`           |
| `app`              | string    | `astronova`                             |
| `event`            | string    | `http_request`, `http_error`            |
| `request_id`       | string    | `X-Request-ID` header or generated      |
| `method`           | string    | uppercase HTTP method                   |
| `route`            | string    | route template, not interpolated        |
| `status`           | int       | HTTP status                             |
| `latency_ms`       | int       | wall-clock                              |
| `user_anon_id`     | string    | from auth cookie/JWT (no PII)           |
| `ip_hash`          | string    | first 16 chars SHA-256(IP + salt)       |
| `user_agent_class` | string    | `ios/17.4`, `android/14`, `bot`         |

Errors add `error_class`, `error_message` (200-char preview, scrubbed), and
`stack_top` (top 3 frames). Forbidden in logs: raw user input, JWT contents,
request body beyond the 200-char preview behind `LOG_PREVIEW=1`.

## Transport & endpoints

| Producer        | Endpoint                                       | Auth             |
|-----------------|------------------------------------------------|------------------|
| iOS clickstream | `POST https://telemetry.iosapps.io/v1/events`  | none (anonymous) |
| iOS PostHog     | `POST https://app.posthog.com/capture/`        | project token    |
| Server logs     | stdout → Render → BetterStack drain            | drain token      |
| Server errors   | Sentry DSN                                     | DSN secret       |

## Flags

Read from `flags.iosapps.io`. Refresh cadence: 5 min in-memory, 1 h on-disk.

| Flag key                              | Type    | Default   | Used by                                 |
|---------------------------------------|---------|-----------|-----------------------------------------|
| `paywall_v2_enabled`                  | bool    | `false`   | Paywall presenter                       |
| `cosmic_tier_enabled`                 | bool    | `true`    | Cosmic IAP shelf                        |
| `oracle_streaming_enabled`            | bool    | `false`   | Oracle response renderer                |
| `experiment_paywall_variant_v1`       | variant | `control` | Paywall A/B (control/treatment)         |
| `review_prompt_astronova_v1`          | bool    | `true`    | Review prompt master switch             |
| `winback_astronova_enabled`           | bool    | `true`    | Win-back scheduler                      |
| `nps_post_transit_enabled`            | bool    | `false`   | NPS post-transit surface ramp           |

## Experiments currently running

| Experiment                | Variants            | Window            | Owner            | Pause criterion                              |
|---------------------------|---------------------|-------------------|------------------|----------------------------------------------|
| `paywall_variant_v1`      | control / treatment | 2026-05 → ongoing | portfolio lead   | `paywall_to_paid` drop > 15 % vs control     |
| `oracle_streaming`        | off / on            | rollout phase     | astronova eng    | crash rate doubles or oracle p95 > 6s        |

Live exposure counts at `/v1/dashboard/experiments?app=astronova`.

## Dashboards & alerts

- Per-app drill-down: `https://telemetry.iosapps.io/v1/dashboard/app/astronova`
- Funnel baselines: `install_to_first_chart = 0.78`,
  `first_chart_to_first_oracle = 0.42`, `first_oracle_to_paywall = 0.55`,
  `paywall_to_paid = 0.08`.
- Win-back scheduler: 14-day threshold, re-arm per transit.

Alerts:

| Trigger                                            | Channel | Action                                |
|----------------------------------------------------|---------|---------------------------------------|
| `http_error` rate > 1% over 5 min                  | Slack   | Page on-call                          |
| `network_error` rate > 5% over 5 min               | Slack   | Investigate API status                |
| Telemetry ingest 5xx > 0.1% over 5 min             | Slack   | Page portfolio on-call                |
| `ingest_partial_reject` > 100/hr                   | Slack   | New event name landed without schema  |
| Sentry new fatal in last 24h                       | Slack   | Triage                                |

## Privacy posture

- Default-on telemetry, Settings opt-out switch ("Share Anonymous Usage").
- Opt-out flips `PortfolioAnalytics.shared.isOptedOut = true` which drops the
  buffer, rotates the local UUID, and calls PostHog `optOut()` + `reset()`.
- DEBUG builds are no-ops at the SDK level (Swift `#if DEBUG`).
- Random per-device UUID stored in `UserDefaults`; never linked to Apple ID,
  email, or device ID.
- Server logs hash IPs with `IP_HASH_SALT` (>= 8 chars, required in production).
- Retention: BetterStack 14 days, PostHog 90 days, Sentry 30 days.

## Privacy and App Store mapping

- Event envelopes include `app_id`, a random app-local UUID, session ID,
  timestamp, experiment buckets, and event properties. Treat Product
  Interaction as linked to the random User ID for App Store nutrition-label
  purposes.
- Smartlook is a session diagnostics provider only after the SDK product is
  linked. In the current repo state, the package reference exists but the SDK
  is not linked to the app target, so do not claim live Smartlook recording
  until that source change is made and verified.
- The privacy manifest declares no cross-app or cross-website tracking:
  `NSPrivacyTracking = false`, with no tracking domains.

## Tooling

| Layer                | Tool         | Rationale                                                     |
|----------------------|--------------|---------------------------------------------------------------|
| Backend log drain    | BetterStack  | Generous free tier, Render-native                             |
| Backend errors       | Sentry       | Best-in-class iOS + Python                                    |
| Clickstream + replay | PostHog      | Single SDK for events + replay + funnels + flags              |
| Crash reporting      | Sentry       | Co-located with backend errors                                |
| Feature flags        | PostHog      | Replaces ad-hoc remote-flag service                           |

## On-call procedures

### "Telemetry endpoint is 5xx"

1. `render logs -r <iosapps-telemetry-service-id> -o text --confirm --tail`
2. Look for `event:ingest_parse_failed` or `event:ingest_fanout` failures.
3. If PostHog is down (sink reports `ok:false`), the service still returns
   204 — clickstream is buffered. No action.
4. If the service itself is crashing, redeploy.

### "App stopped reporting"

1. Verify clients can reach `telemetry.iosapps.io/health` → 200.
2. Verify the PostHog project token is set and the SDK is `configure`d.
   Look for `app_open` events in the last hour:
   `BetterStack: event:app_open app:astronova @last 1h`.
3. If telemetry receives events but PostHog doesn't, check ingest
   `ingest_fanout` log — PostHog API key may be invalid.
4. If neither, the SDK never got `configure()`'d. Check crash logs for a
   startup failure.

### "Backend p95 spiked"

1. BetterStack: `event:http_request app:astronova | sort latency_ms desc`.
2. Cross-reference slowest routes with deploy history.
3. If a recent deploy correlates, roll back to the previous commit.

## Adding a new event

1. Add the case to `PortfolioEvent` in `PortfolioAnalytics.swift`.
2. Update this document with the event, properties, and consumer.
3. Add a PostHog dashboard tile that reads it. PR description must include a
   screenshot or query.
4. Roll the SDK version and ship as part of the next app release.

## Secret rotation

| Secret                   | Where                              | Rotation cadence |
|--------------------------|------------------------------------|------------------|
| PostHog project token    | App secrets store; ingest env      | Annual           |
| BetterStack source token | `iosapps-telemetry` env            | Annual           |
| Sentry DSN               | Server env                         | Annual / on compromise |
| `IP_HASH_SALT`           | Server env                         | Daily (cron job, planned) |
