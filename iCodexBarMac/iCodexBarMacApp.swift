import AppKit
import SwiftUI

@main
struct iCodexBarMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent appearing in the Dock (belt + suspenders with LSUIElement)
        NSApp.setActivationPolicy(.accessory)
        statusItemController = StatusItemController()
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusItemController = nil
    }
}
