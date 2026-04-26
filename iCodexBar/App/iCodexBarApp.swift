import SwiftUI

@main
struct ICodexBarApp: App {
    init() {
        requestNotificationPermission()
        registerBackgroundTask()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func requestNotificationPermission() {
        Task {
            try? await NotificationService.shared.requestAuthorization()
        }
    }

    private func registerBackgroundTask() {
        BackgroundRefreshService.shared.registerBackgroundTask()
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.with.dots.needle.bottom.50percent")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(.accentColor)
    }
}
