import AppKit
import iCodexBarCore

/// Owns the NSStatusItem and wires refresh + menu together.
@MainActor
final class StatusItemController {
    private let statusItem: NSStatusItem
    private let refresher: MacUsageRefresher

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        refresher = MacUsageRefresher()

        configureButton()
        buildMenu(snapshots: [], errorMessage: nil)

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

    private func configureButton() {
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "gauge.with.dots.needle.bottom.50percent",
                accessibilityDescription: "iCodexBar"
            )
            button.image?.isTemplate = true
            button.action = #selector(handleButtonClick)
            button.target = self
        }
    }

    @objc private func handleButtonClick() {
        // Refresh on click, then show menu
        Task {
            await refresher.refresh(interaction: .userInitiated)
            self.update()
        }
        statusItem.button?.performClick(nil)
    }

    private func update() {
        buildMenu(
            snapshots: refresher.snapshots,
            errorMessage: refresher.lastErrorMessage
        )
    }

    private func buildMenu(snapshots: [ProviderUsageSnapshot], errorMessage: String?) {
        let menu = MenuBarMenu.build(snapshots: snapshots, errorMessage: errorMessage)
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
        statusItem.menu = menu
    }

    @objc private func handleRefresh() {
        Task {
            await refresher.refresh(interaction: .userInitiated)
            self.update()
        }
    }
}
