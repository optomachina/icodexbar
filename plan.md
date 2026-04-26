<!-- /autoplan restore point: /Users/blainewilson/.gstack/projects/optomachina-icodexbar/optomachina-autoplan-review-autoplan-restore-20260425-210603.md -->
# iCodexBar — Development Plan

## Overview

iCodexBar is a privacy-first AI usage tracker. **iOS-first widget experience + Apple Watch + macOS companion.** Dual-mode data model (Quota / Spend / Balance) auto-detected per provider. No backend. All storage in Keychain + user's iCloud via CloudKit. See `PRD.md` v2.0 for product context.

---

## 1. MVP Scope

### What We're Building First

The MVP is split into **three build phases**. iOS is the hero surface, but because the most valuable data (Claude Code + Codex CLI quotas) lives on the Mac, we build macOS foundation first and iOS second. Apple Watch comes last.

#### Phase 1 — macOS foundation (weeks 1–3)

The Mac companion exists for two reasons: it's the only place Claude Code / Codex CLI quota data lives, and it's the category-defining surface (menu bar app) for users who live in the terminal.

| Feature | Priority | Notes |
|---|---|---|
| Menu bar status item (2-bar icon) | P0 | Top bar = session, bottom hairline = weekly |
| Menu bar dropdown with per-provider breakdown | P0 | Pace indicators, relative reset countdowns, refresh/quit |
| Claude Code local reader (`~/.claude/projects/*.jsonl`) | P0 | Session 5h + weekly + cost |
| Codex CLI local reader (`~/.codex/`) | P0 | Session + weekly |
| OpenRouter API polling (balance mode) | P0 | `GET /api/v1/credits` |
| OpenAI billing API polling (spend mode) | P0 | `GET /v1/organization/costs` |
| Anthropic billing polling (spend mode) | P0 | Console billing aggregation + response headers |
| macOS widgets (small, medium, large) | P0 | Notification Center + desktop |
| Keychain storage w/ preflight explanation | P0 | Tell user *why* the OS prompt fires before it fires |
| Refresh cadence presets (manual/1m/2m/5m/15m) | P0 | Battery-aware; default 5m |
| Dim icon on stale/error | P0 | Silent freshness signal |
| Launch-at-login toggle | P0 | Via `SMAppService` |
| "Show as used" / "Show as remaining" toggle | P0 | Default remaining |
| Pace reference line | P0 | On-device computed, both Quota + Spend |
| Merge Icons mode | P1 | One status item, dropdown has all |

#### Phase 2 — iOS + CloudKit sync (weeks 4–6)

Now the Mac side has data and is rendering it locally. Phase 2 plumbs it to iOS and adds iOS-native API-key modes so iOS-only users have a complete product.

| Feature | Priority | Notes |
|---|---|---|
| iOS app shell (Dashboard + Settings) | P0 | TabView, SwiftUI |
| Home Screen widgets (small, medium, large) | P0 | Same visual spine as macOS |
| Lock Screen widgets (circular + inline) | P0 | |
| iOS direct OpenRouter balance | P0 | Works without Mac |
| iOS direct OpenAI spend | P0 | Works without Mac |
| iOS direct Anthropic spend | P0 | Works without Mac |
| Mode auto-detection on key entry | P0 | Key shape → mode |
| CloudKit schema + write from Mac companion | P0 | `UsageSnapshot` record, v1 schema |
| CloudKit read from iOS | P0 | Falls back to direct polling if stale |
| Stale-snapshot indicator in widget | P0 | "Last synced 12m ago" chip |
| Alert thresholds per provider | P0 | Configure in Settings |
| Local notifications | P0 | `UNUserNotificationCenter`, threshold crossings |
| Pull-to-refresh | P0 | Dashboard + widget via App Intent |
| Error / empty / rate-limit states | P0 | Every provider, every surface |
| Widget configuration intent | P0 | Pick default provider per widget instance |
| App icon (all sizes) | P0 | |
| Privacy policy page | P0 | Hosted on GitHub Pages |

#### Phase 3 — Launch prep (week 7)

| Feature | Priority | Notes |
|---|---|---|
| TestFlight beta | P0 | iOS + macOS |
| App Store listing | P0 | Screenshots for iPhone 6.7 / 6.5 |
| Mac App Store listing | P0 | Single bundle |
| Fastlane config | P1 | Optional for MVP |
| Bug bash | P0 | Full matrix: iOS-only / Mac-only / iOS+Mac paired |

### Out of MVP (Post-Launch)

- Apple Watch app + complications → **v1.1**
- Premium tier (StoreKit 2, multi-account, charts, pace predictions, CSV export) → **v1.2**
- Enterprise tier (team dashboards, admin, SSO) → **v2.0**
- ChatGPT web scraping via WKWebView → **Phase 2 decision** (only if users demand)
- Additional providers (Gemini, Cursor, Perplexity, Copilot, etc.) → **v1.2+**
- iPad-specific layouts → **v2.x**

### Platform & Deployment

- **Minimum iOS**: 17.0 (modern WidgetKit, App Intents, SwiftData)
- **Minimum macOS**: 14.0 (Sonoma — unified WidgetKit on desktop, `SMAppService`)
- **Minimum watchOS**: 10.0 (for complications, v1.1+)
- **Devices**: iPhone + Mac (iPad runs iOS target, no custom layouts)
- **Distribution**: Single App Store Connect listing, universal bundle (iOS + macOS)
- **Code signing**: Individual developer account for MVP; move to org later

---

## 2. Milestones

### Milestone 0 — Decisions locked (done)
- [x] PRD v2.0 written with dual-mode data model
- [x] Plan v2.0 restructured into Phase 1 / 2 / 3
- [x] Visual direction locked from design shotgun (D spine, A menu bar, C alt large)
- [x] Branch strategy: plan docs on main, code on feature branches

### Milestone 1 — T&E Slice (week 1)

The narrowest end-to-end slice that proves the architecture. One provider, one mode, one surface family, real data, real rendering.

- [ ] macOS menu bar target (NSStatusItem shell)
- [ ] Claude Code reader: parse `~/.claude/projects/*.jsonl` into `UsageSnapshot`
- [ ] Codex CLI reader: parse `~/.codex/` into `UsageSnapshot`
- [ ] In-memory `UsageStore` shared across menu bar + widget
- [ ] 2-bar menu bar icon (session top, weekly bottom)
- [ ] Dropdown with Claude Code + Codex CLI rows (pace-line, relative reset)
- [ ] Refresh cadence: manual + 5m default
- [ ] Keychain preflight explanation (even though no keys yet, validate the flow)
- [ ] One macOS widget (medium, rendering Variant D pill bars)
- [ ] Launch menu bar app, load real local data, widget stays in sync

**Exit criteria**: opening Claude Code, using some tokens, and watching the menu bar icon + widget update within one refresh cycle. No crashes over a full working day.

### Milestone 2 — Full macOS provider matrix (week 2)

- [ ] OpenRouter polling (balance mode)
- [ ] OpenAI billing polling (spend mode)
- [ ] Anthropic billing polling (spend mode)
- [ ] Mode auto-detection from key shape
- [ ] Merge Icons mode
- [ ] Dim icon on stale/error
- [ ] "Show as used/remaining" toggle
- [ ] macOS widgets: small + large added
- [ ] Settings window (key management, refresh cadence, launch-at-login, inline vs dropdown provider config)
- [ ] Unit tests: JSONL parser, cost calculator, pace-line math, API response models

### Milestone 3 — CloudKit + iOS foundation (week 3)

- [ ] `UsageSnapshot` CloudKit record schema (v1)
- [ ] Mac companion writes snapshot every refresh cycle
- [ ] iOS app target (Dashboard + Settings TabView)
- [ ] iOS reads CloudKit, renders Dashboard
- [ ] iOS direct polling (OpenRouter / OpenAI / Anthropic) when CloudKit is stale/absent
- [ ] Stale-snapshot indicator ("Last synced 12m ago")
- [ ] Dashboard cards per provider (D spine)

### Milestone 4 — iOS widgets (week 4)

- [ ] Home Screen widgets: small, medium, large (Variant D)
- [ ] Alt-large widget: Variant C data-dense (user picks in widget config)
- [ ] Lock Screen widgets: circular + inline
- [ ] Widget configuration intent (pick default provider)
- [ ] Shared App Group for iOS app ↔ widget
- [ ] Background timeline refresh (5m cadence)

### Milestone 5 — Alerts (week 5)

- [ ] Alert threshold model (provider, mode-aware — e.g., session <10% OR spend >80%)
- [ ] Alert configuration UI in iOS Settings
- [ ] Local notifications via `UNUserNotificationCenter`
- [ ] Mac companion also fires notifications
- [ ] Widget visual state reflects alert (color shift past threshold)

### Milestone 6 — Polish & launch prep (week 6–7)

- [ ] App icon + menu bar icon variants (light/dark/template)
- [ ] LaunchScreen
- [ ] Empty states (no keys, no Mac companion, no providers)
- [ ] Error states (invalid key, rate limit, CloudKit unavailable, Mac companion not running)
- [ ] App Store listing (iOS + Mac), screenshots, keywords, privacy label
- [ ] Privacy policy page
- [ ] TestFlight beta builds
- [ ] Bug bash across the device matrix

### Milestone 7 — Apple Watch (v1.1)

- [ ] watchOS target sharing Core module
- [ ] Complications: corner, inline, circular, rectangular
- [ ] Watch reads from iOS App Group (which reads CloudKit)
- [ ] Watch face screenshots for App Store

### Milestone 8 — Premium (v1.2)

- [ ] StoreKit 2 subscription
- [ ] Multi-account model (up to 5)
- [ ] Account labels
- [ ] History view with Swift Charts
- [ ] Pace prediction algorithm (beyond current reference line)
- [ ] CSV export

### Milestone 9 — Enterprise (v2.0)

- [ ] Team model
- [ ] Aggregated team dashboard
- [ ] Per-user breakdown views
- [ ] Admin controls UI
- [ ] Stripe/Chargebee for B2B
- [ ] SSO (SAML/OIDC)

---

## 3. Dev Roadmap

```
Q2 2026
├── Apr 24   – Plan v2.0, design shotgun complete, T&E slice starts
├── Week 1   – T&E slice: Mac menu bar + Claude Code reader + 1 widget
├── Week 2   – Full macOS provider matrix + settings
├── Week 3   – CloudKit + iOS app shell + dashboard
├── Week 4   – iOS widgets (Home Screen + Lock Screen)
├── Week 5   – Alerts (iOS + Mac)
├── Week 6–7 – Polish, TestFlight, App Store submission
├── v1.0 launch target: end of May 2026

Q3 2026
├── v1.1 (Jun) – Apple Watch app + complications
└── v1.2 (Jul) – Premium: multi-account, charts, pace predictions, CSV export

Q4 2026
└── v2.0 (Sep) – Enterprise: team dashboards, admin controls, SSO
```

---

## 4. Dependencies

### External APIs & Data Sources

| Source | Platform | Mode | Auth |
|---|---|---|---|
| OpenAI billing | iOS + macOS | Spend | API key (`sk-proj-…`, `sk-…`) |
| Anthropic billing | iOS + macOS | Spend | API key (`sk-ant-api…`) |
| OpenRouter credits | iOS + macOS | Balance | API key (`sk-or-…`) |
| Claude Code (`~/.claude/projects/*.jsonl`) | macOS only | Quota | File system access (user-granted) |
| Codex CLI (`~/.codex/`) | macOS only | Quota | File system access (user-granted) |
| ChatGPT web | macOS only, Phase 2 | Quota | Browser cookies (user-imported) |

### Apple Frameworks (no third-party SDKs)

| Framework | Purpose |
|---|---|
| SwiftUI | UI across iOS, macOS, watchOS |
| WidgetKit | iOS + macOS widgets |
| ClockKit | watchOS complications (v1.1) |
| App Intents | Siri shortcuts, widget config, refresh action |
| CloudKit | Mac → iOS snapshot sync |
| Keychain Services | API key storage |
| UserNotifications | Local alerts |
| BackgroundTasks | iOS widget timeline refresh |
| ServiceManagement (`SMAppService`) | macOS launch-at-login |
| AppKit (NSStatusItem) | macOS menu bar |
| FileSystemEvents / DispatchSource | Local state watching |
| StoreKit 2 | Subscriptions (v1.2+) |

### Tools

| Tool | Purpose |
|---|---|
| XcodeGen | Project generation from `project.yml` |
| SwiftLint | Code style |
| Fastlane | App Store deploy (optional) |

### No third-party dependencies

For privacy guarantees and stability:
- No Firebase / Analytics / Crashlytics
- No Mixpanel / Amplitude / PostHog
- No networking libraries (URLSession only)
- No cookie-stealing browser integrations in v1 (those are CodexBar's biggest source of bug reports)

---

## 5. Technical Architecture

### Module Structure

```
iCodexBar/
├── Core/                           # Shared across all targets
│   ├── Models/
│   │   ├── Provider.swift          # OpenAI, Anthropic, OpenRouter, ClaudeCode, CodexCLI
│   │   ├── UsageMode.swift         # .quota, .spend, .balance
│   │   ├── UsageSnapshot.swift     # Unified record — provider + mode + payload
│   │   ├── QuotaPayload.swift      # session %, weekly %, resets, pace
│   │   ├── SpendPayload.swift      # MTD cost, budget %, projected EoM, pace
│   │   ├── BalancePayload.swift    # balance, last top-up, burn rate
│   │   ├── APIKey.swift
│   │   └── AlertThreshold.swift
│   ├── Sources/
│   │   ├── UsageSource.swift           # Protocol
│   │   ├── OpenAIAPISource.swift       # Spend
│   │   ├── AnthropicAPISource.swift    # Spend
│   │   ├── OpenRouterAPISource.swift   # Balance
│   │   ├── ClaudeCodeLocalSource.swift # Quota, macOS only
│   │   ├── CodexCLILocalSource.swift   # Quota, macOS only
│   │   └── CloudKitSource.swift        # iOS reads, Mac writes
│   ├── Services/
│   │   ├── KeychainService.swift
│   │   ├── UsageStore.swift        # Aggregates sources, publishes snapshots
│   │   ├── PaceCalculator.swift    # Pace-line math for Quota + Spend
│   │   ├── NotificationService.swift
│   │   └── SubscriptionService.swift   # StoreKit 2 (v1.2+)
│   └── Utilities/
│       ├── DateHelpers.swift
│       ├── CurrencyFormatter.swift
│       └── RelativeCountdown.swift # "Resets in 3h 31m"
├── iOS/
│   ├── App/iCodexBarApp.swift
│   ├── Features/
│   │   ├── Dashboard/
│   │   ├── Settings/
│   │   └── AddAccount/
│   └── Widgets/           # See iCodexBarWidget/ target
├── macOS/
│   ├── App/ICodexBarMacApp.swift
│   ├── MenuBar/
│   │   ├── MenuBarController.swift         # NSStatusItem
│   │   ├── TwoBarIconRenderer.swift        # Icon drawing
│   │   └── DropdownView.swift              # SwiftUI popover
│   ├── Companion/
│   │   ├── FileWatcher.swift               # `~/.claude/`, `~/.codex/`
│   │   └── CloudKitWriter.swift            # Syncs to iCloud
│   └── Widgets/           # Shared with iOS widget target where possible
├── Watch/                 # v1.1
│   ├── App/
│   └── Complications/
├── iCodexBarWidget/       # iOS + macOS widget extension (cross-platform)
└── Resources/
    ├── Assets.xcassets
    └── Info.plist
```

### Data Flow

```
Phase 1 (Mac standalone):
  Local sources + API polling → UsageStore → MenuBar + macOS Widgets

Phase 2 (iOS + Mac paired):
  Mac:   Local sources + API polling → UsageStore → MenuBar + macOS Widgets
                                           ↓
                                    CloudKitWriter → iCloud (private DB)

  iOS:   CloudKit read ← iCloud                 (preferred)
         API polling (OpenRouter / OpenAI / Anthropic)  (fallback + iOS-only modes)
                                ↓
                          UsageStore → iOS UI + iOS widgets (via App Group)
```

### App Groups

- iOS: `group.com.icodexbar.shared` — app ↔ widget ↔ watch
- macOS: same group ID (entitlement applies per-platform)

### CloudKit Schema v1

Record type: `UsageSnapshot`
- `provider: String` (enum raw value)
- `mode: String` (quota | spend | balance)
- `capturedAt: Date`
- `payload: Data` (Codable JSON of the mode-specific payload)
- `sourceDevice: String` (for debugging)

One record per provider, overwritten on each Mac-side refresh.

---

## 6. Testing Strategy

### Unit tests (Core module)
- JSONL parser (fixtures from real `~/.claude/projects/`)
- Codex CLI state parser
- API response parsing (all three providers)
- Pace calculator (edge cases: zero-elapsed, over-100%, behind vs ahead)
- Keychain CRUD (mocked)
- Cost calculation
- Relative countdown formatting

### Widget tests
- Timeline entry generation
- Widget rendering with mock snapshots (each mode, each size, each state)
- Stale-data indicator triggers correctly
- Alert-threshold color shift

### Integration tests
- End-to-end: API key → polling → snapshot → widget
- Mac companion writes CloudKit, iOS reads it (CloudKit test container)
- Claude Code file watcher picks up real `~/.claude/` changes

### Manual testing matrix
- [ ] iOS-only: add OpenAI key → spend widget populates
- [ ] iOS-only: add OpenRouter key → balance widget populates
- [ ] iOS-only: add Anthropic key → spend widget populates
- [ ] Mac-only: Claude Code active → menu bar + macOS widget populate
- [ ] Mac-only: Codex CLI active → menu bar + macOS widget populate
- [ ] iOS + Mac paired: Claude Code quota appears on iOS widget within 5m
- [ ] Mac offline: iOS falls back to direct API, stale chip appears for quota providers
- [ ] Alert threshold crossing fires notification
- [ ] Lock Screen widget installs and renders
- [ ] Widget "show as remaining" toggle works
- [ ] Pace line is visually correct at start-of-week, mid-week, end-of-week
- [ ] Background refresh updates widget without app launch
- [ ] Dark mode throughout
- [ ] Provider accent colors correct

---

## 7. Launch Checklist

### Pre-submission
- [ ] All P0 features working in Phase 1 + 2
- [ ] No hardcoded secrets or placeholder keys
- [ ] App Privacy label: No data collected
- [ ] Privacy policy URL hosted
- [ ] App icons at all sizes
- [ ] LaunchScreen configured
- [ ] Bundle identifiers:
  - iOS: `com.icodexbar.app`
  - Widget: `com.icodexbar.app.widget`
  - macOS: `com.icodexbar.mac`
  - macOS menu bar helper: `com.icodexbar.mac.menubar`
  - Watch: `com.icodexbar.watch` (v1.1)
- [ ] App Group configured on all targets
- [ ] Background Modes: `fetch`, `processing`
- [ ] CloudKit container configured + schema deployed
- [ ] Keychain sharing across iOS ↔ widget (for API keys)

### App Store Connect
- [ ] iOS + macOS listing
- [ ] Screenshots: iPhone 6.7", 6.5", Mac
- [ ] Subtitle / description / keywords
- [ ] Category: Developer Tools / Productivity
- [ ] Age rating: 4+
- [ ] Pricing: Free w/ Premium IAP at $0.99/mo (added in v1.2)
- [ ] Submit for review

### Post-launch
- [ ] Monitor App Store reviews
- [ ] Monitor iOS crash logs + macOS Console
- [ ] GitHub Issues for feature requests
- [ ] v1.1 plan based on user signal (Watch + the most-requested next provider)

---

## 8. Open Questions

| Question | Status | Resolution |
|---|---|---|
| Claude Code JSONL schema stability? | **Open** | Schema has evolved across Claude Code versions. Write parser defensively + unit-test against multiple fixture versions. |
| Codex CLI local state format? | **Open** | Inspect `~/.codex/` on a live install. Confirm what's readable + how session/weekly info is persisted. |
| CloudKit free-tier throughput? | **Open** | 12 writes/hr × N devices. Stay well under limits; verify on TestFlight with real users. |
| What happens when two Macs run the companion for the same iCloud? | **Open** | Idempotent writes, last-write-wins by `capturedAt`. Document in README. |
| ChatGPT scraping in v1 or not? | **Deferred** | CodexBar's biggest bug source. Out of MVP. Revisit after launch if demand signal exists. |
| Keychain access group across iOS + Mac? | **Open** | Test that `kSecAttrAccessGroup` works cross-platform via App Group ID. |
| Mac companion distribution: App Store or notarized DMG? | **Leaning App Store** | Single bundle, universal binary. Requires sandboxing; file watching `~/.claude/` and `~/.codex/` needs bookmark-based user consent. |
| Live Activities (ActivityKit) for alert breaches? | **Deferred** | Apple approval required, low priority. |

---

*Plan version: 2.0*
*Created: 2026-03-27*
*Restructured: 2026-04-24*
---

## /autoplan Review Report

> Generated by /autoplan on 2026-04-25. Restore point at top of file.

### Phase 1 — CEO Review (Strategy & Scope)

#### Step 0A — Premise Challenge

The plan stakes 5 premises. Both review voices independently challenged 4 of 5.

| # | Stated premise | Status | Challenge |
|---|---|---|---|
| 1 | iOS-first is the right wedge — ~60% of MVP audience is iOS-only API-key users (Tier A) | **Disputed** | Both voices: Tier A has weak job-to-be-done. API spend updates daily, not minutely; OpenAI/Anthropic billing dashboards already exist on web. Build order (3 weeks Mac before any iOS) contradicts the iOS-first stance. |
| 2 | Pace line is the central differentiator | **Disputed** | Both voices: CodexBar already has risk forecasting; iPhone competitor "AI Limits & Reset Tracker" already markets "Usage Pace." Pace ships in ~200 lines. Not a moat — table stakes. |
| 3 | One developer in 7 weeks ships iOS app + macOS menu bar + 2 file readers + 3 API integrations + CloudKit + widgets (iOS+macOS) + Lock Screen widgets + alerts + onboarding + 2 App Store reviews | **Disputed (critical)** | Both voices: realistic estimate 14–18 weeks. CloudKit alone is ~2 weeks. Sandbox vs `~/.claude` reading is its own problem. |
| 4 | Three-mode (Quota/Spend/Balance) auto-detected by key shape is a clean, durable abstraction | **Disputed** | Both voices: shapes share zero math; key-shape coupling is leaky; first new provider (Cursor, Copilot, Gemini) breaks it. Better: model "provider + source" explicitly, treat shapes as render types. |
| 5 | No backend / no analytics / no telemetry compatible with §9 success metrics (widget add rate, Mac companion install rate, alert config rate, premium conversion, 30-day retention) | **Disputed (critical)** | Both voices: cannot validate the differentiation hypothesis without instrumentation. RevenueCat + opt-in event pings are privacy-safe alternatives. |
| 6 | Existing market has no iOS widget for AI usage | **Stale** | Codex (web search): "AI Limits & Reset Tracker" already ships iPhone+Mac, widgets, alerts, history, pace. The "first iOS widget" framing is outdated. |

**Premise gate** — see AskUserQuestion below. Premises require human judgment; not auto-decided.

#### Step 0.5 — Dual Voices

##### CODEX SAYS (CEO — strategy challenge)

10 findings. Top critical:
- **STALE MARKET MAP** (critical) — "AI Limits & Reset Tracker" already ships iPhone+Mac+widgets+pace; CodexBar covers 16+ providers. Premise of "first iOS version" is outdated.
- **SEGMENT-SEQUENCING CONTRADICTION** (critical) — PRD says 60% iOS-only, plan starts with 3 weeks of macOS. Pick one truth.
- **THIS MVP IS TWO PRODUCTS PLUS A SYNC LAYER** (critical) — 7 weeks for one dev is portfolio-scale, not MVP-scale. Cut to one platform, one job.
- **NO TELEMETRY MEANS NO LEARNING** (critical) — §9 success metrics literally cannot be measured given §6's no-analytics rule.
- **PACE IS NOT A DIFFERENTIATOR** (high) — competitors already have it.
- **SPEND PACE HAS FAKE PRECISION** (high) — quota pace is grounded; spend pace assumes a budget denominator that doesn't exist by default.
- **THE THREE-MODE MODEL IS EARLY OVER-ARCHITECTURE** (high) — auth-shape→mode is leaky; provider+source is cleaner.
- **CURATED TO FIVE PROVIDERS** (high) — power users accumulate providers; curating yourself out of relevance.
- **ENTERPRISE IS STRATEGIC FICTION** (medium) — local-only, no-backend utility cannot graduate to team dashboards + SSO without architectural pivot.

##### CLAUDE SUBAGENT (CEO — strategic independence)

10 findings. Top critical:
- **WRONG CATEGORY, WRONG GRAVITY** (critical) — Mac is where the work happens. iOS Lock Screen widget for "you spent $4.12 today" is solution-looking-for-problem. Tier A persona has no urgent JTBD.
- **7-WEEK TIMELINE IS COSPLAY** (critical) — Realistic 14–18 weeks. CloudKit, sandbox, JSONL parser drift each eat a week.
- **NO-BACKEND/NO-ANALYTICS LOCKS YOU OUT OF LEARNING** (high) — Privacy-first ≠ blind. Opt-in event pings + RevenueCat are privacy-safe.
- **THREE-MODE ABSTRACTION** (high) — Quota/Spend/Balance share zero math. Cursor/Copilot break it on contact.
- **COMPETITOR WILL EAT YOU IN 3 MONTHS** (high) — CodexBar can clone an iOS widget in a weekend if signal emerges.
- **BUILD ORDER CONTRADICTS STRATEGY** (high) — 3 weeks Mac before any iOS guarantees rushed iOS surface.
- **TIER A PERSONA HAS NO NEED** (high) — drop it; build for Tier B (Mac+iOS Claude Code) and Tier C (Mac-only).
- **MAC APP STORE SANDBOX VS FILE-WATCHING** (medium) — security-scoped bookmarks per project dir is a Phase 8 problem; ship notarized DMG.
- **CLOUDKIT AS THE SYNC MECHANISM IS A FOOT-GUN** (medium) — schema deploys are non-reversible; ship Mac standalone, add sync after demand is proven.
- **NO DISTRIBUTION PLAN** (medium) — App Store search for "AI usage" returns 50 apps; need launch wedge.

##### CEO Dual Voices — Consensus Table

```
═══════════════════════════════════════════════════════════════════════════
  Dimension                                  Claude   Codex   Consensus
  ────────────────────────────────────────── ───────  ──────  ───────────
  1. Premises valid?                         NO       NO      CONFIRMED — disputed
  2. Right problem to solve?                 PARTIAL  NO      DISAGREE on framing,
                                                              both reject Tier A
  3. Scope calibration correct?              NO       NO      CONFIRMED — too big
  4. Alternatives sufficiently explored?     NO       NO      CONFIRMED — gaps
  5. Competitive/market risks covered?       NO       NO      CONFIRMED — stale map
  6. 6-month trajectory sound?               NO       NO      CONFIRMED — at risk
═══════════════════════════════════════════════════════════════════════════
CONFIRMED = both agree. 6/6 confirmed problems. This plan needs premise reset
before continuing detailed review.
```

**Cross-phase signal candidates:**
- Three-mode abstraction concerns (will resurface in Eng phase)
- 7-week timeline (will resurface in Eng phase test/scope review)
- No-telemetry blocks success metrics (will resurface in DX phase)

#### Step 0B — Existing Code Leverage Map

| Sub-problem | Existing code | Status |
|---|---|---|
| iOS app shell (Tab) | `iCodexBar/App/iCodexBarApp.swift` | Built — stub |
| Settings UI | `iCodexBar/Features/Settings/SettingsView.swift`, `APIKeyEntryView.swift` | Built — basic |
| Dashboard UI | `iCodexBar/Features/Dashboard/DashboardView.swift`, `UsageCardView.swift`, `DashboardViewModel.swift` | Built — basic |
| Keychain | `iCodexBar/Core/Services/KeychainService.swift` | Built — **bug at line 95** (wrong delete signature) |
| Usage store | `iCodexBar/Core/Services/UsageStore.swift` | Built — Spend-only model, no Quota/Balance modes |
| OpenAI / OpenRouter / Anthropic API | `iCodexBar/Core/Services/UsageAPIService.swift` | Built — **multiple bugs** (wrong endpoints, wrong headers, no Quota mode) |
| Notifications | `iCodexBar/Core/Services/NotificationService.swift` | Built — basic |
| Background refresh | `iCodexBar/Core/Services/BackgroundRefreshService.swift` | Built — basic |
| Widget extension | `iCodexBarWidget/iCodexBarWidget.swift` | Built — basic |
| Models (UsageData, ProviderUsageSnapshot, RateWindow, AlertThreshold, Provider, APIKey, DailyUsageEntry) | `iCodexBar/Core/Models/*` | Built — but no `UsageMode`, no `QuotaPayload`, no `SpendPayload`, no `BalancePayload` (plan spec mismatch) |
| **macOS menu bar** | — | **Missing entirely** |
| **macOS target** | — | **Missing in `project.yml` — only iOS targets defined** |
| **Claude Code reader** | — | Missing |
| **Codex CLI reader** | — | Missing |
| **CloudKit schema/writer/reader** | — | Missing |
| **Mode auto-detection** | — | Missing |
| **Pace calculator** | — | Missing |
| **App Group keychain group** | — | Set to `nil` — keys won't share with widget |

**Findings:**
- The plan declares "Phase 1: macOS foundation (weeks 1–3) — build macOS first because Claude Code/Codex CLI quota lives there." There is no macOS target. There is no menu bar code. The Mac side is 0% built.
- The iOS side has been built ahead of the Phase 2 plan (Settings, Dashboard, API keys, usage store, widget extension) — but built against a Spend-only data model that contradicts the plan's tri-mode design.
- The current iOS code has 4+ bugs that would prevent it from working with real API keys (wrong OpenAI endpoint, wrong Anthropic auth header, broken Keychain delete signature, malformed Anthropic version header). See Eng phase for line numbers.
- The plan's milestones 1–6 do not match the implementation state. Either the plan is wrong (we are iOS-first, not Mac-first) or the implementation is wrong (built the wrong platform first).

#### Step 0C — Dream State Diagram

```
CURRENT (today, 2026-04-25):
  • iOS scaffold (~21 swift files, builds for iOS only)
  • 3 API integrations stubbed but broken (OpenAI endpoint, Anthropic auth, Keychain delete)
  • No mode model (Quota/Spend/Balance) — only Spend in code
  • No macOS target, no menu bar, no Mac→iOS sync
  • Plan claims Phase 1 = 3 weeks of Mac; reality = iOS shell already built

THIS PLAN (end of week 7):
  • macOS menu bar + dropdown + widgets
  • iOS app + Home + Lock Screen widgets
  • CloudKit Mac→iOS sync
  • All 5 providers wired, 3 modes auto-detected
  • Alerts on iOS + Mac
  • TestFlight beta + App Store submission

12-MONTH IDEAL (end of Q2 2027):
  • One platform (Mac OR iOS) shipped, polished, ~1k MAU
  • One mode (Quota OR Spend) demonstrably driving retention
  • Validated demand for second platform from real signals
  • Premium conversion proven ≥3%
  • Defensible wedge that survives CodexBar copying it (e.g., proprietary
    quota normalization across CLI tool versions, OR enterprise team mode
    backed by a real backend, OR specific workflow integration like Slack
    notification-on-quota-cross)
  • Distribution loop running (HN/podcast/Show HN/blog cadence)

DELTA (this plan vs ideal):
  • Plan does too much for one dev in 7 weeks — likely ships shallow on
    everything, deep on nothing
  • Plan does not address distribution (app discovery)
  • Plan does not validate "iOS-first" hypothesis before committing
  • Plan does not have a measurement loop to detect retention failure
```

#### Step 0C-bis — Implementation Alternatives Table

| Alternative | Effort (1 dev) | Risk | Pros | Cons |
|---|---|---|---|---|
| **A. Plan as-written** (Mac + iOS + CloudKit, 7 weeks) | 14–18 weeks realistic | Critical | Full platform coverage; matches PRD vision | Ships shallow on everything; iOS likely undertested; no measurement loop |
| **B. Mac-first only** (8 weeks Mac MVP, iOS as v1.1) | 6–8 weeks | Medium | Targets Tier B/C (real JTBD); avoids CloudKit until demand proven; competes head-on with CodexBar polish | Drops Tier A persona; "iOS-first" branding becomes misleading; need to rewrite PRD |
| **C. iOS-only** (8 weeks iOS MVP, Mac companion as v1.1) | 6–8 weeks | High (Tier A weak JTBD) | Aligns with stated "iOS-first"; lighter sandboxing; faster App Store path | Bets on Tier A persona that both reviewers say has no JTBD; loses Quota providers (Claude Code, Codex CLI) — the differentiated data |
| **D. Concierge beta** (2 weeks scrappy Mac CLI/menu bar, 10 hand-picked Claude Code users, validate retention) | 2 weeks | Low | Cheapest validation; learns from real usage; rewrites PRD before committing 14+ weeks | No App Store launch in MVP; founder-led only; doesn't ship "the product" |

#### Step 0D — Mode-Specific Analysis (SELECTIVE EXPANSION)

Auto-decided expansions (in blast radius, ≥1 day CC effort, but high impact):

| Expansion | Status | Principle | Rationale |
|---|---|---|---|
| Add "What we're explicitly NOT building" section to plan | **APPROVE** | P1 (completeness) | Plan currently buries non-goals; making them explicit prevents scope creep |
| Add an opt-in privacy-safe telemetry track (RevenueCat + event ping for widget add / alert config / pair rate) | **APPROVE** | P1 (completeness) | Without this, §9 success metrics are unmeasurable. Both reviewers flagged. <1 day to wire RevenueCat. |
| Add measurement plan to PRD: how do we know if pace line is working? | **APPROVE** | P1 (completeness) | Differentiation hypothesis is currently unfalsifiable |
| Replace "Auth shape → mode" with "Provider + source → render type" abstraction | **DEFER → TODOS.md** | P3 (pragmatic) | Would require refactoring existing code; defer until 4th provider arrives |
| Drop Enterprise from roadmap entirely | **APPROVE** | P3 (pragmatic) | Both reviewers: not a natural extension of local-only architecture; pretending it's planned creates false promises |
| Add "Distribution plan" section | **APPROVE** | P1 (completeness) | Currently §7 only covers App Store submission. App discovery is not addressed. |
| Drop Anthropic spend mode from MVP (no public billing API) | **APPROVE** | P5 (explicit) | Current code uses fake projection; spend mode there is misleading. Either remove or label clearly as "estimate." |
| Mac App Store vs notarized DMG decision | **DECIDE: notarized DMG for Mac, App Store for iOS** | P5 (explicit) | Sandbox + `~/.claude` is a known foot-gun; both reviewers agree. |

**Scope reductions** (P1 says don't reduce; but premises are wrong, so reductions are not "reducing scope," they are "fixing scope"):

These are deferred to the premise gate — user decides at the AskUserQuestion below.

#### Step 0E — Temporal Interrogation

| Hour | What's happening |
|---|---|
| Hour 1 (Day 1) | Plan reread; user reckons with the consensus and either accepts a premise reset OR commits to plan-as-written knowing the risks |
| Hour 6 | If reset accepted: PRD v3 written; if not: T&E slice on Mac begins |
| Day 3 | First unit test fails on Claude Code JSONL parser — schema is more variable than expected; ~2 days of fixture work added |
| Week 2 | OpenAI billing endpoint returns 410 Gone — `/v1/billing/usage` is deprecated. Realize plan's API spec was wrong. Migrate to `/v1/organization/costs`. ~3 days lost. |
| Week 3 | CloudKit dev container works; production deploy stalls because schema iterations are not reversible. ~2 days. |
| Week 5 | Sandbox + bookmark refresh on macOS broken; rewrite to notarized DMG. ~3 days. |
| Week 7 | Discover that no analytics means we have no idea if anyone is adding widgets. Ship anyway, fly blind for 30 days. |
| Month 3 | CodexBar adds an iOS widget in a weekend. Differentiation evaporates. App Store rating still ~30 reviews. |
| Month 6 | Pivot conversation. |

#### Step 0F — Mode Selection

**Recommended mode: SCOPE REDUCTION + PREMISE RESET.**

The plan, as written, fails the CEO review at the premise level. Continuing with SELECTIVE EXPANSION assumes the foundation is sound and we cherry-pick. The foundation is contested. Auto-deciding to keep going would push critical doubt down the funnel and waste reviews on a plan that needs rewriting.

The 6 principles do not let me unilaterally rewrite the plan. The user must reckon with the premises first. **This is the gate.**


#### Decision Audit Trail (Phase 1 — partial)

| # | Phase | Decision | Classification | Principle | Rationale | Rejected |
|---|---|---|---|---|---|---|
| 1 | CEO | Run BOTH Codex + Claude subagent (dual voices) | mechanical | P6 (action) | Always run both when available | Single-voice mode |
| 2 | CEO | Add explicit "NOT in scope" section | mechanical | P1 (completeness) | Plan needs guardrails | Skip section |
| 3 | CEO | Add opt-in telemetry track (privacy-safe) | TASTE | P1 (completeness) | Can't validate metrics without it; both reviewers flagged. Tradeoff: privacy purity vs learning loop | No-telemetry purity |
| 4 | CEO | Defer "Auth shape → mode" refactor to TODOS.md | mechanical | P3 (pragmatic) | Out of MVP blast radius; refactor when 4th provider arrives | Refactor now |
| 5 | CEO | Drop Enterprise from roadmap | TASTE | P3 (pragmatic) | Architectural mismatch; misleads users about direction. Tradeoff: roadmap optics vs honesty | Keep roadmap theater |
| 6 | CEO | Add Distribution plan section | mechanical | P1 (completeness) | Plan has zero app-discovery story | Skip |
| 7 | CEO | Drop Anthropic spend mode (or label as estimate) | mechanical | P5 (explicit) | No public billing API; current "projection" is fiction | Keep misleading label |
| 8 | CEO | Choose notarized DMG for Mac, App Store for iOS | TASTE | P5 (explicit) | Both reviewers flag sandbox as foot-gun. Tradeoff: discovery vs reliability | App Store both, fight sandbox |
| 9 | CEO | Mode selection: SCOPE REDUCTION + PREMISE RESET | **GATE** | — | Cannot auto-decide; premises require human judgment | Continue with SELECTIVE EXPANSION |


#### Premise Gate Resolution

User decision (D1, 2026-04-25): **A) Accept premises as-stated, continue review.**

Per plan-ceo-review skill: user has founder context the reviewers lack. Premises stand. The 4 disputed premises (iOS-first wedge, pace line moat, 7-week timeline, no-telemetry compatible with §9 metrics) are logged for visibility but not blocking. Eng/Design/DX phases will surface implementation-level concerns that trace back to these premises; the final approval gate will let you reconcile them.


---

### Phase 2 — Design Review (UI scope)

#### Step 0 — Design Scope Assessment

- **Initial design completeness:** 4/10. PRD §3 (modes) and §7 (tokens) are well-articulated, but the implementation flattens three modes into one Spend-shaped layout, omits the pace line, and ignores Variant D tokens.
- **Existing patterns mapped:**
  - `iCodexBar/Features/Dashboard/UsageCardView.swift` — Spend-shaped card; no mode switch.
  - `iCodexBarWidget/iCodexBarWidget.swift` — Small/Medium/Large + Lock Screen Circular/Inline; system tokens; no pace tick; Inline never wired.
  - `iCodexBar/Features/Settings/SettingsView.swift` — single 50–100% slider for all alert thresholds; misses mode semantics.
  - `iCodexBar/Core/Models/Provider.swift` — accent colors implemented (`#10A37F`, `#CC785C`, `#E63946`); only 3 providers (no Claude Code, no Codex CLI).
- **Design system source:** `~/.gstack/projects/optomachina-icodexbar/designs/widgets-20260423/` (Variant D + A + C). DESIGN.md does not exist at repo root.

#### Step 0.5 — Dual Voices

##### CODEX SAYS (design — UX challenge)

10 findings. Top:
- **HIERARCHY DRIFTS BY SURFACE** (critical) — small/medium/large widgets each lead with different things; Dashboard buries reset; macOS surfaces are unbuilt.
- **THREE MODES ARE NOT ACTUALLY DESIGNED, JUST NAMED** (critical) — UsageCardView always shows Cost+Tokens; ProviderUsageSnapshot has no mode field.
- **PACE LINE IS THE CLAIMED MOAT BUT IT DOES NOT EXIST IN UI OR MODELS** (critical) — no tick, no pace state, no math.
- **STALE STATE IS REQUIRED BUT IMPOSSIBLE TO PERCEIVE** (high) — `loadEntry()` stamps `Date()` instead of fetch time.
- **EMPTY/ERROR/PARTIAL STATES UNDER-SPECIFIED** (high) — only 1 dashboard empty state; 1 generic error string.
- **VARIANT D TOKENS NOT IMPLEMENTED** (high) — code uses `.fill.tertiary`, `.systemBackground`, no warm charcoal, no SF Pro Display, no monospaced numerals.
- **LOCK SCREEN INLINE EXISTS ON PAPER ONLY** (high) — declared in supportedFamilies, never rendered.
- **ALERT THRESHOLD UX IS SEMANTICALLY WRONG** (high) — single 50–100% slider for opposite-direction semantics (Quota <10% vs Spend >80%).
- **WIDGET PROVIDER SELECTION NON-INTENTIONAL** (medium) — `snapshots.keys.first`, no widget config intent.
- **ACCESSIBILITY UNSPECIFIED** (medium) — no VoiceOver labels, no Dynamic Type guards, no contrast verification.

##### CLAUDE SUBAGENT (design — independent review)

11 findings. Top:
- **DATA MODEL IS SPEND-SHAPED; QUOTA AND BALANCE BOLTED ON** (critical) — same critical convergence as Codex.
- **PACE REFERENCE LINE NOT BUILT, NOT SPEC'D VISUALLY** (critical) — convergent.
- **LOCK SCREEN CIRCULAR BORDERLINE UNUSABLE; INLINE WIRED BUT UNINFORMATIVE** (critical) — `Int(percent)` ambiguous (used vs remaining); body always renders Circular regardless of family.
- **VISUAL TOKENS FROM PRD §7 ABSENT** (high) — convergent.
- **ALERT THRESHOLD SLIDER WRONG SEMANTICS FOR TWO OF THREE MODES** (high) — convergent.
- **NO STATE FOR MAC COMPANION NOT RUNNING / PARTIAL CLOUDKIT / STALE** (high) — convergent.
- **INFORMATION HIERARCHY: SMALL WIDGET SHOWS WRONG NUMBER FIRST** (high) — Cost as hero is emotionally neutral; should be percent (Spend), session% + reset (Quota), or $ remaining (Balance).
- **ACCESSIBILITY ISSUES SPECIFIC** (high) — bar track `Color.white.opacity(0.2)` on charcoal fails WCAG AA contrast.
- **PROVIDER MODEL LOCKED TO 3, DUAL-MODE INVISIBLE IN CODE** (medium) — no UsageMode enum, no Claude Code/Codex CLI cases.
- **SETTINGS IA: SHOWS THRESHOLD ROWS FOR UNUSED PROVIDERS** (medium) — also missing Refresh Cadence + Show-as-Used/Remaining (both P0 in plan).
- **EMPTY / CONFIGURED / PARTIAL TRANSITIONS ABRUPT** (medium) — graveyard of "No data" cards instead of inviting CTA.

##### Design Dual Voices — Consensus Table

```
═══════════════════════════════════════════════════════════════════════════
  Dimension                                  Claude   Codex   Consensus
  ────────────────────────────────────────── ───────  ──────  ───────────
  1. Mode-specific rendering designed?       NO       NO      CONFIRMED
  2. Pace line built/specified?              NO       NO      CONFIRMED
  3. Visual hierarchy consistent?            NO       NO      CONFIRMED
  4. Variant D tokens applied?               NO       NO      CONFIRMED
  5. State matrix complete (loading/empty/   NO       NO      CONFIRMED
     error/stale/partial)?
  6. Lock Screen surfaces built correctly?   NO       NO      CONFIRMED
  7. Alert threshold UX mode-aware?          NO       NO      CONFIRMED
  8. Accessibility specified?                NO       NO      CONFIRMED
═══════════════════════════════════════════════════════════════════════════
8/8 confirmed problems. Two reviewers, fully independent, full agreement.
```

#### Passes 1–7 — Auto-decisions logged

| # | Issue | Decision | Principle |
|---|---|---|---|
| D1 | Mode-specific rendering missing → introduce `UsageMode` enum + per-mode `@ViewBuilder` switch in UsageCardView and widgets | **APPROVE — fix in Eng phase via test plan** | P1 (completeness) |
| D2 | Pace line absent → spec the math (`paceFraction = elapsed / period`) and 1px tick render in every bar component | **APPROVE — required, blocks differentiation claim** | P1 (completeness) |
| D3 | Lock Screen inline never rendered → branch on `widgetFamily` like home widgets | **APPROVE — bug, must fix** | P5 (explicit) |
| D4 | Variant D tokens not applied → introduce `DesignTokens.swift` (`Color.warmCharcoal`, `Font.heroNumber.monospacedDigit()`) | **APPROVE** | P1 (completeness) |
| D5 | Alert threshold slider wrong semantics → split into 3 threshold types (`.quotaRemainingBelow`, `.spendUsedAbove`, `.balanceRemainingBelow`) | **APPROVE** | P5 (explicit) |
| D6 | Stale indicator missing → carry `lastSnapshotAge` in entry; >15m dim, >1h chip "Synced X ago" | **APPROVE** | P1 (completeness) |
| D7 | "No Mac companion" empty state missing → add explicit empty variant per provider card | **APPROVE** | P1 (completeness) |
| D8 | Bar track contrast fails WCAG AA on charcoal → `opacity(0.35)` minimum, verify with Accessibility Inspector | **APPROVE — accessibility fix** | P1 (completeness) |
| D9 | Widget provider selection non-deterministic → add WidgetConfigurationIntent (already in plan but not coded) | **APPROVE — already in plan** | P5 (explicit) |
| D10 | Settings missing Refresh Cadence + Show-as-Used/Remaining toggle (both P0) | **APPROVE — bug, both are listed in plan §1 Phase 1 P0** | P1 (completeness) |
| D11 | Hierarchy drift: small widget hero is "Cost" → mode-aware hero | **APPROVE** | P1 (completeness) |
| D12 | "Anthropic Spend" mode shows fake projection (no public billing API) → either remove from MVP or label clearly as "Estimate from response headers" | **TASTE DECISION** — surfaced at gate. Tradeoff: drop persona vs ship misleading data | P5 (explicit) |
| D13 | Dashboard graveyard cards → iterate `configuredProviders`, append "Add provider" CTA | **APPROVE** | P5 (explicit) |
| D14 | Accessibility: VoiceOver labels, Dynamic Type guards, Reduce Motion checks → require per-surface acceptance criteria added to plan | **APPROVE — added to plan** | P1 (completeness) |

#### Design Litmus Scorecard (7 dimensions)

| Dimension | Score | Notes |
|---|---|---|
| Information hierarchy | 3/10 | Drifts across surfaces; hero is wrong number per mode |
| State coverage (loading/empty/error/stale/partial) | 3/10 | Only no-key empty state + generic error string |
| Mode-specific rendering | 1/10 | One Spend-shaped layout for three semantic shapes |
| Visual tokens (Variant D) | 2/10 | System defaults; no warm charcoal, no tabular-lining |
| Pace line | 0/10 | Not built, not spec'd visually, no math model |
| Accessibility | 2/10 | No VoiceOver labels; contrast unverified; no Dynamic Type guards |
| Animation & motion | 2/10 | PRD calls out subtle number roll-up + pace-tick slide; not implemented; no Reduce Motion fallback |
| **Average** | **1.9/10** | Design plan ahead of code; code is prototype-grade |


---

### Phase 3 — Eng Review

#### Step 0 — Scope Challenge (read the actual code)

| Sub-problem | Code reference | Status |
|---|---|---|
| iOS app shell | `iCodexBar/App/iCodexBarApp.swift` | Built, basic |
| iOS Dashboard + Settings | `iCodexBar/Features/{Dashboard,Settings}/*` | Built, basic |
| iOS widget (Home Screen + Lock Screen) | `iCodexBarWidget/iCodexBarWidget.swift` | Built; Lock Screen Inline never rendered |
| Keychain | `iCodexBar/Core/Services/KeychainService.swift` | **Compile error at line 95**; access group nil |
| 3 API integrations (OpenAI/Anthropic/OpenRouter) | `iCodexBar/Core/Services/UsageAPIService.swift` | **All three broken**: wrong OpenAI endpoint, wrong Anthropic auth+version+model, OpenRouter timeout race buggy |
| Background refresh | `iCodexBar/Core/Services/BackgroundRefreshService.swift` | Built; **double-completion race** in `handleBackgroundRefresh` |
| Notifications + threshold eval | `iCodexBar/Core/Services/NotificationService.swift`, `UsageStore.swift:140-175` | Built; **wrong direction for Quota / Balance modes** |
| `UsageMode` enum + per-mode payloads | — | **Missing entirely** |
| Pace calculator | — | **Missing entirely** |
| `~/.claude/projects/*.jsonl` parser | — | Missing |
| `~/.codex/` parser | — | Missing |
| Mode auto-detection from key shape | — | Missing |
| CloudKit schema/writer/reader | — | Missing |
| **macOS target** | — | **Missing — `project.yml` only has iOS** |
| **watchOS target** | — | Missing (acceptable for v1.1) |
| Tests for parsers, threshold edge crossings, widget timeline rendering | — | **Existing tests partially stale** — `ProviderUsageSnapshotTests.swift:24` and `NotificationServiceTests.swift:17,30,42` call signatures that don't exist |

**Reality check:** Phase 1 of the plan ("macOS foundation, weeks 1–3") is 0% scaffolded. Phase 2 of the plan (iOS) is partially scaffolded but with broken API integrations and a Spend-shaped data model that contradicts the tri-mode architecture in §3 of the PRD.

#### Step 0.5 — Dual Voices

##### CODEX SAYS (eng — architecture challenge)

15 findings. Top:
- **KEYCHAIN OVERWRITE PATH DOESN'T COMPILE** (critical) — `KeychainService.swift:95` calls `delete(key:service:)`; only `delete(for:in:)` exists. Compile error.
- **ANTHROPIC REQUEST HEADERS ARE WRONG** (critical) — `UsageAPIService.swift:333` uses `Authorization: Bearer` (should be `x-api-key`); `:334` sets the value to `"anthropic-version: 2023-06-01"` (the field name doubled inside the value).
- **OPENAI SPEND CLIENT POINTED AT THE WRONG API SHAPE** (critical) — `UsageAPIService.swift:55` calls `/v1/billing/usage` (deprecated, dashboard-only). PRD says use `/v1/organization/costs`.
- **OPENAI "PERCENT USED" IS MATHEMATICALLY FAKE** (high) — `:100` computes `totalCost / projectedCost`, which collapses to "fraction of month elapsed" for any nonzero spend. There is no budget input despite PRD §3.2 calling for "% of $1,200 budget."
- **ANTHROPIC "SPEND" MODE IS AN ESTIMATE MASQUERADING AS BILLING** (high) — `:323` makes a billable `/v1/messages` ping, scrapes a header that doesn't exist, and accumulates totals in UserDefaults. Not authoritative billing.
- **BACKGROUND REFRESH CAN COMPLETE THE SAME TASK TWICE** (high) — `BackgroundRefreshService.swift:107` — expirationHandler calls `setTaskCompleted(false)` while the inner Task also calls `setTaskCompleted` at lines 123/126/129. Race violates BGTask's one-completion contract.
- **KEYCHAIN NOT SHARED WITH WIDGET / FUTURE MAC TARGET** (high) — `KeychainService.swift:36` `accessGroup = nil`. App Group ≠ Keychain sharing. Widget can never read keys from Keychain directly; only the cached `UserDefaults` snapshot.
- **SHARED STORE + ACTOR CALLS NOT STRICT-CONCURRENCY SAFE** (high) — `UsageStore.swift:32` is `@Observable` singleton with no `@MainActor` isolation, mutated from async task groups. `UsageStore.swift:90`, `APIKeyEntryView.swift:123`, `DashboardViewModel.swift:21` call actor-isolated `KeychainService` synchronously without `await`.
- **THE THREE-MODE ARCHITECTURE EXISTS ONLY IN DOCS** (high) — convergent with Design phase.
- **CLOUDKIT SCHEMA HAS NO VERSION FIELD AND NO UPGRADE STORY** (high) — proposed record in `plan.md:350` has no `schemaVersion`, opaque `payload: Data` is hostile to migrations + CloudKit queries. PRD §4.1 promises versioning from day one — not delivered.
- **MAC APP STORE DISTRIBUTION CONFLICTS WITH FILE ACCESS MODEL** (high) — sandbox vs `~/.claude` reading. Same as CEO finding.
- **THE ROADMAP IS MAC-FIRST, BUT THE PROJECT IS NOT** (high) — `project.yml` has zero macOS targets. Same as CEO finding.
- **TEST STRATEGY MOSTLY ASPIRATIONAL + SOME TESTS ARE STALE** (high) — `ProviderUsageSnapshotTests.swift:24` calls a nonexistent `DailyUsageEntry` initializer; `NotificationServiceTests.swift:17/30/42` target signatures that do not exist. Suite likely doesn't build today.
- **ALERT THRESHOLDS CANNOT REPRESENT MODE-AWARE RULES** (medium) — single `thresholdPercent` field cannot express "session remaining <10%" or "balance <$5".
- **`ARMV7` IS STALE FOR AN iOS 17 APP** (medium) — `Info.plist:37` declares `armv7` as a required device capability. iOS 17 is arm64-only; iPhone 4S was the last armv7 device. Remove `UIRequiredDeviceCapabilities` entirely.

**Codex confirmed false positives in my hypothesis list:** `BGTaskSchedulerPermittedIdentifiers` IS present (`Info.plist:47`); `UIBackgroundModes` with `fetch`+`processing` IS present (`:51`). The actual BG defect is the double-completion race.

##### CLAUDE SUBAGENT (eng — independent review)

18 findings. Top:
- **`UsageStore.shared` IS `@Observable` MUTATED FROM BACKGROUND TASKS — Swift 6 DATA RACE** (critical) — convergent.
- **APP GROUP KEYCHAIN GROUP IS NIL — WIDGET CANNOT READ API KEYS** (critical) — convergent.
- **OPENAI BILLING ENDPOINT IS THE DEPRECATED `/v1/billing/usage`** (critical) — convergent. Adds detail: even the new `/v1/organization/costs` requires an *admin* key (`sk-admin-…`), not a standard `sk-…` key. Document this prerequisite in onboarding.
- **ANTHROPIC AUTH HEADER MALFORMED — EVERY REQUEST 401s** (critical) — convergent. Adds detail: `httpResponse.value(forHTTPHeaderField: "anthropic-usage")` reads a header that does not exist; usage is in JSON body. Code throws away the body (`(_, response) = ...`).
- **THREE-MODE DATA MODEL NOT ENFORCED — RENDER-TIME GUESSWORK** (critical) — convergent.
- **OPENROUTER `fetchKeyInfo` RACE TIMEOUT IS BROKEN** (high) — `withTaskGroup` reads `group.next()` once; on a normal connection 1s sleep wins. Also `result ?? nil` is a typo for double-Optional collapse. Drop the task group; use `URLSessionConfiguration.timeoutIntervalForRequest` (already 2s on the request).
- **WIDGET TIMELINE NEVER AGES — STALE DATA MASQUERADES AS FRESH** (high) — `iCodexBarWidget.swift:44-62` stamps `Date()` instead of `lastFetchedKey`. User offline 6h → widget claims "now."
- **WIDGET PROVIDER SELECTION NON-DETERMINISTIC** (high) — `snapshots.keys.first` varies each launch. Use `.sorted` until WidgetConfigurationIntent ships.
- **ALERT THRESHOLD SEMANTICS WRONG FOR TWO OF THREE MODES** (high) — convergent.
- **CLOUDKIT CONTAINER + ENTITLEMENT ENTIRELY MISSING — PHASE 2 CANNOT START** (high) — convergent.
- **BG 30s BUDGET vs THREE SERIAL HTTP CALLS + `try` ON NON-THROWING `fetchAll`** (high) — convergent (double-completion). Adds: `try fetchTask.value` is meaningless; `await UsageStore.shared.fetchAll()` doesn't throw.
- **`keychainService` BUILDS NESTED PATH; `save` CALLS NONEXISTENT `delete(key:service:)`** (high) — convergent. Suite likely doesn't compile.
- **`project.yml` HAS ZERO macOS TARGETS** (high) — convergent.
- **MAC APP STORE SANDBOX vs `~/.claude/projects/*.jsonl` UNSOLVED** (high) — convergent.
- **`CodingKeys` IN `ProviderUsageSnapshot` IS PRIVATE AT FILE SCOPE — DOES NOTHING** (medium) — file-scope `private enum CodingKeys` is unused; `Codable` synthesis only honors nested `CodingKeys`. Encoded shape silently changes if a field is renamed. CloudKit migration foot-gun.
- **`UserDefaults.synchronize()` REPEATEDLY + APP GROUP CROSS-PROCESS LATENCY** (medium) — `.synchronize()` is a no-op since iOS 12; cross-process App Group writes don't propagate immediately. WidgetCenter.reloadAllTimelines is the right path.
- **TEST PLAN HAS ZERO COVERAGE FOR THE THINGS THAT WILL BREAK** (medium) — no JSONL parser tests, no API fixture tests, no threshold-crossing edge tests, no widget timeline tests. Convergent with Codex.
- **API KEY LEAK RISK VIA `print` + ERROR BODY ECHO** (medium) — `UsageAPIService.swift:78` includes response body's first 200 chars in the thrown error. Use `Logger(... privacy: .private)`.

##### Eng Dual Voices — Consensus Table

```
═══════════════════════════════════════════════════════════════════════════
  Dimension                                  Claude   Codex   Consensus
  ────────────────────────────────────────── ───────  ──────  ───────────
  1. Architecture sound?                     NO       NO      CONFIRMED
  2. Test coverage sufficient?               NO       NO      CONFIRMED — stale
  3. Performance / 30s budget OK?            NO       NO      CONFIRMED
  4. Security threats covered?               NO       NO      CONFIRMED
  5. Error paths handled?                    NO       NO      CONFIRMED
  6. Deployment risk manageable?             NO       NO      CONFIRMED — sandbox unsolved
═══════════════════════════════════════════════════════════════════════════
6/6 confirmed problems. Two reviewers, fully independent, full agreement.
```

#### Section 1 — Architecture (ASCII Dependency Graph)

```
                    iOS App Process                                     Widget Extension Process
                    ───────────────                                     ────────────────────────

  iCodexBarApp ──► ContentView (TabView)                              ICodexBarWidget (WidgetBundle)
                    │                                                            │
                    ├─► DashboardView ──► DashboardViewModel ─┐                  ├─► ICodexBarHomeWidget
                    │                                          │                  │     ├─ SmallWidgetView
                    └─► SettingsView ──► APIKeyEntryView      │                  │     ├─ MediumWidgetView
                          │                                    │                  │     └─ LargeWidgetView
                          └─► AlertRowView                    │                  └─► ICodexBarLockScreenWidget
                                                              │                        └─ LockScreenCircularView
                                                              ▼                              ⚠ LockScreenInlineView declared, never rendered
                              ┌─────────────────────────────────┐
                              │       UsageStore.shared          │ ⚠ @Observable singleton, mutated from BG
                              │       ─────────────────          │
                              │  • snapshots: [Provider:Snapshot]│
                              │  • errors / lastFetchedAt        │
                              └────┬────────────────────────────┘
                                   │ fetchAll() — withTaskGroup ⚠ races
                                   ▼
                       ┌───────────────────────────┐
                       │     UsageAPIService        │
                       │     ─────────────          │
                       │  • OpenAIUsageAPI       ⚠ wrong endpoint
                       │  • AnthropicUsageAPI    ⚠ wrong header + auth + model
                       │  • OpenRouterUsageAPI   ⚠ broken timeout race
                       └───────────────────────────┘
                                   │
                                   ▼
                       ┌───────────────────────────┐
                       │     KeychainService        │ ⚠ accessGroup nil; widget can't read
                       │     (actor)                │ ⚠ save() calls nonexistent delete(key:service:)
                       └───────────────────────────┘
                                   │
                                   ▼
                              iOS Keychain
                                                              ▲
                                                              │ ⚠ no path: widget reads only UserDefaults blob
                                                              │
                       ┌───────────────────────────┐         │
                       │     App Group UserDefaults  │ ◄─────┴──► (cross-process write latency real,
                       │     group.com.icodexbar.shared │           .synchronize() is a no-op)
                       └───────────────────────────┘

                       ┌───────────────────────────┐
                       │   BackgroundRefreshService  │ ⚠ double-completion race
                       │   BGAppRefreshTask         │
                       └───────────────────────────┘

                       ┌───────────────────────────┐
                       │   NotificationService       │ ⚠ alert direction wrong for Quota/Balance
                       │   (actor)                  │
                       └───────────────────────────┘

                       MISSING entirely:
                       ────────────────
                       •   macOS target (NSStatusItem, FileWatcher, CloudKitWriter)
                       •   ClaudeCodeLocalSource (~/.claude/projects/*.jsonl reader)
                       •   CodexCLILocalSource (~/.codex/ reader)
                       •   CloudKit container, schema, writer, reader
                       •   UsageMode enum + QuotaPayload/SpendPayload/BalancePayload
                       •   PaceCalculator
                       •   WidgetConfigurationIntent
                       •   Mode auto-detection from key shape
                       •   watchOS target (acceptable for v1.1)
```

#### Section 3 — Test Review (per skill instructions: never skip; build the test diagram)

| New UX flow / data flow / codepath | Test type needed | Exists? | Gap |
|---|---|---|---|
| `~/.claude/projects/*.jsonl` parsing across schema versions | Unit + fixtures | ❌ | Parser doesn't exist; no fixtures committed |
| `~/.codex/` state parsing | Unit + fixtures | ❌ | Parser doesn't exist |
| Mode auto-detection from key shape | Unit | ❌ | Code path doesn't exist |
| OpenAI `/v1/organization/costs` JSON → ProviderUsageSnapshot | Unit + fixture | ❌ | Code calls wrong endpoint |
| Anthropic response → ProviderUsageSnapshot | Unit + fixture | ❌ | Code reads wrong field |
| OpenRouter `/api/v1/credits` + `/key` race | Unit + integration | ❌ | Race is broken |
| Pace-line math (weekly, monthly, edge: zero-elapsed, end-of-period, leap year) | Unit | ❌ | PaceCalculator missing |
| Cost calculator (input + output token pricing per model, cache tokens) | Unit | ❌ | Hardcoded Haiku price |
| Threshold crossing — Quota `<10%` direction | Unit | ❌ | Model + eval missing direction |
| Threshold crossing — Spend `>80%` direction with hysteresis (79→80→81→79) | Unit | ❌ | `lastNotifiedPercent` exists; not unit-tested at edges |
| Threshold crossing — Balance `<$5` | Unit | ❌ | Mode + eval missing |
| Widget timeline policy + stale entry rendering | Snapshot test | ❌ | Timeline always stamps `Date()` |
| Widget — empty state (no providers configured) | Snapshot test | ❌ | Code falls back to `.openAI` placeholder |
| Lock Screen Circular — every mode (Quota / Spend / Balance) | Snapshot test | ❌ | Single Gauge always rendered |
| Lock Screen Inline — every mode | Snapshot test | ❌ | View defined but never rendered (bug) |
| Keychain CRUD — save → overwrite → delete → not-found | Unit | Partial; `KeychainServiceTests.swift` exists | save() compile error means cannot run |
| Background refresh — expiration during fetch | Unit | ❌ | Double-completion race uncovered |
| CloudKit write → CloudKit read with schema v1 | Integration (test container) | ❌ | Container doesn't exist yet |
| App Group cross-process latency (write from app, read from widget) | Integration | ❌ | |
| App Store entitlement / Mac sandbox bookmark refresh | Manual | ❌ | Decision not made |
| Existing `ProviderUsageSnapshotTests.swift` calls non-existent `DailyUsageEntry` init | Unit | **Stale** | Tests don't compile |
| Existing `NotificationServiceTests.swift:17/30/42` calls non-existent signatures | Unit | **Stale** | Tests don't compile |

**Critical test gaps:**
- API parsers have no fixtures and no decoder tests. The first time a provider changes their schema, the app crashes silently.
- The `lastNotifiedPercent` hysteresis logic in `UsageStore.swift:140-175` is non-trivial and untested.
- Existing tests don't compile, so CI is either green-without-running or has been silenced.

**Test plan artifact written to:** `~/.gstack/projects/optomachina-icodexbar/optomachina-autoplan-review-test-plan-20260425.md` — see below for contents (gaps + suggested fixtures).

#### Section 4 — Performance / Concurrency

- `UsageStore` is `@Observable` shared singleton; `withTaskGroup` mutates the `snapshots` dictionary inside `for await` from non-isolated context. Under Swift 5.9 this is a runtime race; under Swift 6 strict concurrency it won't compile.
- BG 30s budget vs three parallel HTTP calls with 20–30s individual timeouts — first slow connection eats the budget.
- `UserDefaults.synchronize()` called multiple times — no-op since iOS 12, generates noise in profiler traces.
- Widget process re-decodes the entire `[Provider: ProviderUsageSnapshot]` blob on every timeline call. Fine for 3 providers; degrades when more land.

#### Section — Failure Modes Registry

| Failure | Impact | Currently handled? | Fix |
|---|---|---|---|
| OpenAI key invalid (401) | Provider card shows error; OK | Partial — error string is generic | Map to specific UX: "Invalid OpenAI key — tap to update" |
| OpenAI org costs requires admin key | All standard `sk-…` keys fail | ❌ | Onboarding: explain admin key requirement; detect & explain on 401 |
| Anthropic rate-limited | Card shows "Rate limited" | OK once auth works | — |
| Anthropic API not authoritative for spend | User sees fake projection | ❌ | Label "Estimate" or remove from MVP |
| OpenRouter `/key` slow → falls back to credits-only | Acceptable | OK | — |
| Mac companion not running (iOS) | Widget shows stale data with no chip | ❌ | Stale chip; "Mac companion offline" empty state |
| CloudKit unavailable | iOS falls back to direct API | ❌ | Code path doesn't exist |
| Two Macs writing same iCloud account | Last-write-wins; potential flicker | ❌ | Deterministic write key per `(provider, mode)` |
| Background task expired mid-fetch | Race calls `setTaskCompleted` twice | ❌ | Single completion guard |
| Keychain locked (Face ID required, biometric pending) | Read fails silently | ❌ | Surface reason, prompt unlock |
| `~/.claude` access denied (sandbox) | Mac companion silently shows nothing | ❌ | Bookmark grant flow |
| JSONL parse failure on schema bump | Provider falls to error | ❌ | Defensive parse + fixture-driven tests |

#### Decisions Made (Phase 3)

| # | Decision | Class | Principle |
|---|---|---|---|
| E1 | Fix Keychain `delete` signature mismatch | mechanical | P5 (explicit) |
| E2 | Replace OpenAI endpoint with `/v1/organization/costs`; require admin key in onboarding | mechanical | P5 (explicit) |
| E3 | Fix Anthropic auth (`x-api-key`), version header value, model name, and parse usage from JSON body | mechanical | P5 (explicit) |
| E4 | Fix BG double-completion race with single-completion guard | mechanical | P5 (explicit) |
| E5 | Add Keychain access group + entitlement; widget can read keys | mechanical | P1 (completeness) |
| E6 | Convert `UsageStore` to actor or `@MainActor` to fix concurrency | mechanical | P5 (explicit) |
| E7 | Introduce `UsageMode` enum + sum-type payload | TASTE — surfaced at gate | P1 (completeness) — significant refactor of existing code; user previously said keep premise |
| E8 | Drop or label Anthropic "Spend" mode as Estimate | TASTE — surfaced at gate | P5 (explicit) |
| E9 | Decide notarized DMG (Mac) + App Store (iOS); cancel "single bundle, universal binary" | TASTE — surfaced at gate | P5 (explicit) |
| E10 | Add macOS target to `project.yml` (or rewrite plan to drop macOS Phase 1) | **USER CHALLENGE** — both models flagged this contradiction; we previously asked user; user kept premise. Logging again as confirmed eng risk | P5 (explicit) |
| E11 | Remove `armv7` from Info.plist | mechanical | P5 (explicit) |
| E12 | Fix or remove stale tests (`ProviderUsageSnapshotTests.swift:24`, `NotificationServiceTests.swift:17/30/42`) | mechanical | P1 (completeness) |
| E13 | Add CloudKit `schemaVersion` field; document migration plan before any production schema deploy | mechanical | P1 (completeness) |
| E14 | Move `enum CodingKeys` inside `ProviderUsageSnapshot` struct (currently file-scope, doesn't apply) | mechanical | P5 (explicit) |
| E15 | Remove `.synchronize()` calls; trust `WidgetCenter.reloadAllTimelines()` | mechanical | P3 (pragmatic) |
| E16 | Use `Logger(privacy: .private)` for any value derived from API responses; strip `print` from release builds | mechanical | P3 (pragmatic) |
| E17 | Hard-cap each API request at 8s with `URLSessionConfiguration.timeoutIntervalForRequest` to fit BG 30s budget | mechanical | P5 (explicit) |
| E18 | Make `AlertThreshold` mode-aware: `enum AlertCondition { case quotaRemainingBelow; case spendUsedAbove; case balanceUsdBelow }` | mechanical | P1 (completeness) |
| E19 | Replace `snapshots.keys.first` with sorted-deterministic until `WidgetConfigurationIntent` ships | mechanical | P5 (explicit) |
| E20 | Add stale-snapshot indicator to widget entry (`lastSnapshotAge`) | mechanical | P1 (completeness) |
| E21 | Wire LockScreenInlineView via family-aware entry view | mechanical | P5 (explicit) |
| E22 | Add fixture-driven decoder tests for each API + JSONL parser before any new feature | mechanical | P1 (completeness) |
| E23 | Defer "Auth shape → mode" refactor unless E7 is approved | mechanical | P3 (pragmatic) |


---

### Phase 3.5 — DX Review

#### Step 0 — DX Scope Assessment

- **Product type:** consumer-facing iOS app marketed to developers. The primary user is a developer using OpenAI/Anthropic/OpenRouter API keys, or running Claude Code/Codex CLI on Mac.
- **Initial DX completeness:** 2/10. iOS code exists, basic settings + key entry + dashboard. No onboarding. Error messages are technical strings, not actionable. No Mac companion pairing. No README.
- **TTHW (current):** ~6–8 minutes optimistic for OpenRouter, ~15–25 minutes for OpenAI (key-type confusion). For a Tier-B Claude Code user: undefined — there is no path to that data on iOS.
- **TTHW (target per industry norm):** under 5 minutes from install → first widget showing real data.

#### Step 0.5 — Dual Voices

##### CODEX SAYS (DX — developer experience challenge)

12 findings. Top:
- **NO GUIDED TIME-TO-HELLO-WORLD** (critical) — bare TabView shell + generic empty state; auto-dismiss after key save without walking user to widget.
- **OPENAI KEY SETUP IS MISLEADING** (critical) — `sk-` validation accepts project keys but `/v1/organization/costs` requires admin (`sk-admin-…`); user gets blamed for wrong-key-type error.
- **NO MAC COMPANION PAIRING MOMENT** (critical) — Tier B user (30% of MVP, higher LTV) has no path to Claude Code/Codex CLI data on iOS; iOS app only knows three API providers.
- **UNCONFIGURED PROVIDERS LOOK BROKEN** (high) — Dashboard renders cards for every Provider.allCases with warning triangles, looks like app failure.
- **ANTHROPIC "SPEND" IS A SELF-GENERATED ESTIMATE** (high) — convergent.
- **ERRORS SAY "SOMETHING FAILED," NOT WHAT TO DO NEXT** (high) — convergent.
- **SAVED KEY IS REHYDRATED BACK INTO ENTRY FIELD** (high) — convergent (security).
- **SETTINGS IA IS MISSING CORE CONTROLS THE PRODUCT PROMISES** (high) — convergent.
- **WIDGET CONFIGURATION + OFFLINE STATES ARE MISLEADING** (high) — `StaticConfiguration` says "Add widget to configure" but there's no config intent; LockScreenInline never rendered.
- **DISTRIBUTION STORY IS CONTRADICTORY FOR THE MAC-USING DEV** (high) — convergent.
- **APP ASKS FOR NOTIFICATIONS BEFORE EARNING THE RIGHT** (medium) — `iCodexBarApp.init` requests notification auth at startup before any provider is connected.
- **UPGRADE/MIGRATION UX DOES NOT EXIST YET** (medium) — convergent.

##### CLAUDE DX SUBAGENT (DX — independent review)

13 findings. Top:
- **OPENAI KEY VALIDATION ACCEPTS KEYS THAT WILL ALWAYS FAIL** (critical) — convergent. Adds: deep-link from hint should go to `/settings/organization/admin-keys`, not `/api-keys`.
- **`loadExistingKey()` REHYDRATES THE RAW SECRET INTO A SecureField** (critical) — convergent. Adds: "show fingerprint last-4" pattern is the right fix.
- **NO ONBOARDING — FIRST LAUNCH IS A TabView** (high) — convergent. TTHW count: 4–7 min optimistic / 15+ min for users who don't already have admin key.
- **ERROR MESSAGES TELL USER WHAT FAILED, NOT WHAT TO DO** (high) — convergent. Adds: don't save invalid keys (line 182 currently saves and then says "could not fetch usage").
- **ANTHROPIC IMPLEMENTATION BROKEN IN TWO WAYS USER WILL SEE** (high) — convergent.
- **NO iOS-SIDE MAC COMPANION PAIRING FLOW** (high) — convergent.
- **SETTINGS MISSING EVERY P0 FROM PRD** (high) — convergent. Adds: `label` field accepts input but is never persisted.
- **PRIVACY FRAMING INVISIBLE AT MOMENTS THAT MATTER** (medium) — APIKeyEntryView says nothing about Keychain storage at the exact moment user pastes a credential.
- **EMPTY / PARTIAL / ERROR STATES UNDESIGNED** (medium) — convergent.
- **NO README IN REPO ROOT** (medium) — `AGENTS.md:38` claims README starts with `# iCodexBar`; doesn't exist. New contributors land on PRD.md/plan.md/AGENTS.md/CLAUDE.md/BUILD.md and have no human-facing entry doc.
- **CLOUDKIT SCHEMA MIGRATION STORY UNWRITTEN** (medium) — convergent.
- **POWER-USER FEATURES MODEL SUPPORTS BUT UI DOESN'T EXPOSE** (medium) — labels (dead UI), key rotation, bulk paste, provider reorder.
- **SUCCESS STATE OF "SAVE & TEST" IS TOO CLEVER** (medium) — auto-dismiss after 1.5s yanks user away from the magic moment ("Connected — $4.21 used, 2.1M tokens").

##### DX Dual Voices — Consensus Table

```
═══════════════════════════════════════════════════════════════════════════
  Dimension                                  Claude   Codex   Consensus
  ────────────────────────────────────────── ───────  ──────  ───────────
  1. Getting started < 5 min?                NO       NO      CONFIRMED
  2. API/CLI naming guessable?               PARTIAL  PARTIAL CONFIRMED — provider docs OK,
                                                              admin-key surprise breaks it
  3. Error messages actionable?              NO       NO      CONFIRMED
  4. Docs findable & complete?               NO       NO      CONFIRMED — no README
  5. Upgrade path safe?                      NO       NO      CONFIRMED — no schema version
  6. Dev environment friction-free?          NO       NO      CONFIRMED
═══════════════════════════════════════════════════════════════════════════
6/6 confirmed problems.
```

#### Developer Journey Map (9-stage table)

| Stage | Current state | Friction | Target |
|---|---|---|---|
| 1. Discovery | App Store search "AI usage" returns 50 apps; iCodexBar has no audience yet | No HN/blog/distribution plan in plan §7 | Distribution wedge identified (CEO Phase finding); pre-built audience |
| 2. Install | One App Store tap | None | Same |
| 3. First launch | TabView with two tabs; Dashboard empty state with one line | No welcome, no privacy framing, no provider list | 3-screen onboarding: what+privacy, pick providers, add widget |
| 4. Add API key | Settings → tap provider → form with prefix-only validation | Wrong-key-type silent failure for OpenAI; no admin-key explanation | Provider-specific guidance; pre-flight key-shape detection |
| 5. Test connection | Save & Test button; spin; success message; auto-dismiss in 1.5s | Magic moment yanked away before user reads "Connected — $4.21 used" | Show snapshot prominently; user taps Done |
| 6. Add widget | App auto-dismisses; no in-app widget add prompt | User must figure out long-press home → widget gallery → search | Deep link to widget gallery + visual instructions |
| 7. Configure widget | StaticConfiguration; no provider picker; deterministic provider via sort fix | Same widget on every device; no per-instance picker | AppIntentConfiguration with provider intent |
| 8. Receive first alert | Notification permission requested at app launch (before user understands value) | Permission denied → no alerts; app didn't earn trust yet | Defer permission until user enables alerts on a real provider |
| 9. Pair Mac companion | **No path** | iOS app has no awareness of Mac companion; Tier B user (30% of audience) has no way to access Claude Code data they came for | Settings → Mac Companion → Get Mac app + iCloud check + status |

#### Developer Empathy Narrative (first-person)

> "I'm a senior eng at a YC company. I use Claude Code daily and pay $200/mo for OpenAI API. I see iCodexBar on Show HN. I install it, expecting to glance at quota on my Lock Screen.
>
> First launch: I see a Dashboard with three provider cards (OpenAI / Anthropic / OpenRouter), all empty with warning triangles. Looks broken. I tap Settings → OpenAI. Form says 'Find your API key at platform.openai.com/api-keys.' OK, I open Safari, paste my project key, return, tap Save & Test. Spinner. Then 'Invalid API key.' I check the key — it's valid, I just used it 30 seconds ago in my CLI. I delete iCodexBar.
>
> If I had been Tier B: I would have searched Settings for 'Claude Code' or 'pair Mac.' Found nothing. Concluded the iOS app doesn't actually do the thing the App Store description promised. Refund."

This is the dominant first-time experience today. The fix is not one feature; it's a sequence: admin-key validation, error message rewrite, onboarding flow, Mac pairing entry point, and saved-key UX.

#### TTHW Assessment

| User type | Current TTHW | Failure rate | Target TTHW |
|---|---|---|---|
| Tier A — OpenRouter (simplest) | ~6–8 min | ~10% | <3 min |
| Tier A — OpenAI (admin key required) | ~15–25 min | ~70% | <5 min |
| Tier A — Anthropic | Currently broken (wrong auth header) | 100% | <5 min |
| Tier B — Mac Claude Code | No path | 100% | <8 min (includes Mac install) |

#### DX Scorecard (8 dimensions)

| Dimension | Score | Notes |
|---|---|---|
| Getting started (TTHW) | 2/10 | Admin-key surprise, no onboarding, broken Anthropic |
| API/CLI naming + ergonomics | 5/10 | Provider docs OK, prefix validation OK conceptually but accepts wrong key types |
| Error messages | 2/10 | "Invalid API key," "API error 401," raw OSStatus surfaced |
| Documentation | 2/10 | No README; great agent docs, no human entry doc |
| Upgrade path safety | 1/10 | No schema version; CloudKit migration not designed |
| Power-user features | 3/10 | Labels accepted but dropped; no rotation; no bulk paste |
| Privacy framing | 4/10 | Mentioned in About; missing at key-entry moment |
| Mac companion pairing | 0/10 | No iOS-side awareness of Mac at all |
| **Average** | **2.4/10** | |

#### DX Implementation Checklist (post-review)

- [ ] Replace OpenAI prefix validation with admin-key requirement + provider-specific error mapping
- [ ] Fix Anthropic auth/version/model contract bugs
- [ ] Stop rehydrating saved key into SecureField; show fingerprint + Replace/Remove
- [ ] Add 3-screen onboarding (privacy framing, providers, add widget)
- [ ] Rewrite every user-facing error string with problem + cause + fix
- [ ] Add "Mac Companion" Settings row + status states (not installed / iCloud signed-out / connected / offline)
- [ ] Add Settings sections for Display (used/remaining toggle), Refresh (cadence picker), Widgets (config intent)
- [ ] Defer notification auth request until user enables an alert
- [ ] Filter Dashboard cards to configured providers + add "Add provider" CTA
- [ ] Persist `label` from APIKeyEntryView; render in Settings rows
- [ ] Add CloudKit `schemaVersion`; surface "Update iCodexBar" when reading newer schema
- [ ] Add a real `README.md` at repo root
- [ ] Make the success state of Save & Test linger (no auto-dismiss; show "Connected — $X used" prominently)

#### Decisions Made (Phase 3.5)

| # | Decision | Class | Principle |
|---|---|---|---|
| DX1 | OpenAI requires admin key — bake into validator + UI hint | mechanical | P5 (explicit) |
| DX2 | Saved-key UX → fingerprint + Replace/Remove (don't rehydrate secret) | mechanical | P1 (completeness) |
| DX3 | Add 3-screen onboarding | mechanical | P1 (completeness) |
| DX4 | Rewrite error messages with problem + cause + fix | mechanical | P5 (explicit) |
| DX5 | Defer notification permission until alert enabled | mechanical | P3 (pragmatic) |
| DX6 | Add Mac Companion settings entry + status | mechanical | P1 (completeness) |
| DX7 | Add Refresh Cadence + Display Settings sections | mechanical | P1 (completeness) — already in plan, missing in code |
| DX8 | Filter Dashboard to configured providers | mechanical | P5 (explicit) |
| DX9 | Persist + render API key labels | mechanical | P3 (pragmatic) |
| DX10 | Add `schemaVersion` field to CloudKit records + version-mismatch banner | mechanical | P1 (completeness) |
| DX11 | Add README.md to repo root | mechanical | P1 (completeness) |
| DX12 | Don't auto-dismiss Save & Test success — let user read snapshot | mechanical | P5 (explicit) |
| DX13 | Privacy footer on key-entry screen ("Stored in your iPhone's Keychain — never sent to our servers") | mechanical | P1 (completeness) |


---

### Cross-Phase Themes

These concerns appeared in 2+ phases' dual voices independently — the highest-confidence signal in this review.

| Theme | Phases | Severity |
|---|---|---|
| **Three-mode (Quota/Spend/Balance) is asserted in PRD but absent in code** — no `UsageMode` enum, `UsageCardView` always renders Cost+Tokens, breaks for Balance and Quota | CEO, Design, Eng, DX | Critical |
| **Mac-first build order vs iOS-first claim is contradictory** — `project.yml` has zero macOS targets; Phase 1 of plan is 0% scaffolded | CEO, Eng, DX | Critical |
| **Pace line (claimed differentiator) is unbuilt** — no tick, no math, no `PaceCalculator` | CEO, Design, Eng | Critical |
| **No Mac companion pairing on iOS** — Tier B (30% of MVP audience) has no path to Claude Code data; iOS code only knows three API providers | CEO, Design, Eng, DX | Critical |
| **Anthropic Spend mode is fake projection** — no public billing API; current code makes a billable ping, scrapes a header that doesn't exist, accumulates in UserDefaults | CEO, Eng, DX | High |
| **Alert thresholds wrong direction for Quota / Balance** — single 50–100% slider; Quota needs <10% remaining, Balance needs <$5 | Design, Eng, DX | High |
| **Settings missing P0 features from plan** — Refresh cadence picker + "Show as used/remaining" toggle absent | Design, Eng, DX | High |
| **No-telemetry locks team out of validating success metrics in PRD §9** | CEO | Critical (single-phase but loaded) |
| **Distribution friction: Mac App Store sandbox vs `~/.claude` reading is unsolved** | CEO, Eng, DX | High |
| **Lock Screen Inline view defined but never rendered** — declared in supportedFamilies, body always returns Circular | Design, Eng | High |
| **Widget `loadEntry()` stamps `Date()` instead of `lastFetchedKey`** — staleness invisible | Design, Eng, DX | High |
| **API integrations all broken differently** — wrong OpenAI endpoint, wrong Anthropic auth+version+model, OpenRouter timeout race | Eng, DX | Critical |
| **Existing tests don't compile** — `ProviderUsageSnapshotTests.swift:24`, `NotificationServiceTests.swift:17/30/42` reference non-existent signatures | Eng | Critical (single-phase but trivially verifiable) |
| **No README in repo root** — `AGENTS.md:38` claims README exists; doesn't | DX | Medium |

The convergence is unusually high. Two reviewer voices per phase × 4 phases = 8 independent passes, and they agree on the same handful of architectural and DX issues. That is high-confidence signal worth acting on as a unit, not item-by-item.


---

## /autoplan — APPROVED

**Status:** APPROVED 2026-04-25 by user via /autoplan final gate.

**Premise resolution (D1):** User accepted current premises as-stated. The 4 disputed premises stand on founder authority. Implementation should proceed knowing reviewers flagged: iOS-first wedge, pace line moat, 7-week timeline, no-telemetry compatible with §9 metrics.

**Taste decisions resolution (D2 — Approve as-is):** All 7 taste decisions accepted with reviewer recommendations:
- T1: Introduce `UsageMode` enum + sum-type payloads now (refactor before more feature code lands on Spend-shaped model)
- T2: Drop Anthropic Spend mode from MVP (no public billing API; current code is fake)
- T3: Notarized DMG for Mac, App Store for iOS (sandbox + `~/.claude` is unsolved)
- T4: Drop Enterprise from roadmap (architectural mismatch; misleads users)
- T5: Add opt-in privacy-safe telemetry (RevenueCat + event ping)
- T6: Sandbox vs file-access decision = notarized DMG (T3 implies T6)
- T7: Defer "Auth shape → mode" refactor (T1 covers it)

**Mechanical decisions (37):** All accepted. See Decision Audit Trail above.

**Critical fixes blocking T&E slice:**
1. `KeychainService.swift:95` compile error — call `delete(for:in:)` not `delete(key:service:)`
2. Anthropic auth — `x-api-key` not `Authorization: Bearer`; fix version header value; fix model name; parse usage from JSON body
3. OpenAI endpoint — replace `/v1/billing/usage` with `/v1/organization/costs`; require admin key
4. Stale tests — fix `ProviderUsageSnapshotTests.swift:24` and `NotificationServiceTests.swift:17/30/42` so suite compiles
5. `Info.plist` — remove `armv7` from `UIRequiredDeviceCapabilities`
6. BG refresh — single-completion guard for `setTaskCompleted`
7. Keychain access group — add to entitlements + `accessGroup` in `KeychainService.swift:36`

**Test plan artifact:** `~/.gstack/projects/optomachina-icodexbar/optomachina-autoplan-review-test-plan-20260425.md`

**Deferred to TODOS.md:**
- Distribution wedge / launch plan (CEO)
- Measurement plan: how do we know if pace line is working
- Provider-source abstraction refactor (after 4th provider arrives)
