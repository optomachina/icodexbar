# AGENTS.md

Last updated: March 27, 2026

## Purpose

This file is the canonical operating system for human contributors and coding agents working in the iCodexBar repository.
Its job is to define:
- how work is chosen
- how work is shaped
- how work is implemented
- how work is verified
- how work is handed off
- how parallel agents avoid colliding

Durable repo instructions belong here, not in repeated prompts.
If a rule should still be true next week, it belongs in this file.

---

## Canonical instruction hierarchy

When instructions overlap, use this order:

1. `PRD.md`
2. `plan.md`
3. `AGENTS.md` (this file)
4. `README.md`
5. local tool instruction files (`.github/copilot-instructions.md`, etc.)

If documents conflict, prefer the higher-priority document and flag the drift.

---

## Workspace identity check

Minimum fingerprints of the correct repo root:
- `README.md` starts with `# iCodexBar`
- root contains `PRD.md`, `plan.md`, `AGENTS.md`
- root contains `iCodexBar/` (app source), `iCodexBarWidget/` (widget extension)
- root contains `project.yml` (XcodeGen)

If those fingerprints do not match, stop and fix workspace selection before changing code.

---

## Core operating principles

- Preserve product intent from PRD and plan
- Do not silently change requirements
- Prefer the smallest safe change
- One problem per branch whenever practical
- Do not make drive-by fixes unrelated to the task
- Do not claim completion based only on a successful build
- When behavior changes, update the docs that describe it
- If recurring guidance is needed, update this file

---

## Work modes

### 1. Planning mode

Use for: new features, backlog decomposition, ambiguous implementation work, architecture-impacting changes.

Required outputs: problem statement, constraints, acceptance criteria, affected areas, risks, smallest viable implementation slice.

### 2. Analysis mode

Before changing code: read relevant source-of-truth docs, inspect the local area to be changed, identify touched boundaries, identify likely tests, identify privacy and security implications.

Do not start implementing until the likely blast radius is understood.

### 3. Implementation mode

Implement in a focused way: touch the minimum number of files needed, preserve existing UX/layout contracts unless the task explicitly changes them, avoid opportunistic refactors, avoid unrelated renames and formatting churn, do not add dependencies without a task-linked reason.

### 4. Review mode

Review order:
1. security, privacy, Keychain exposure, API key handling
2. broken contracts, API response parsing drift
3. validation gaps on external input (API responses, user input)
4. widget timeline correctness and refresh cadence
5. test coverage gaps on changed critical paths
6. undocumented behavior changes

Prefer minimal, localized fixes over broad rewrites.

### 5. Handoff mode

Every nontrivial task ends with: what changed, why it changed, files changed, tests run, docs updated or why not, known risks, follow-ups.

---

## Required output contract for nontrivial tasks

Before implementation starts, restate: acceptance criteria, intended scope, excluded scope.

At completion, provide: implementation summary, verification evidence, docs impact, known risks or follow-ups. No vague "done" claims.

---

## Parallel agent and subagent rules

Use delegation only for bounded work.

Allowed:
- isolated file creation
- isolated test file creation
- isolated code review on a bounded diff
- isolated investigation of one subsystem
- parallel work on different modules (Widget vs App vs API layer)

Not allowed:
- multiple agents editing the same file concurrently
- multiple agents independently integrating the same feature
- duplicate broad analysis passes

Required subagent return format: goal, files inspected or changed, result, open questions, commit or patch reference.

Integration rule: one integrator owns the final patch, reconcile once.

---

## Branch and worktree policy

Use an isolated branch for:
- behavior changes
- new module scaffolding
- changes touching multiple files
- risky refactors
- concurrent efforts

Direct local edits are acceptable only for: trivial one-file fixes, typo or copy changes, clearly safe non-behavioral edits.

Recommended naming:
- `feature/...`
- `fix/...`
- `refactor/...`
- `spike/...`
- `docs/...`

---

## Blast-radius control

Before editing, set the intended blast radius. Change only what is needed to satisfy acceptance criteria. Do not mix cleanup into implementation unless the cleanup is required. Do not edit generated artifacts directly unless the task explicitly requires it.

If the diff grows beyond original scope, stop and either split the work or restate the new scope explicitly.

---

## Package manager and dependency policy

- **XcodeGen** is the only authorized project generator — edit `project.yml`, then run `xcodegen generate`
- **Swift Package Manager** (SPM) for any third-party dependencies — only if truly necessary, prefer stdlib
- **No CocoaPods** — keep the dependency surface minimal to protect privacy guarantees
- Do not add dependencies casually; every dependency is a privacy and maintenance risk

---

## Verification policy

Run the narrowest sufficient verification early, then the broader required verification before handoff.

Canonical local commands:
```
xcodegen generate          # regenerate project after project.yml changes
swift build                # compile check (no Xcode required)
swift test                 # run unit tests
```

### Verification lanes

#### Lane 0 — docs / copy / non-behavioral changes
Run only what is needed to confirm no unintended breakage.

#### Lane 1 — isolated local behavior change
Run targeted checks first, then minimum broader checks for confidence.

#### Lane 2 — shared behavior or cross-file change
Run targeted checks plus broader affected-area checks, then full build.

#### Lane 3 — high-risk change
Required for: Keychain access, API key handling, widget timeline logic, notification delivery, StoreKit integration, privacy-sensitive paths.

Run targeted checks early and full build + tests before handoff.

Do not skip verification silently.

---

## Testing policy

- Bug fixes should be test-first when practical
- Behavior changes should include test evidence or an explicit rationale for omission
- Keychain CRUD, API response parsing, alert threshold evaluation, and widget timeline are high-risk areas
- Use `@MainActor` and `XCTest` for SwiftUI-adjacent tests
- Widget rendering tests: use previews with mock data

---

## Documentation update policy

When changing any of the following, update the relevant docs in the same change or explicitly state why no doc update is needed:
- product behavior
- workflow expectations
- architecture boundaries
- module structure

Common doc targets: `PRD.md`, `plan.md`, `README.md`, `AGENTS.md`.

---

## Review guidelines

Always flag first:
- P0/P1 security, privacy, Keychain exposure, API key leakage
- broken API contracts or response parsing errors
- missing validation on external inputs (API responses, user-provided keys)
- widget timeline returning stale or incorrect data
- StoreKit receipt validation gaps
- undocumented behavior changes

Also flag:
- missing documentation on public API (Swift module boundaries)
- dependency additions or permission expansions
- logging of secrets, tokens, or PII

---

## Pull request standard

PRs must include:
- problem
- scope
- verification evidence
- tests added or updated
- docs updated or reason none were needed

Before publishing: ensure the branch is coherent, PR exists, title is concrete, body reflects actual work.

---

## Task completion standard

A task is not complete until:
1. the requested change is implemented
2. relevant verification has been run
3. the diff is coherent
4. docs are updated if needed
5. important risks or follow-ups are noted

---

## Stop-and-flag conditions

Stop and surface the issue instead of improvising when:
- source-of-truth docs conflict materially
- the task implies a product decision not documented anywhere
- a requested shortcut bypasses privacy guarantees
- two agents would need to touch the same file at the same time
- the task's blast radius is expanding beyond original intent without explicit approval
- API key or secret would be logged or exposed

---

## Efficiency rules

- run one primary analysis pass
- delegate only bounded tasks
- require compact structured subagent outputs
- default to low-volume git inspection first (`--name-only`, `--oneline`, `--stat`)
- pull full patch or log output only after a concrete target is identified
- keep command output scoped to the decision at hand
- use one watcher for CI or checks instead of repeated polling

Speed without control is waste. Control without throughput is also waste.
The target is narrow, verified motion.

---

## iOS-specific conventions

### File structure
```
iCodexBar/
├── App/
├── Core/
│   ├── Models/
│   ├── Services/
│   └── Utilities/
├── Features/
│   ├── Dashboard/
│   ├── History/
│   ├── Settings/
│   └── AddAccount/
├── Widget/
├── Intents/
└── Resources/

iCodexBarWidget/
├── iCodexBarWidget.swift
├── ProviderTimelineProvider.swift
└── Views/
```

### Swift style
- SwiftUI for all UI; no UIKit unless unavoidable
- `@Observable` (iOS 17+) over `ObservableObject`
- `async/await` for all network calls
- Use `Result` type for API responses with typed error cases
- Guard all Keychain operations with `guard ... else { throw }`
- Never log API keys or token values — use `***` redaction in any debug output

### Widget conventions
- Timeline entries must be deterministic for a given `Date`
- Use `WidgetCenter.shared.reloadAllTimelines()` after key changes
- Share data via App Group `UserDefaults(suiteName: "group.com.icodexbar.shared")`
- Widget refresh in background uses `BGAppRefreshTask` registered in `Info.plist`

### API key handling
- Keys stored via `KeychainServices` with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- Never include key values in logs, errors, or crash reports
- Validate key format (non-empty, reasonable length) before storing
- Test connectivity on key save; show clear error if API rejects the key
