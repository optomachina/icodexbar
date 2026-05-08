import AppKit
import iCodexBarCore

/// Owns provider-specific NSStatusItems and wires refresh + menus together.
@MainActor
final class StatusItemController {
    private var statusItems: [Provider: NSStatusItem] = [:]
    private let refresher: MacUsageRefresher
    private let driver = DisplayLinkDriver()
    private var hasCompletedInitialRefresh = false

    private static let fallbackProvider: Provider = .codexCLI
    private static let statusItemLength: CGFloat = 24
    private static let staleThreshold: TimeInterval = 10 * 60

    init() {
        refresher = MacUsageRefresher()

        let fallbackItem = ensureItem(for: Self.fallbackProvider)
        fallbackItem.menu = makeFallbackMenu()
        startLoadingAnimation()

        // Initial fetch — user just launched the app, prompt is expected.
        Task {
            await refresher.refresh(interaction: .userInitiated)
            self.update()
        }

        // Observe changes from the refresher
        Task {
            for await _ in refresher.changeStream {
                self.update()
            }
        }

        // Background timer: refresh every 5 minutes — gated, won't surprise-prompt.
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000)
                await refresher.refresh(interaction: .background)
                self.update()
            }
        }
    }

    // MARK: - Private

    private func startLoadingAnimation() {
        driver.start(fps: 12)

        Task { @MainActor in
            for await phase in driver.stream {
                guard !hasCompletedInitialRefresh else { break }
                renderLoading(phase: phase)
            }
        }
    }

    private func renderLoading(phase: CGFloat) {
        for (provider, item) in statusItems {
            item.button?.image = StatusIconRenderer.render(
                mode: .loading(phase: phase),
                accent: NSColor(provider.accentColor),
                isStale: false
            )
        }
    }

    private func update() {
        if !hasCompletedInitialRefresh {
            hasCompletedInitialRefresh = true
            driver.stop()
        }

        let now = Date()
        let snapshotsByProvider = Dictionary(
            uniqueKeysWithValues: refresher.snapshots.map { ($0.provider, $0) }
        )

        for provider in Provider.allCases {
            guard let snapshot = snapshotsByProvider[provider] else { continue }

            let item = ensureItem(for: provider)
            let isStale = now.timeIntervalSince(snapshot.updatedAt) > Self.staleThreshold
            item.button?.image = StatusIconRenderer.render(
                mode: .live(
                    primary: snapshot.primary?.usedPercent,
                    secondary: snapshot.secondary?.usedPercent
                ),
                accent: NSColor(provider.accentColor),
                isStale: isStale
            )
            item.menu = makeProviderMenu(snapshot: snapshot)
        }

        for provider in Array(statusItems.keys) where snapshotsByProvider[provider] == nil {
            if provider == Self.fallbackProvider {
                let item = ensureItem(for: provider)
                item.button?.image = StatusIconRenderer.render(
                    mode: .empty,
                    accent: NSColor(provider.accentColor),
                    isStale: false
                )
                item.menu = makeFallbackMenu()
            } else if let item = statusItems[provider] {
                NSStatusBar.system.removeStatusItem(item)
                statusItems.removeValue(forKey: provider)
            }
        }
    }

    @discardableResult
    private func ensureItem(for provider: Provider) -> NSStatusItem {
        if let existing = statusItems[provider] {
            return existing
        }

        let item = NSStatusBar.system.statusItem(withLength: Self.statusItemLength)
        item.autosaveName = "icodexbar.\(provider.rawValue)"
        item.button?.imagePosition = .imageOnly
        item.button?.image = StatusIconRenderer.render(
            mode: .empty,
            accent: NSColor(provider.accentColor),
            isStale: false
        )
        item.button?.toolTip = provider.displayName
        statusItems[provider] = item
        return item
    }

    private func makeProviderMenu(snapshot: ProviderUsageSnapshot) -> NSMenu {
        let menu = MenuBarMenu.build(snapshots: [snapshot], errorMessage: nil)
        appendStandardItems(to: menu)
        return menu
    }

    private func makeFallbackMenu() -> NSMenu {
        let menu = MenuBarMenu.build(
            snapshots: [],
            errorMessage: refresher.lastErrorMessage
        )
        appendStandardItems(to: menu)
        return menu
    }

    private func appendStandardItems(to menu: NSMenu) {
        menu.addItem(.separator())
        let refresh = NSMenuItem(
            title: "Refresh",
            action: #selector(handleRefresh),
            keyEquivalent: "r"
        )
        refresh.target = self
        menu.addItem(refresh)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit iCodexBar",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
    }

    @objc private func handleRefresh() {
        Task {
            await refresher.refresh(interaction: .userInitiated)
            self.update()
        }
    }
}
