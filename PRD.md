# iCodexBar — Product Requirements Document

## 1. Problem Statement

Developers using CLI subscription products — Claude Code, OpenAI Codex CLI — constantly hit invisible quota walls. The 5-hour session window and the weekly cap are real, enforced, and not visible anywhere except when you're already blocked. Separately, developers paying per-token for OpenAI / Anthropic / OpenRouter APIs have no native way to glance at spend. Existing solutions are all macOS menu bar apps (CodexBar is the reference) — there is no iOS widget, no Lock Screen glance, no Apple Watch complication.

iCodexBar is the **iOS-first widget + Apple Watch + macOS companion** for AI usage. Privacy-first (keys in Keychain, no backend), dual-mode (auto-detects whether a given provider is quota-based or spend-based), and architected so that the iOS app works standalone for API-key providers while unlocking Claude Code / Codex CLI quota data when paired with the macOS companion.

---

## 2. Target Users

### Tier A — iOS-only user (~60% of MVP audience)
- Uses AI via API keys (OpenAI, Anthropic, OpenRouter)
- Wants Lock Screen / Home Screen glance at spend + balance
- Does not use (or does not need to track) Claude Code / Codex CLI
- Can fully use iCodexBar with zero Mac involvement

### Tier B — iOS + Mac user (~30% of MVP audience, higher LTV)
- Uses Claude Code or Codex CLI on a Mac
- Wants the same iOS widget experience, but with quota data that only exists on the Mac
- Installs the iCodexBar macOS companion; it reads local CLI state and syncs snapshots to iCloud
- iOS widgets pick up the synced state; Apple Watch complications reflect it at the wrist

### Tier C — Mac-only user (~10% of MVP audience)
- Lives in the terminal, wants a menu bar app
- Directly replaces CodexBar with a more stable, better-designed alternative
- No iOS required

### Paid tiers (scope unchanged from v0; see §4)
- **Premium ($1/mo)** — multi-account, history charts, pace predictions, CSV export
- **Enterprise ($15/user/mo)** — team dashboards, admin controls, SSO

---

## 3. Data Model — Dual Mode

### 3.1 Provider auth detection drives the mode

When a user adds a provider, the auth shape determines the tracking mode. The user does not pick the mode; we detect it.

| User provides | Mode | Data |
|---|---|---|
| OpenAI API key (`sk-proj-…`, `sk-…`) | **Spend** | `GET /v1/organization/costs` — daily cost, monthly budget %, projected EoM |
| OpenAI Codex CLI (local `~/.codex/`, Mac only) | **Quota** | Session 5h window + weekly cap + reset times |
| Anthropic API key (`sk-ant-api…`) | **Spend** | Response headers from `/v1/messages` + console billing aggregation |
| Anthropic Claude Code (local `~/.claude/projects/*.jsonl`, Mac only) | **Quota** | Session 5h window + weekly cap + cost |
| OpenRouter API key (`sk-or-…`) | **Balance** | `GET /api/v1/credits` — balance remaining (no session/weekly concept) |
| ChatGPT subscription (Plus / Pro / Team, scraped cookies) | **Quota** | Session window (per CodexBar's approach — scoped to Phase 2) |

A single user can have any combination. OpenAI might be Spend (API key) while Anthropic is Quota (Claude Code via Mac companion). The widget tile renders whichever shape applies.

### 3.2 The three visual shapes

All three fit the same widget chrome; only the data changes:

**Quota shape:**
- Session bar: % remaining + reset countdown ("94% · resets in 18h")
- Weekly bar: % remaining + pace-reference line ("62% remaining · slightly behind pace")
- Today metric: time used + tokens ("Today 2h 31m · 2.2M tokens")
- 30-day metric: cost + tokens ("Last 30 Days $497.15 · 1.3B tokens")

**Spend shape:**
- Month-to-date bar: % of budget ("42% of $1,200 budget")
- Projected end-of-month ("Projected $680")
- Daily burn / yesterday delta
- Provider pace tag (On pace / Over pace / Under pace)

**Balance shape** (OpenRouter, and future prepaid providers):
- Balance remaining ("$12.40 remaining")
- Last top-up date
- Burn rate (optional: "≈ 8 days at current pace")

### 3.3 Pace reference line

Both Quota and Spend modes show an on-device-computed pace reference. For a weekly quota, it's the fraction of the week elapsed. For a monthly spend budget, it's the fraction of the month elapsed. A user "on pace" has the pace-line sitting exactly on their current usage; "behind pace" (good) has the line past them; "over pace" (bad) has the line behind them.

This is the single most important metric we show and the thing CodexBar does that no API-spend-tracker does. It turns raw percentages into a forecast.

---

## 4. Core Features

### 4.1 MVP v1 (Free Tier, ships first)

#### macOS foundation (Phase 1 of build)
- Menu bar status item ("codex bar") with 2-bar icon: top = session, bottom = weekly
- Dropdown with per-provider breakdown, pace indicators, refresh, quit
- macOS widgets (small, medium, large) — Notification Center + Desktop
- Local readers: `~/.claude/projects/*.jsonl`, `~/.codex/` state
- OpenRouter polling (API key)
- OpenAI + Anthropic API-key polling (spend mode)
- Keychain storage with preflight explanation prompt
- Launch-at-login toggle
- Refresh cadence presets (manual / 1m / 2m / 5m / 15m)
- Dim icon = stale/error

#### iOS foundation (Phase 2 of build)
- iOS app with Dashboard tab + Settings tab
- Home Screen widgets (small, medium, large)
- Lock Screen widgets (circular + inline)
- Direct API-key support (OpenRouter balance, OpenAI/Anthropic spend)
- Mode auto-detection on key entry
- Pull-to-refresh, error states, empty states
- Alert thresholds per provider (configurable, notify at X%)

#### iCloud sync (Phase 2, glue)
- Mac companion writes usage snapshots to CloudKit private database every 5m
- iOS app reads from CloudKit, falls back to direct API polling when Mac snapshot is stale or absent
- CloudKit record schema versioned from day one
- Zero backend — all storage is the user's iCloud

### 4.2 Features cribbed directly from CodexBar

| Feature | Why | Priority |
|---|---|---|
| 2-bar menu bar icon (session top, weekly bottom) | Single glance signal, core identity | P0 |
| Relative reset countdown ("Resets in 3h 31m") | More useful than absolute timestamp | P0 |
| "Show usage as used" / "remaining" toggle | Power-user preference | P0 |
| Pace reference line with risk forecasting | The differentiator from spend-only trackers | P0 |
| Refresh cadence presets (not slider) | Battery-aware, no ambiguity | P0 |
| Dim icon on stale/error | Silent freshness signal | P0 |
| Merge Icons mode (one status item, dropdown has all) | For users with 3+ providers | P1 |
| Overview tab in dropdown | Summary view across providers | P1 |
| Keychain preflight explanation | Reduces onboarding bounce | P0 |
| Provider status polling (incidents) | Orthogonal to usage | P2 |

### 4.3 Features we explicitly do differently

| CodexBar's approach | Our approach | Why |
|---|---|---|
| macOS only | iOS-first, Watch, macOS companion | Lock Screen / wrist is the real glance surface |
| WKWebView scraping for ChatGPT / Claude.ai | Official APIs + local state only in v1; scraping Phase 2 if demand | Stability (CodexBar has recurring memory-leak issues #722, #713, #678, #788) |
| Notifications accepted-but-unbuilt (#776) | First-class alert thresholds in MVP | Table stakes for a usage tracker |
| OpenRouter as fallback "credits bar" when weekly empty | OpenRouter Balance mode as equal citizen | It's a different shape, not a fallback |
| 20+ providers | Curated: OpenAI / Anthropic / OpenRouter / Claude Code / Codex CLI | Ship polish, not breadth |
| No pace line for raw API spend | Pace line universal across Quota + Spend | Makes raw spend tracking actionable, not just observational |

### 4.4 Apple Watch (v1.1)
- Complications: corner, inline, circular, rectangular
- Single-provider view; user picks default in iOS app
- Reads from iOS shared App Group (which reads from CloudKit)

---

## 5. Monetization

Unchanged from v0. Free covers 90% of needs. Premium ($1/mo) unlocks multi-account, history charts, pace predictions, CSV export. Enterprise ($15/user/mo) adds team dashboards, admin, SSO.

---

## 6. Tech Stack

### Frameworks & Languages
- **Swift 5.9+** with **SwiftUI** for all UI
- **WidgetKit** — iOS + macOS widgets
- **ClockKit / WidgetKit complications** — Apple Watch
- **App Intents** (iOS 16+) for Siri + widget configuration
- **Keychain Services** — on-device key storage
- **CloudKit** — private database for Mac-to-iOS snapshot sync
- **StoreKit 2** — in-app subscriptions
- **Charts** (SwiftUI native) — history visualizations
- **URLSession** — API polling
- **NSStatusItem + AppKit** — macOS menu bar
- **FileSystemEvents / DispatchSource** — watching `~/.claude/` and `~/.codex/` local state

### Architecture
- **MVVM** with ObservableObject ViewModels
- **Repository pattern** for usage data access (one per data source type)
- **Actor-based** sources for thread-safe file watching + API polling
- **Dependency injection** via environment
- **Shared Core module** across iOS + macOS + Watch targets

### Data sources
| Source | Platform | Mode |
|---|---|---|
| OpenAI API (billing) | iOS + macOS | Spend |
| Anthropic API (messages + billing) | iOS + macOS | Spend |
| OpenRouter API (credits) | iOS + macOS | Balance |
| `~/.claude/projects/*.jsonl` | macOS only | Quota |
| `~/.codex/` local state | macOS only | Quota |
| ChatGPT web (cookies, WKWebView) | macOS only, Phase 2 | Quota |
| CloudKit private DB | iOS / Watch | Synced from Mac |

### Security & Privacy
- All API keys in **Keychain** with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- Mac companion requires explicit user consent to read `~/.claude/` / `~/.codex/`
- **No analytics SDKs** — zero third-party data collection
- **No backend required** — all logic client-side; CloudKit uses the user's iCloud
- App Store Privacy label: **No data collected**

---

## 7. UI / UX Direction

Visual language locked in during design shotgun session (`~/.gstack/projects/optomachina-icodexbar/designs/widgets-20260423/`):

- **Spine**: Variant D "Glanceable Minimal" — pill bars, pace-line tick, hero numbers, tabular-lining numerals
- **macOS menu bar**: Variant A "Terminal" — 2-bar icon + dropdown with dense per-provider rows + relative countdowns
- **Alt large widget**: Variant C "Data Dense" — for power users who want the htop view on the Home Screen

### Tokens
- Background: warm charcoal `#121417`
- Primary text: off-white
- Provider accents: OpenAI `#10A37F`, Anthropic `#CC785C`, OpenRouter `#E63946`
- Pace-line: 1px off-white tick, subtle
- Typography: SF Pro Display for hero numbers, SF Pro Text for body, SF Mono for menu bar dropdown rows
- Tabular-lining numerals everywhere

### Animations
- Subtle number roll-up on refresh
- Pace-line tick slides as time advances (no flash)
- Dim transition on stale data

---

## 8. Non-Goals (Explicit)

- Android app
- Web dashboard (our widgets replace the need)
- iPad-specific layouts in v1 (iPad runs iOS target, no custom work)
- Automatic cost optimization suggestions
- API key rotation / generation
- Provider billing integration (we show usage, not invoices)
- Multi-currency (USD only in v1)
- ChatGPT.com usage scraping in v1 (Phase 2 decision)

---

## 9. Success Metrics

- Widget add rate (% of app users who add at least one)
- Lock Screen widget add rate specifically
- Mac companion install rate among iOS users (the synergy moment)
- Alert configuration rate
- Premium conversion (target 3–5%)
- App Store rating target 4.5+
- Retention at 30 days (the AI-usage-tracker market is high-churn without a real hook; our hook is the pace line)

---

## 10. Open Questions

| Question | Status | Notes |
|---|---|---|
| ChatGPT usage scraping in v1? | **Deferred** | CodexBar does it via WKWebView with known stability issues. Defer to Phase 2 unless users demand it. |
| How do we handle Mac companion not running when iOS asks? | **Resolved** | iOS falls back to "last known" from CloudKit with a "stale" chip; widgets dim; user sees the gap. |
| CloudKit throughput for 5m snapshot cadence? | **Open** | 12 writes/hr per device is well under CloudKit limits. Confirm no throttling on free tier. |
| Watch complication without iOS? | **Deferred** | Phase 3. Watch always pairs with iOS. |
| App name "iCodexBar" | **Keep** | "i" prefix signals iOS-first, "CodexBar" signals the category. Revisit if CodexBar upstream objects. |

---

*Document version: 2.0*
*Last updated: 2026-04-24*
