import AppKit
import iCodexBarCore

enum MenuBarMenu {
    /// Builds an NSMenu from live snapshots. Caller appends Refresh + Quit items.
    static func build(snapshots: [ProviderUsageSnapshot], errorMessage: String?) -> NSMenu {
        let menu = NSMenu()

        if let errorMessage {
            menu.addItem(makeDisabledItem(errorMessage))
            return menu
        }

        if snapshots.isEmpty {
            menu.addItem(makeDisabledItem("No usage data"))
            return menu
        }

        for snapshot in snapshots {
            menu.addItem(makeProviderItem(snapshot))
        }

        return menu
    }

    // MARK: - Private builders

    private static func makeProviderItem(_ snapshot: ProviderUsageSnapshot) -> NSMenuItem {
        let item = NSMenuItem()
        item.attributedTitle = attributedTitle(for: snapshot)
        item.isEnabled = false
        return item
    }

    private static func makeDisabledItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private static func attributedTitle(for snapshot: ProviderUsageSnapshot) -> NSAttributedString {
        let providerName = snapshot.provider.displayName

        let primary = snapshot.primary
        let secondary = snapshot.secondary

        var lines: [String] = []

        // Line 1: Provider name
        lines.append(providerName)

        // Line 2: 5h usage
        if let primary {
            let usedPct = Int(primary.usedPercent.rounded())
            let resetStr = primary.resetDescription ?? ""
            lines.append("  5h: \(usedPct)% used\(resetStr.isEmpty ? "" : " -- resets \(resetStr)")")
        }

        // Line 3: Weekly usage
        if let secondary {
            let usedPct = Int(secondary.usedPercent.rounded())
            let resetStr = secondary.resetDescription ?? ""
            lines.append("  Weekly: \(usedPct)% used\(resetStr.isEmpty ? "" : " -- resets \(resetStr)")")
        }

        let combined = lines.joined(separator: "\n")
        let attributed = NSMutableAttributedString(string: combined)

        let fullRange = NSRange(combined.startIndex..., in: combined)
        attributed.addAttribute(.font, value: NSFont.menuFont(ofSize: 0), range: fullRange)

        // Bold the provider name line
        if let providerRange = combined.range(of: providerName) {
            let nsRange = NSRange(providerRange, in: combined)
            attributed.addAttribute(
                .font,
                value: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize),
                range: nsRange
            )
        }

        return attributed
    }
}
