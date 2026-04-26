# iCodexBar

Privacy-first native iOS + macOS app for real-time AI token usage tracking across OpenAI, Anthropic, and OpenRouter. Widget-first UX. No backend. API keys stay on-device in Keychain.

## What it does

Glanceable AI usage on the surfaces you actually look at — Lock Screen, Home Screen, Apple Watch, and the Mac menu bar. Auto-detects whether each provider is **quota-based** (Claude Code, Codex CLI, ChatGPT subscriptions), **spend-based** (OpenAI / Anthropic API keys), or **balance-based** (OpenRouter) and renders the right shape for each.

The differentiator is the **pace reference line** — a forecast tick that turns "62% remaining" into "slightly behind pace, you'll be fine" or "over pace, slow down." Universal across quota and spend modes.

## Architecture

- **iOS app** (Tier A): Standalone for API-key providers. Reads OpenAI cost API, Anthropic billing, OpenRouter credits. No Mac required.
- **macOS companion** (Tier B): Reads `~/.claude/projects/*.jsonl` and `~/.codex/` local state for Claude Code / Codex CLI quota tracking. Syncs snapshots to CloudKit private DB every 5m.
- **iOS widgets read CloudKit** when present; fall back to direct API polling when the Mac companion is absent or stale.
- **Apple Watch** (v1.1): complications read from iOS shared App Group.

Zero backend. CloudKit uses the user's iCloud. App Store privacy label: **No data collected**.

## Tech stack

- Swift 5.9+ / SwiftUI / WidgetKit / App Intents (iOS 16+)
- Keychain Services (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`)
- CloudKit private database for Mac→iOS sync
- StoreKit 2 for subscriptions
- MVVM + repository pattern, actor-based sources

## Building

Requires Xcode 15+ and the toolchain in [`BUILD.md`](BUILD.md):

```bash
brew install xcodegen swiftlint swiftformat fastlane
xcodegen generate
open iCodexBar.xcodeproj
```

Set your `DEVELOPMENT_TEAM` in `project.yml` or as an env var before building.

## Project layout

```
iCodexBar/           # Main app target (iOS + macOS via shared Core)
├── App/             # Entry point
├── Core/            # Models, Services (API, Keychain), Utilities
├── Features/        # Dashboard, Settings
└── Resources/       # Assets, Info.plist
iCodexBarWidget/     # Widget extension (iOS + macOS)
iCodexBarTests/      # Unit tests
fastlane/            # CI/CD lanes (test, build, beta, release)
```

## Documentation

- [`PRD.md`](PRD.md) — full product requirements, data model, feature matrix
- [`plan.md`](plan.md) — implementation plan
- [`BUILD.md`](BUILD.md) — toolchain, CI/CD, code signing
- [`AGENTS.md`](AGENTS.md) — agent collaboration guide
- [`CLAUDE.md`](CLAUDE.md) — Claude Code routing for this repo

## Status

Pre-MVP. See `plan.md` for current phase and `PRD.md` §4 for the v1 feature cut.
