import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct iCodexBarEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

// MARK: - Configuration Intent

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("Configure iCodexBar Widget")
}

// MARK: - Timeline Provider

struct iCodexBarProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> iCodexBarEntry {
        iCodexBarEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> iCodexBarEntry {
        iCodexBarEntry(date: Date(), configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<iCodexBarEntry> {
        let entry = iCodexBarEntry(date: Date(), configuration: configuration)
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: iCodexBarEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                Text("iCodexBar")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            Spacer()
            Text("Code Snippet")
                .font(.headline)
                .fontWeight(.bold)
            Text("10 items")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: iCodexBarEntry

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "book.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("iCodexBar")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                Spacer()
                Text("Recent Snippets")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("5 code snippets saved")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                StatView(icon: "swift", value: "3", label: "Swift")
                StatView(icon: "doc.text", value: "2", label: "Other")
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct StatView: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.blue)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.bold)
                Text(label)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let entry: iCodexBarEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                Text("iCodexBar")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("Today")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            Text("Recent Snippets")
                .font(.headline)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 6) {
                SnippetRowView(language: "Swift", title: "Quick Sort Algorithm", lines: "12 lines")
                SnippetRowView(language: "Python", title: "Fibonacci Sequence", lines: "8 lines")
                SnippetRowView(language: "JavaScript", title: "Event Handler", lines: "5 lines")
                SnippetRowView(language: "Swift", title: "Core Data Fetch", lines: "15 lines")
            }

            Spacer()

            HStack {
                Text("View All")
                    .font(.caption)
                    .foregroundColor(.blue)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct SnippetRowView: View {
    let language: String
    let title: String
    let lines: String

    var body: some View {
        HStack {
            Circle()
                .fill(languageColor(for: language))
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption)
                .lineLimit(1)
            Spacer()
            Text(lines)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    func languageColor(for language: String) -> Color {
        switch language {
        case "Swift": return .orange
        case "Python": return .green
        case "JavaScript": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Widget Bundle

@main
struct iCodexBarWidgetBundle: WidgetBundle {
    var body: some Widget {
        iCodexBarWidget()
    }
}

// MARK: - Widget

struct iCodexBarWidget: Widget {
    let kind: String = "iCodexBarWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: iCodexBarProvider()) { entry in
            iCodexBarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("iCodexBar")
        .description("View your code snippets at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct iCodexBarWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: iCodexBarProvider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    iCodexBarWidget()
} timeline: {
    iCodexBarEntry(date: .now, configuration: ConfigurationAppIntent())
}

#Preview(as: .systemMedium) {
    iCodexBarWidget()
} timeline: {
    iCodexBarEntry(date: .now, configuration: ConfigurationAppIntent())
}

#Preview(as: .systemLarge) {
    iCodexBarWidget()
} timeline: {
    iCodexBarEntry(date: .now, configuration: ConfigurationAppIntent())
}
