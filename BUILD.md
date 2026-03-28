# Build & CI/CD Configuration

## Toolchain

| Tool | Version | Purpose |
|------|---------|---------|
| XcodeGen | 2.38.0 | Project generation |
| SwiftLint | 0.57.0 | Linting |
| SwiftFormat | 0.54.0 | Formatting |
| Fastlane | 2.227.0 | CI/CD automation |

## Setup

```bash
# Install tools
brew install xcodegen swiftlint swiftformat fastlane

# Generate Xcode project
xcodegen generate

# Run linting
swiftlint

# Run formatting (check)
swiftformat --lint .

# Run formatting (apply)
swiftformat .
```

## Fastlane

See `fastlane/Fastfile` for available lanes:
- `fastlane test` — Run unit tests
- `fastlane build_debug` — Build debug configuration
- `fastlane build_release` — Build release configuration
- `fastlane beta` — Upload to TestFlight
- `fastlane release` — Submit to App Store

## CI/CD

GitHub Actions workflow runs on every push:
- Lint: SwiftLint + SwiftFormat
- Build: Debug + Release
- Test: Unit tests on iOS 17 simulator

## Project Structure

```
icodexbar/
├── iCodexBar/           # Main app target
│   ├── App/             # App entry point
│   ├── Core/            # Shared logic
│   │   ├── Models/      # Data models
│   │   ├── Services/    # API, Keychain, etc.
│   │   └── Utilities/   # Helpers
│   ├── Features/        # Feature modules
│   │   ├── Dashboard/   # Main dashboard
│   │   └── Settings/    # Settings views
│   └── Resources/       # Assets, Info.plist
├── iCodexBarWidget/     # Widget extension
├── fastlane/            # Fastlane config
├── .github/             # GitHub Actions
└── project.yml          # XcodeGen config
```

## Code Signing

Development team ID must be set in `project.yml`:

```yaml
settings:
  base:
    DEVELOPMENT_TEAM: "YOUR_TEAM_ID"
```

Or via environment variable:
```bash
export DEVELOPMENT_TEAM="YOUR_TEAM_ID"
```

## App Groups

Shared between app and widget:
- `group.com.icodexbar.shared`

Used for:
- UserDefaults persistence
- File container for usage snapshots
