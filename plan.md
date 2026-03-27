# iCodexBar — Development Plan

## Overview

iCodexBar is a privacy-first native iOS app providing real-time AI token usage tracking via widgets. No backend. No data collection. API keys stay on-device in the iOS Keychain.

---

## 1. MVP Scope

### What We're Building First

**Core MVP (Free Tier)** — Must ship before anything else:

| Feature | Priority | Notes |
|---------|----------|-------|
| API key entry UI (OpenAI, Anthropic, OpenRouter) | P0 | Keychain-backed secure storage |
| Manual usage refresh | P0 | Pull-to-refresh on dashboard |
| Dashboard view (current period usage) | P0 | Token counts + cost estimates |
| Home Screen widget (small, medium, large) | P0 | Lock Screen widget optional for MVP |
| Lock Screen widget (circular + inline) | P1 | Can ship in v1.1 if time permits |
| Alert threshold configuration | P0 | Per-provider, notify at X% |
| Background refresh (widget timeline) | P0 | WidgetKit timeline provider, 5-min refresh |
| App icon + basic UI polish | P0 | Dark mode, provider accent colors |

**Out of MVP (Post-Launch)**:
- Premium tier (multi-account, charts)
- Enterprise tier
- In-app purchase flow
- History charts
- Pace predictions
- CSV export
- Team dashboards

### Platform & Deployment

- **Minimum iOS**: 17.0 (for modern WidgetKit, App Intents, SwiftData)
- **Devices**: iPhone only (iPad deferred)
- **App Store**: Individual developer account initially

---

## 2. Milestones

### Milestone 1 — Shell Project (Week 1)
- [ ] XcodeGen project.yml configured
- [ ] SwiftUI App entry point
- [ ] TabView shell (Dashboard, History placeholder, Settings placeholder)
- [ ] Provider enum: OpenAI, Anthropic, OpenRouter
- [ ] Basic Keychain wrapper (get/set/delete API keys)
- [ ] Configured Widget extension target
- [ ] GitHub repo initialized with conventional commits

### Milestone 2 — API Layer (Week 2)
- [ ] OpenAI billing usage endpoint (`/v1/billing/usage`)
- [ ] OpenRouter usage endpoint (`/v1/usage`)
- [ ] Anthropic usage: parse from `/v1/messages` response headers (cost estimation)
- [ ] Usage response models (token count, cost, period dates)
- [ ] Mock data layer for offline UI development
- [ ] Unit tests for API response parsing

### Milestone 3 — Dashboard & Key Management (Week 3)
- [ ] API key entry form (masked input, validation)
- [ ] Keychain CRUD for all 3 providers
- [ ] Dashboard view with current period data
- [ ] Provider status indicator (API up/down)
- [ ] Pull-to-refresh
- [ ] Error handling (invalid key, network error, rate limit)
- [ ] App Intents for "Refresh iCodexBar" Siri action

### Milestone 4 — Widgets (Week 4)
- [ ] Small Home Screen widget (single provider gauge)
- [ ] Medium Home Screen widget (two providers)
- [ ] Large Home Screen widget (all three + reset date)
- [ ] Lock Screen circular widget
- [ ] Lock Screen inline widget
- [ ] Widget configuration intent (select default provider)
- [ ] Shared App Group for data between app and widget
- [ ] Background timeline refresh

### Milestone 5 — Alerts (Week 5)
- [ ] Alert threshold model (provider, threshold %, enabled)
- [ ] Alert configuration UI in Settings
- [ ] Local notifications via `UNUserNotificationCenter`
- [ ] Alert state persistence in UserDefaults
- [ ] Widget reflects alert state (color change at threshold)

### Milestone 6 — Polish & Launch Prep (Week 6)
- [ ] App icon (all sizes)
- [ ] LaunchScreen storyboard
- [ ] App Store listing copy + screenshots
- [ ] Privacy policy page (linked from Settings)
- [ ] Fastlane submission (optional, manual if not ready)
- [ ] TestFlight beta build
- [ ] Bug bash and fix

### Milestone 7 — Premium Tier (Post-Launch v1.1)
- [ ] StoreKit 2 subscription setup
- [ ] Multi-account model (up to 5)
- [ ] Account label management
- [ ] History view with Swift Charts
- [ ] Pace prediction algorithm
- [ ] CSV export via share sheet

### Milestone 8 — Enterprise Tier (Post-Launch v2.0)
- [ ] Team model (owner, members)
- [ ] Aggregated team dashboard
- [ ] Per-user breakdown views
- [ ] Admin controls UI
- [ ] Stripe/Chargebee integration for enterprise billing
- [ ] SSO (SAML/OIDC) — Phase 2

---

## 3. Dev Roadmap

```
Q1 2026
├── Mar 27  – Project start, PRD + plan complete
├── Week 1  – Shell project, XcodeGen, tab structure, Keychain wrapper
├── Week 2  – API layer for all 3 providers, response models, mocks
├── Week 3  – Dashboard UI, API key management, App Intents
├── Week 4  – Widgets (Home Screen + Lock Screen)
├── Week 5  – Alerts, local notifications, threshold persistence
└── Week 6  – Polish, TestFlight, App Store submission

Q2 2026
├── v1.1 (Apr) – Premium: multi-account, charts, pace predictions
└── v1.2 (May) – Bug fixes, widget improvements, performance

Q3 2026
└── v2.0 (Jul) – Enterprise: team dashboards, admin controls, SSO
```

---

## 4. Dependencies

### External APIs (Documentation Links)

| Provider | Endpoint | Auth | Docs |
|----------|----------|------|------|
| OpenAI | `POST /v1/billing/usage` | Bearer token | https://platform.openai.com/docs/api-reference/billing |
| OpenRouter | `GET /v1/usage` | Bearer token | https://openrouter.ai/docs/api-reference/usage |
| Anthropic | Response headers from `/v1/messages` | Bearer token | https://docs.anthropic.com/en/api/messages |

### iOS Frameworks (All Apple, No Third-Party)

| Framework | Purpose |
|-----------|---------|
| SwiftUI | UI layer |
| WidgetKit | Home Screen + Lock Screen widgets |
| AppIntents | Siri shortcuts, widget configuration |
| Charts | History visualizations (iOS 16+) |
| StoreKit | In-app subscriptions |
| Keychain Services | Secure API key storage |
| UserNotifications | Local alerts |
| BackgroundTasks | Background refresh scheduling |
| ActivityKit | Live Activities (Phase 2) |

### Tools

| Tool | Purpose |
|------|---------|
| XcodeGen | Project generation from `project.yml` |
| SwiftLint | Code style enforcement |
| Fastlane | App Store deployment (optional) |

### No Third-Party Dependencies

To maintain privacy guarantees:
- **No Firebase/Analytics/Crashlytics**
- **No Mixpanel/Amplitude**
- **No networking libraries** (use URLSession)
- **No dependency managers beyond CocoaPods/SPM for internal modules**

If a lightweight utility is genuinely needed, evaluate carefully and prefer stdlib alternatives.

---

## 5. Technical Architecture

### Module Structure

```
iCodexBar/
├── App/
│   └── iCodexBarApp.swift
├── Core/
│   ├── Models/
│   │   ├── Provider.swift              # OpenAI, Anthropic, OpenRouter enum
│   │   ├── UsageData.swift             # Token usage, cost, period dates
│   │   ├── APIKey.swift                # Stored key metadata (no secret value)
│   │   └── AlertThreshold.swift        # Per-provider alert config
│   ├── Services/
│   │   ├── KeychainService.swift      # Secure storage CRUD
│   │   ├── UsageAPIService.swift      # Protocol + implementations
│   │   │   ├── OpenAIUsageAPI.swift
│   │   │   ├── OpenRouterUsageAPI.swift
│   │   │   └── AnthropicUsageAPI.swift
│   │   ├── NotificationService.swift  # Local notifications
│   │   └── SubscriptionService.swift   # StoreKit 2
│   └── Utilities/
│       ├── DateHelpers.swift
│       └── CurrencyFormatter.swift
├── Features/
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   ├── DashboardViewModel.swift
│   │   ├── ProviderCardView.swift
│   │   └── UsageGaugeView.swift
│   ├── History/
│   │   ├── HistoryView.swift          # Premium
│   │   └── ChartView.swift            # Premium
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   ├── APIKeyEntryView.swift
│   │   ├── AlertConfigView.swift
│   │   └── SubscriptionView.swift
│   └── AddAccount/
│       └── AddAccountView.swift
├── Widget/
│   ├── iCodexBarWidget.swift          # Widget bundle
│   ├── ProviderTimelineProvider.swift  # Timeline entries
│   ├── SmallWidgetView.swift
│   ├── MediumWidgetView.swift
│   ├── LargeWidgetView.swift
│   └── LockScreenWidgetView.swift
├── Intents/
│   ├── RefreshUsageIntent.swift       # App Intent for Siri
│   └── ConfigureWidgetIntent.swift    # Widget configuration
└── Resources/
    ├── Assets.xcassets
    ├── LaunchScreen.storyboard
    └── Info.plist
```

### Data Flow

```
Widget Timeline Provider
         ↓
  Shared App Group (UserDefaults suite)
         ↑
  UsageDataController (saves latest fetch)
         ↑
  Background App Refresh (BGTaskScheduler)
         ↑
  Manual Pull-to-Refresh / App Intent
         ↑
  UsageAPIService (OpenAI | OpenRouter | Anthropic)
         ↑
  KeychainService (API keys)
```

### App Group

- **App Group ID**: `group.com.icodexbar.shared`
- Used for: widget reads app data, app writes widget data, shared UserDefaults suite

---

## 6. Testing Strategy

### Unit Tests
- API response parsing (JSON fixtures for each provider)
- Cost calculation logic
- Keychain CRUD (mocked)
- Alert threshold evaluation
- Date/period calculation helpers

### Widget Tests
- Timeline entry generation
- Widget view rendering with mock data

### Integration Tests
- End-to-end usage fetch with mock API keys (test accounts)
- Full alert flow: threshold breach → notification

### Manual Testing Checklist
- [ ] Add OpenAI key → fetch usage → display correct
- [ ] Add OpenRouter key → fetch usage → display correct
- [ ] Add Anthropic key → estimate from response headers → display correct
- [ ] Remove key → dashboard shows "No key configured"
- [ ] Network error → graceful degradation with retry option
- [ ] Invalid key → clear error message, no crash
- [ ] Add Home Screen widget → renders correctly
- [ ] Add Lock Screen widget → renders correctly
- [ ] Set alert at 50% → simulate 60% usage → notification fires
- [ ] Background refresh → widget updates without app launch
- [ ] Dark mode throughout
- [ ] All three provider accent colors visible

---

## 7. Launch Checklist

### Pre-Submission
- [ ] All P0 features implemented and tested
- [ ] No hardcoded secrets or placeholder API keys
- [ ] App Privacy labels set in App Store Connect (no data collection)
- [ ] Privacy policy URL hosted (GitHub Pages or simple static page)
- [ ] App icon in all required sizes (1024x1024 base)
- [ ] LaunchScreen storyboard configured
- [ ] Bundle identifier: `com.icodexbar.app`
- [ ] Widget extension bundle ID: `com.icodexbar.app.widget`
- [ ] App Group configured in both targets
- [ ] Background Modes: `fetch`, `processing`
- [ ] Keychain sharing capability (if sharing between app + widget)

### App Store Connect
- [ ] Create app listing
- [ ] Write app name, subtitle, description
- [ ] Add keywords
- [ ] Set category: Developer Tools / Utilities
- [ ] Set age rating: 4+
- [ ] Upload screenshots (iPhone 6.7", 6.5", 5.5")
- [ ] App Privacy completed (no data collection)
- [ ] Pricing: Free with Premium IAP at $0.99/month
- [ ] Submit for review

### Post-Launch
- [ ] Monitor App Store reviews
- [ ] Monitor Crashlytics-free crash reports (iOS crash logs)
- [ ] Collect feedback, file Issues in GitHub
- [ ] Plan v1.1 based on user signal

---

## 8. Open Questions

| Question | Status | Resolution |
|----------|--------|------------|
| Anthropic billing API available? | Open | May need to estimate from message token counts in responses rather than a dedicated billing endpoint. Confirm before Milestone 2. |
| OpenRouter rate limits? | Open | Need to check docs; may need exponential backoff. |
| App Group Keychain sharing? | Open | Sharing Keychain access between app and widget extension requires `kSecAttrAccessGroup`. Test in iOS 17. |
| Enterprise billing via Stripe? | Deferred | Phase 2 decision; may use Chargebee for easier B2B. |
| Live Activities approval? | Deferred | ActivityKit requires Apple approval for Live Activities; low priority for MVP. |

---

*Plan version: 1.0*
*Created: 2026-03-27*
