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
