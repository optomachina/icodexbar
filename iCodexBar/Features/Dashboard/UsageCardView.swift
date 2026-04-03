import SwiftUI

/// A card showing usage for a single provider
struct UsageCardView: View {
    let provider: Provider
    let snapshot: ProviderUsageSnapshot?
    let error: String?
    let isLoading: Bool

    @AppStorage("isDemoMode") private var isDemoMode = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: provider.iconName)
                    .font(.title3)
                    .foregroundStyle(provider.accentColor)
                    .frame(width: 28)

                Text(provider.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if isDemoMode {
                    Text("DEMO")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(.orange.opacity(0.5), lineWidth: 1))
                }

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                } else if error != nil {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else if let snapshot {
                // Usage bar
                usageBar(percent: snapshot.primary?.usedPercent ?? 0)

                // Stats row
                HStack(spacing: 16) {
                    statItem(
                        label: "Cost",
                        value: snapshot.formattedCost,
                        accent: provider.accentColor
                    )
                    statItem(
                        label: "Tokens",
                        value: snapshot.formattedTokens,
                        accent: provider.accentColor
                    )
                    Spacer()
                    if let resetDesc = snapshot.primary?.resetDescription {
                        Text(resetDesc)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Balance for credit-based providers
                if let balance = snapshot.balance {
                    HStack {
                        Text("Balance:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(CurrencyFormatter.format(balance))
                            .font(.caption2)
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
            } else {
                // No data yet
                VStack(spacing: 4) {
                    Text("No data")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Add an API key in Settings")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(provider.accentColor.opacity(0.3), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func usageBar(percent: Double) -> some View {
        let clampedPercent = max(0, min(100, percent))
        let isOver = percent > 100

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(Int(clampedPercent))% used")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                if isOver {
                    Text("Over limit")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(isOver ? Color.red : provider.accentColor)
                        .frame(width: geo.size.width * (clampedPercent / 100))
                }
            }
            .frame(height: 8)
        }
    }

    @ViewBuilder
    private func statItem(label: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(accent)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        UsageCardView(
            provider: .openAI,
            snapshot: .placeholder,
            error: nil,
            isLoading: false
        )
        UsageCardView(
            provider: .anthropic,
            snapshot: nil,
            error: "Invalid API key",
            isLoading: false
        )
        UsageCardView(
            provider: .openRouter,
            snapshot: nil,
            error: nil,
            isLoading: true
        )
    }
    .padding()
    .background(Color(.systemGray6))
}
