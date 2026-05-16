# Astronova Analytics Integration

Cheat-sheet for Astronova's wiring into the portfolio's analytics, flags,
and feedback infrastructure. For the full operator manual see
[../umbrella/ANALYTICS_RUNBOOK.md](../umbrella/ANALYTICS_RUNBOOK.md).

- North-star: paid users getting recurring chart/oracle value.
- Privacy posture: default-on telemetry with Settings opt-out. Turning off
  `Share Anonymous Usage` drops portfolio events, clears buffered portfolio
  events, rotates/removes the local analytics UUID, and stops Smartlook
  recording/event forwarding for the current app session when the Smartlook SDK
  is actually linked.
- SDK: `IOSAppsAnalytics`, `IOSAppsFlags`, `IOSAppsReviewPrompts`,
  `IOSAppsCrashReporting`, `IOSAppsWinback`.
- Smartlook status: the Swift package reference exists in the project, but
  `SmartlookAnalytics` is not linked to the `AstronovaApp` target in the
  current repo state. Treat Smartlook runtime recording/events as not active
  unless a source worker links the SDK and re-verifies it.

## Event Vocabulary and Current Wiring

From [`umbrella/analytics/IOSAppsAnalytics/.../EventName.swift`](../umbrella/analytics/IOSAppsAnalytics/):

This table is the allowed event vocabulary. Subscription lifecycle events are
defined as targets, but they are not emitted today; see
[`SUBSCRIPTION_EVENTS.md`](SUBSCRIPTION_EVENTS.md).

| Event                  | When                                       | Notes |
|------------------------|--------------------------------------------|-------|
| `app_open`             | App launch, foreground                     | `cold_start`, `first_session` properties drive funnel step 1. |
| `session_start`        | Session begins                             | `acquisition_source` persisted from install attribution. |
| `session_end`          | Session ends                               |       |
| `chart_viewed`         | User opens a natal/transit chart           | `first_only` of this event is the activation step. |
| `feature_used`         | Generic — oracle, transit drill-in, etc.   | `feature` property required. |
| `paywall_shown`        | Paywall presented                          | `paywall_id`, `build`. |
| `paywall_dismissed`    | Paywall closed without conversion          |       |
| `paywall_converted`    | Paywall converts to purchase intent        | Drives baseline `paywall_to_paid = 0.08`. |
| `subscription_started` | Subscription begins                        | Defined target; not emitted today. |
| `subscription_renewed` | Renewal                                    | Defined target; not emitted today. |
| `subscription_lapsed`  | Grace period exit, downgrade               | Defined target; not emitted today. |
| `iap_purchased`        | Non-renewing IAP (cosmic tier add-ons)     | `amount` minor units. |
| `referral_sent`        | Share-a-chart action                       |       |
| `nps_shown` / `nps_submitted` / `nps_dismissed` | NPS surface (post-transit) | `surface` property names the trigger. |
| `review_prompt_shown`  | `SKStoreReviewController` requested        | `peak` property: which `PeakMoment` triggered. |

Custom event names not on this list are forbidden until they land in
[`ANALYTICS_DESIGN.md`](../umbrella/analytics/ANALYTICS_DESIGN.md) and
`EventName.swift`.

## Custom event properties

| Property             | On events            | Example value             |
|----------------------|----------------------|---------------------------|
| `oracle_kind`        | `feature_used`       | `transit`, `daily`, `natal` |
| `chart_kind`         | `chart_viewed`       | `natal`, `transit`, `synastry` |
| `paywall_id`         | paywall events       | `astronova_cosmic_v3`     |
| `transit_id`         | `feature_used`       | `mercury-cancer-2026-05`  |

## Flags read

From `flags.iosapps.io` (see [`umbrella/flags/IOSAppsFlags/README.md`](../umbrella/flags/IOSAppsFlags/README.md)):

| Flag key                              | Type    | Default  | Used by                                |
|---------------------------------------|---------|----------|----------------------------------------|
| `paywall_v2_enabled`                  | bool    | `false`  | Paywall presenter                      |
| `cosmic_tier_enabled`                 | bool    | `true`   | Cosmic IAP shelf                       |
| `oracle_streaming_enabled`            | bool    | `false`  | Oracle response renderer               |
| `experiment_paywall_variant_v1`       | variant | `control`| Paywall A/B (control/treatment)        |
| `review_prompt_astronova_v1`          | bool    | `true`   | Review prompt master switch            |
| `winback_astronova_enabled`           | bool    | `true`   | Win-back scheduler                     |
| `nps_post_transit_enabled`            | bool    | `false`  | NPS post-transit surface ramp          |

Refresh cadence is 5 minutes in-memory, 1-hour on-disk cache.

## Experiments currently running

| Experiment                          | Variants               | Window         | Owner            | Pause criterion                              |
|-------------------------------------|------------------------|----------------|------------------|----------------------------------------------|
| `paywall_variant_v1`                | control / treatment    | 2026-05 → ongoing | portfolio lead | `paywall_to_paid` drop > 15 % vs control     |
| `oracle_streaming`                  | off / on               | rollout phase  | astronova eng    | crash rate doubles or oracle latency p95 > 6s |

See `/v1/dashboard/experiments?app=astronova` for live exposure counts.

## Dashboard

- Per-app drill-down: `https://telemetry.iosapps.io/v1/dashboard/app/astronova`
- Funnel definition: [`umbrella/alerts/funnels.json`](../umbrella/alerts/funnels.json)
  → `apps.astronova`.
  Baseline conversions: `install_to_first_chart = 0.78`,
  `first_chart_to_first_oracle = 0.42`,
  `first_oracle_to_paywall = 0.55`, `paywall_to_paid = 0.08`.
- Win-back: 14-day threshold, re-arm per transit
  (see [`umbrella/winback/WINBACK_DESIGN.md`](../umbrella/winback/WINBACK_DESIGN.md)).

## Privacy and App Store mapping

- Event envelopes include `app_id`, a random app-local UUID, session ID,
  timestamp, experiment buckets, and event properties. Treat Product
  Interaction as linked to the random User ID for App Store nutrition-label
  purposes.
- Smartlook is a session diagnostics provider only after the SDK product is
  linked. In the current repo state, the package reference exists but the SDK is
  not linked to the app target, so do not claim live Smartlook recording until
  that source change is made and verified.
- The privacy manifest declares no cross-app or cross-website tracking:
  `NSPrivacyTracking = false`, with no tracking domains.
