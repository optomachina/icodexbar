import SwiftUI

struct SettingsView: View {
    @State private var thresholds: [AlertThreshold] = []
    @State private var configuredProviders: [Provider] = []

    var body: some View {
        NavigationStack {
            List {
                // API Keys Section
                Section("API Keys") {
                    ForEach(Provider.allCases) { provider in
                        NavigationLink {
                            APIKeyEntryView(provider: provider)
                        } label: {
                            HStack {
                                Image(systemName: provider.iconName)
                                    .foregroundStyle(provider.accentColor)
                                    .frame(width: 24)

                                Text(provider.displayName)

                                Spacer()

                                if configuredProviders.contains(provider) {
                                    Text("Connected")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Not connected")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }

                // Alerts Section
                Section("Alert Thresholds") {
                    ForEach($thresholds) { $threshold in
                        AlertRowView(threshold: $threshold) {
                            saveThresholds()
                        }
                    }
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.appVersion)
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com/optomachina/icodexbar/blob/main/PRIVACY.md")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)

                    HStack {
                        Text("Data Collection")
                        Spacer()
                        Text("None — API keys stay on-device")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                loadThresholds()
                Task {
                    await loadConfiguredProviders()
                }
            }
        }
    }

    private func loadThresholds() {
        let defaults = UserDefaults(suiteName: "group.com.icodexbar.shared") ?? .standard
        if let data = defaults.data(forKey: "alert_thresholds"),
           let decoded = try? JSONDecoder().decode([AlertThreshold].self, from: data)
        {
            thresholds = decoded
        } else {
            thresholds = Provider.allCases.map { AlertThreshold(provider: $0) }
        }
    }

    private func loadConfiguredProviders() async {
        var providers: [Provider] = []
        for provider in Provider.allCases {
            do {
                let key = try await KeychainService.shared.get(key: provider.rawValue)
                if !key.isEmpty {
                    providers.append(provider)
                }
            } catch {
                continue
            }
        }
        configuredProviders = providers
    }

    private func saveThresholds() {
        let defaults = UserDefaults(suiteName: "group.com.icodexbar.shared") ?? .standard
        if let encoded = try? JSONEncoder().encode(thresholds) {
            defaults.set(encoded, forKey: "alert_thresholds")
        }
    }
}

// MARK: - Alert Row

struct AlertRowView: View {
    @Binding var threshold: AlertThreshold
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: threshold.provider.iconName)
                    .foregroundStyle(threshold.provider.accentColor)

                Text(threshold.provider.displayName)

                Spacer()

                Toggle("", isOn: $threshold.isEnabled)
                    .labelsHidden()
            }

            if threshold.isEnabled {
                HStack {
                    Text("Alert at")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Slider(
                        value: Binding(
                            get: { Double(threshold.thresholdPercent) },
                            set: { threshold.thresholdPercent = Int($0) }
                        ),
                        in: 50 ... 100,
                        step: 5
                    )

                    Text("\(threshold.thresholdPercent)%")
                        .font(.caption)
                        .fontWidth(.compressed)
                        .frame(width: 36)
                }
            }
        }
        .onChange(of: threshold.isEnabled) { _, _ in onSave() }
        .onChange(of: threshold.thresholdPercent) { _, _ in onSave() }
    }
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView()
}
