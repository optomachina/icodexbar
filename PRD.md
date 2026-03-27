# iCodexBar — Product Requirements Document

## 1. Problem Statement

Developers and teams using multiple AI providers (OpenAI, Claude, OpenRouter) have no native iOS visibility into real-time token consumption. Billing surprises are common. Usage is scattered across provider dashboards with no unified view, no alerts, and no historical trends. iCodexBar solves this with a widget-first experience that puts usage data exactly where users need it — on their Lock Screen and Home Screen — without requiring them to open an app or visit a web dashboard.

---

## 2. Target Users

### Free Tier
- **Individual developers** using one or two AI accounts across OpenAI, Claude, and OpenRouter
- **Freelancers and contractors** managing personal API spend
- **Students** learning AI development on limited budgets

### Premium ($1/month)
- **Power users** with multiple API accounts (personal, work, client projects)
- **Small teams** (2–5) wanting history charts and spend predictions without full enterprise overhead

### Enterprise ($15/user/month)
- **Engineering teams** at startups and agencies tracking AI spend across projects
- **Technical leads and managers** needing aggregated team dashboards and per-user breakdowns
- **Finance/operations** needing admin controls and exportable spend reports

---

## 3. Core Features

### 3.1 Free Tier — Core

#### Real-Time Token Usage Widget (Home Screen + Lock Screen)
- Displays current billing period usage for each connected provider
- Shows: total tokens used, cost estimate, reset date countdown
- Updates via API polling every 5 minutes when app is active
- Lock Screen widget: compact single-provider view
- Home Screen widget: supports small (single provider), medium (2 providers), large (all 3)

#### Usage Alerts
- Configurable thresholds per provider (e.g., "alert at 80% of monthly budget")
- Notifications triggered at threshold crossings
- One-tap alert dismissal and threshold adjustment

#### API Key Management
- Secure storage via iOS Keychain (Keychain Services API)
- Support for: OpenAI (Billing API), Anthropic/Claude (Console or API), OpenRouter (Dashboard API)
- Add/edit/remove keys without leaving the app
- Keys never leave the device; no data leaves device except API polling

#### Basic Dashboard (In-App)
- Current period summary: tokens, cost, % of any set budget
- Provider health status (API up/down indicator)
- Quick actions: refresh, add account, configure alert

### 3.2 Premium Tier ($1/month) — via In-App Purchase

#### Multi-Account Support
- Connect up to 5 accounts across any combination of providers
- Per-account usage breakdown within the app
- Account labels (e.g., "Work - GPT-4", "Personal - Claude")

#### History & Charts
- 30-day rolling history per account
- Line charts for token usage over time
- Cost trend charts
- Bar charts for provider comparison

#### Pace Predictions
- Projected end-of-month usage based on current burn rate
- Projected cost at month end
- "On track / Over pace / Under pace" status badges

#### Data Export
- CSV export of usage history
- Share via iOS share sheet

### 3.3 Enterprise Tier ($15/user/month)

#### Team Dashboard
- Aggregated token spend across all team members
- Combined cost across all providers
- Team-wide budget alerts

#### Per-User Breakdowns
- Admin can view any team member's usage (with their consent/cooperation — API keys are individually provided)
- User-level spend charts and trends

#### Admin Controls
- Invite/remove team members
- Set team-wide budget caps
- Receive team-level alert notifications
- Audit log of team activity

#### Enterprise SSO (Phase 2)
- SAML/OIDC support for enterprise identity providers

---

## 4. Monetization

### Tiered Pricing

| Tier | Price | Features |
|------|-------|----------|
| **Free** | $0 | 1 account per provider, real-time widget, basic alerts |
| **Premium** | $1/month | Multi-account (5), history charts, pace predictions, CSV export |
| **Enterprise** | $15/user/month | Team dashboards, per-user breakdowns, admin controls, SSO |

### Revenue Model
- **Direct iAP** — StoreKit 2 for Premium monthly subscription
- **Enterprise invoicing** — B2B via Stripe or Chargebee for Enterprise tier
- **No ads, no data monetization** — Privacy-first positioning

### Conversion Flow
1. Free tier covers 90% of basic needs
2. Premium upsell at 3rd provider account or 2nd week of use (triggered by a natural "you've hit 80% of free tier usage" prompt)
3. Enterprise pitch on team formation within the app

---

## 5. Tech Stack

### Frameworks & Languages
- **Swift 5.9+** with **SwiftUI** for all UI
- **WidgetKit** for Home Screen and Lock Screen widgets
- **App Intents** (iOS 16+) for Siri shortcuts and widget configuration
- **Keychain Services API** for secure API key storage
- **StoreKit 2** for in-app subscriptions
- **Charts** (SwiftUI native, iOS 16+) for history visualizations
- **UserDefaults + FileManager** for local data persistence (no external DB)
- **URLSession** for API polling
- **ActivityKit** (Phase 2) for Live Activities if Apple approves

### Architecture
- **MVVM** with ObservableObject ViewModels
- **Repository pattern** for API data access
- **Dependency injection** via environment objects
- **Combine** for reactive data flow

### API Integrations
- **OpenAI** — `api.openai.com/v1/billing/usage` (requires Billing API token)
- **Anthropic** — Console billing API (scrapes or official API when available) + `api.anthropic.com/v1/messages` usage from response headers
- **OpenRouter** — `openrouter.ai/api/v1/usage` (requires API key)

### Security
- All API keys stored in **iOS Keychain** with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- **No analytics SDKs** — zero third-party data collection
- **No backend required** — all logic client-side
- Network calls only to provider APIs; no intermediary server

### Privacy
- No user accounts required for Free/Premium (keys are the identity)
- Enterprise: team data stored encrypted on-device; no external sync
- **App Privacy label**: No data collection declared

---

## 6. UI/UX Direction

### Visual Language
- **Dark-mode first** — natural for developers
- **Minimal chrome** — data density over decoration
- **Accent colors** per provider for instant recognition:
  - OpenAI: `#10A37F` (green)
  - Anthropic: `#CC785C` (orange)
  - OpenRouter: `#E63946` (red)
- Monospace font for numbers; SF Pro for UI text

### Navigation
- **TabView** with 3 tabs: Dashboard, History, Settings
- Settings houses: API Keys, Alerts, Subscription, Enterprise (if active)

### Widget Design
- **Small**: Single provider gauge (tokens used / limit + cost)
- **Medium**: Two providers side-by-side
- **Large**: All three providers + next reset date + pace indicator
- **Lock Screen (Circular)**: Single provider % used
- **Lock Screen (Inline)**: "OpenAI: 2.1M tokens · $4.20"

### Animations
- Subtle number roll-up on data refresh
- Pulse on alert threshold breach
- No gratuitous motion

---

## 7. Non-Goals (Out of Scope)

- Android app (future consideration)
- Web dashboard
- Automatic cost optimization suggestions
- Multi-currency support (initially USD only)
- API key rotation or generation (read-only polling)
- Direct provider billing integration (we show usage, not invoices)

---

## 8. Success Metrics

- Widget addition rate (% of app users who add a widget)
- Alert configuration rate
- Premium conversion rate (target: 3–5%)
- Enterprise team formation rate
- App Store rating: target 4.5+
- Privacy-focused marketing differentiation

---

## 9. Privacy Policy

iCodexBar does not collect, store, or transmit any personal data to external servers except the minimum API calls required to fetch usage information from the providers you have authorized. API keys are stored exclusively in the device Keychain and are never accessible to the developers. No analytics, no crash reporting SDK, no third-party frameworks that phone home. The only network traffic is direct HTTPS calls to OpenAI, Anthropic, and OpenRouter APIs using your provided keys.

---

*Document version: 1.0*
*Last updated: 2026-03-27*
