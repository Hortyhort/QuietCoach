// QuickPracticeWidget.swift
// QuietCoachWidgets
//
// Interactive widget for one-tap scenario launch.
// Get practicing with a single tap from your home screen.

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Quick Practice Intent

struct QuickPracticeIntent: AppIntent {
    static let title: LocalizedStringResource = "Quick Practice"
    static let description = IntentDescription("Start practicing a scenario")

    @Parameter(title: "Scenario ID")
    var scenarioId: String

    init() {
        self.scenarioId = "set-boundary"
    }

    init(scenarioId: String) {
        self.scenarioId = scenarioId
    }

    func perform() async throws -> some IntentResult & OpensIntent {
        // Store the scenario ID for the app to pick up
        let defaults = UserDefaults(suiteName: "group.com.quietcoach") ?? .standard
        defaults.set(scenarioId, forKey: "pendingScenarioId")
        return .result()
    }
}

// MARK: - Timeline Entry

struct QuickPracticeEntry: TimelineEntry {
    let date: Date
    let scenarios: [ScenarioPreview]

    struct ScenarioPreview: Identifiable {
        let id: String
        let title: String
        let icon: String
    }

    static var placeholder: QuickPracticeEntry {
        QuickPracticeEntry(
            date: Date(),
            scenarios: [
                ScenarioPreview(id: "set-boundary", title: "Set a Boundary", icon: "hand.raised.fill"),
                ScenarioPreview(id: "ask-raise", title: "Ask for a Raise", icon: "chart.line.uptrend.xyaxis"),
                ScenarioPreview(id: "give-feedback", title: "Give Feedback", icon: "text.bubble.fill"),
                ScenarioPreview(id: "say-no", title: "Say No", icon: "xmark.circle.fill")
            ]
        )
    }
}

// MARK: - Timeline Provider

struct QuickPracticeProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickPracticeEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickPracticeEntry) -> Void) {
        completion(.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickPracticeEntry>) -> Void) {
        // Static content - refresh weekly
        let nextUpdate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let timeline = Timeline(entries: [QuickPracticeEntry.placeholder], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Views

struct QuickPracticeWidgetEntryView: View {
    var entry: QuickPracticeEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            mediumView
        }
    }

    // MARK: - Home Screen Small

    private var smallView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "waveform")
                    .foregroundStyle(.orange)
                Text("Practice")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Spacer()

            if let firstScenario = entry.scenarios.first {
                Button(intent: QuickPracticeIntent(scenarioId: firstScenario.id)) {
                    VStack(spacing: 8) {
                        Image(systemName: firstScenario.icon)
                            .font(.title)
                            .foregroundStyle(.orange)

                        Text(firstScenario.title)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding()
        .containerBackground(.black, for: .widget)
    }

    // MARK: - Home Screen Medium

    private var mediumView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "waveform")
                    .foregroundStyle(.orange)
                Text("Quick Practice")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(spacing: 12) {
                ForEach(entry.scenarios.prefix(4)) { scenario in
                    Button(intent: QuickPracticeIntent(scenarioId: scenario.id)) {
                        VStack(spacing: 6) {
                            Image(systemName: scenario.icon)
                                .font(.title2)
                                .foregroundStyle(.orange)
                                .frame(width: 32, height: 32)

                            Text(scenario.title)
                                .font(.caption2)
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .containerBackground(.black, for: .widget)
    }
}

// MARK: - Widget Configuration

struct QuickPracticeWidget: Widget {
    let kind: String = "QuickPracticeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickPracticeProvider()) { entry in
            QuickPracticeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quick Practice")
        .description("Start a scenario with one tap")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    QuickPracticeWidget()
} timeline: {
    QuickPracticeEntry.placeholder
}
