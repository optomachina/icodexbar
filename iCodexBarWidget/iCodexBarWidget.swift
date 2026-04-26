import SwiftUI
import WidgetKit

// MARK: - Widget Entry

struct ICodexBarEntry: TimelineEntry {
    let date: Date
    let snapshots: [Provider: ProviderUsageSnapshot]
    let provider: Provider

    static let placeholder = ICodexBarEntry(
        date: Date(),
        snapshots: [:],
        provider: .openAI
    )
}

// MARK: - Timeline Provider

struct ICodexBarProvider: TimelineProvider {
    typealias Entry = ICodexBarEntry

    private let appGroupID = "group.com.icodexbar.shared"
    private let snapshotsKey = "provider_usage_snapshots"
    private let lastFetchedKey = "last_fetched_at"

    func placeholder(in _: Context) -> Entry {
        .placeholder
    }

    func getSnapshot(in _: Context, completion: @escaping (Entry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> Entry {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            return .placeholder
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        var snapshots: [Provider: ProviderUsageSnapshot] = [:]
        if let data = defaults.data(forKey: snapshotsKey),
           let decoded = try? decoder.decode([Provider: ProviderUsageSnapshot].self, from: data) {
            snapshots = decoded
        }

        // Default to first configured provider (sorted for deterministic ordering), or OpenAI
        let provider = snapshots.keys.sorted { $0.rawValue < $1.rawValue }.first ?? .openAI

        return ICodexBarEntry(date: Date(), snapshots: snapshots, provider: provider)
    }
}

// MARK: - Widget Views

struct SmallWidgetView: View {
    let entry: ICodexBarEntry

    var body: some View {
        let snapshot = entry.snapshots[entry.provider]

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: entry.provider.iconName)
                    .font(.caption)
                    .foregroundStyle(entry.provider.accentColor)
                Text(entry.provider.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if let snapshot {
                Text(snapshot.formattedCost)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .minimumScaleFactor(0.5)

                UsageBarView(percent: snapshot.primary?.usedPercent ?? 0, color: entry.provider.accentColor)

                Text(snapshot.formattedTokens)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("No data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumWidgetView: View {
    let entry: ICodexBarEntry

    private var providers: [Provider] {
        let configured = entry.snapshots.keys.sorted { $0.rawValue < $1.rawValue }
        return configured.isEmpty ? [.openAI] : Array(configured.prefix(2))
    }

    var body: some View {
        HStack(spacing: 12) {
            ForEach(providers) { provider in
                let snapshot = entry.snapshots[provider]
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: provider.iconName)
                            .font(.caption2)
                            .foregroundStyle(provider.accentColor)
                        Text(provider.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                        Spacer()
                        Text(entry.date, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    Text(snapshot?.formattedCost ?? "—")
                        .font(.headline)
                        .fontWeight(.semibold)

                    UsageBarView(percent: snapshot?.primary?.usedPercent ?? 0, color: provider.accentColor)

                    Text(snapshot?.formattedTokens ?? "—")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct LargeWidgetView: View {
    let entry: ICodexBarEntry

    private var providers: [Provider] {
        let configured = entry.snapshots.keys.sorted { $0.rawValue < $1.rawValue }
        return configured.isEmpty ? Provider.allCases : configured
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text("iCodexBar")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Provider rows
            ForEach(providers) { provider in
                let snapshot = entry.snapshots[provider]
                HStack {
                    Image(systemName: provider.iconName)
                        .font(.caption)
                        .foregroundStyle(provider.accentColor)
                        .frame(width: 20)

                    Text(provider.displayName)
                        .font(.caption)
                        .frame(width: 70, alignment: .leading)

                    UsageBarView(percent: snapshot?.primary?.usedPercent ?? 0, color: provider.accentColor, height: 8)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(snapshot?.formattedCost ?? "—")
                            .font(.caption2)
                            .fontWeight(.medium)
                        Text(snapshot?.formattedTokens ?? "—")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 70, alignment: .trailing)
                }
            }

            Spacer()
        }
        .padding(14)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Shared Components

private struct UsageBarView: View {
    let percent: Double
    let color: Color
    var height: CGFloat = 6

    var body: some View {
        let clamped = max(0, min(100, percent))
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.2))
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: geo.size.width * (clamped / 100))
            }
        }
        .frame(height: height)
    }
}

// MARK: - Lock Screen Views

struct LockScreenCircularView: View {
    let entry: ICodexBarEntry

    var body: some View {
        let snapshot = entry.snapshots[entry.provider]
        let percent = snapshot?.primary?.usedPercent ?? 0

        Gauge(value: min(100, percent), in: 0 ... 100) {
            Image(systemName: entry.provider.iconName)
                .font(.caption2)
        } currentValueLabel: {
            Text("\(Int(percent))")
                .font(.caption2)
        }
        .gaugeStyle(.accessoryCircular)
        .tint(entry.provider.accentColor)
    }
}

struct LockScreenInlineView: View {
    let entry: ICodexBarEntry

    var body: some View {
        let snapshot = entry.snapshots[entry.provider]
        HStack {
            Image(systemName: entry.provider.iconName)
            Text("\(entry.provider.displayName): \(snapshot?.formattedCost ?? "—")")
        }
    }
}

// MARK: - Widget Bundle

@main
struct ICodexBarWidget: WidgetBundle {
    var body: some Widget {
        ICodexBarHomeWidget()
        if #available(iOSApplicationExtension 17.0, *) {
            ICodexBarLockScreenWidget()
        }
    }
}

struct ICodexBarHomeWidget: Widget {
    let kind: String = "ICodexBarHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ICodexBarProvider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("AI Usage")
        .description("Track your AI provider usage.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@available(iOSApplicationExtension 17.0, *)
struct ICodexBarLockScreenWidget: Widget {
    let kind: String = "ICodexBarLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ICodexBarProvider()) { entry in
            LockScreenCircularView(entry: entry)
        }
        .configurationDisplayName("AI Usage")
        .description("Track your AI usage at a glance.")
        .supportedFamilies([.accessoryCircular, .accessoryInline])
    }
}

struct WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: ICodexBarEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            LargeWidgetView(entry: entry)
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    ICodexBarHomeWidget()
} timeline: {
    ICodexBarEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    ICodexBarHomeWidget()
} timeline: {
    ICodexBarEntry.placeholder
}

#Preview("Large", as: .systemLarge) {
    ICodexBarHomeWidget()
} timeline: {
    ICodexBarEntry.placeholder
}
