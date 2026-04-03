import SwiftUI

struct APIKeyEntryView: View {
    let provider: Provider

    @Environment(\.dismiss) private var dismiss

    @State private var apiKey: String = ""
    @State private var label: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @State private var testResult: String?
    @State private var testSuccess: Bool = false
    @State private var showKey: Bool = false

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        if showKey {
                            TextField(keyPlaceholder, text: $apiKey)
                                .textContentType(.password)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField(keyPlaceholder, text: $apiKey)
                                .textContentType(.password)
                        }

                        Button {
                            showKey.toggle()
                        } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Label (optional)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("e.g., Work account", text: $label)
                        .autocorrectionDisabled()
                }
            } header: {
                Text(provider.displayName)
            } footer: {
                Text(providerKeyHint)
            }

            if let error = errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                }
            }

            if testSuccess, let result = testResult {
                Section {
                    Label(result, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                }
            }

            Section {
                Button {
                    Task { await saveAndTest() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                                .padding(.trailing, 6)
                        }
                        Text("Save & Test")
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
                .disabled(apiKey.isEmpty || isSaving)

                if isConfigured {
                    Button(role: .destructive) {
                        Task { await deleteKey() }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Remove API Key")
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle(provider.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadExistingKey()
        }
    }

    private var keyPlaceholder: String {
        provider == .anthropic ? "Claude Code OAuth token" : "sk-..."
    }

    private var providerKeyHint: String {
        switch provider {
        case .openAI:
            return "Find your API key at platform.openai.com/api-keys"
        case .anthropic:
            return "Enter your Claude Code OAuth token. Get it from claude.ai after signing in with Claude Code."
        case .openRouter:
            return "Find your API key at openrouter.ai/settings/keys"
        }
    }

    private var isConfigured: Bool {
        do {
            let key = try KeychainService.shared.get(key: provider.rawValue)
            return !key.isEmpty
        } catch {
            return false
        }
    }

    private func loadExistingKey() async {
        do {
            let key = try KeychainService.shared.get(key: provider.rawValue)
            apiKey = key
        } catch {
            // Key not found — that's fine for a new entry
        }
    }

    private func saveAndTest() async {
        isSaving = true
        errorMessage = nil
        testResult = nil
        testSuccess = false

        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedKey.isEmpty else {
            errorMessage = "API key cannot be empty"
            isSaving = false
            return
        }

        guard isValidKeyFormat(trimmedKey) else {
            errorMessage = "Invalid API key format"
            isSaving = false
            return
        }

        // Save to Keychain
        do {
            try await KeychainService.shared.save(key: provider.rawValue, value: trimmedKey)
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            isSaving = false
            return
        }

        // Test the key
        let testSnapshot: ProviderUsageSnapshot?
        do {
            switch provider {
            case .openAI:
                testSnapshot = try await OpenAIUsageAPI.shared.fetchUsage(apiKey: trimmedKey)
            case .openRouter:
                testSnapshot = try await OpenRouterUsageAPI.shared.fetchUsage(apiKey: trimmedKey)
            case .anthropic:
                testSnapshot = try await AnthropicUsageAPI.shared.fetchUsage(apiKey: trimmedKey)
            }
        } catch {
            testResult = "Saved but could not fetch usage: \(error.localizedDescription)"
            testSuccess = false
            isSaving = false
            return
        }

        if let snapshot = testSnapshot {
            testResult = "Connected — \(snapshot.formattedCost) used, \(snapshot.formattedTokens) tokens"
            testSuccess = true

            // Also refresh the store
            await UsageStore.shared.fetchAll()

            // Dismiss after short delay
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            dismiss()
        }

        isSaving = false
    }

    private func deleteKey() async {
        do {
            try await KeychainService.shared.delete(key: provider.rawValue)
            dismiss()
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
        }
    }

    private func isValidKeyFormat(_ key: String) -> Bool {
        switch provider {
        case .openAI:
            return key.hasPrefix("sk-") && key.count > 10
        case .anthropic:
            return key.count >= 10  // OAuth tokens have no public prefix spec
        case .openRouter:
            return key.hasPrefix("sk-or-") && key.count > 10
        }
    }
}

#Preview {
    NavigationStack {
        APIKeyEntryView(provider: .openAI)
    }
}
