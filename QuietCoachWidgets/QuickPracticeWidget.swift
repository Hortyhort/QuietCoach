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

    // MARK: - Home Screen Small (iOS 26 Liquid Glass)

    private var smallView: some View {
        ZStack {
            // Liquid Glass gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.12),
                    Color.purple.opacity(0.08),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 24, height: 24)
                            .blur(radius: 3)

                        Image(systemName: "waveform")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    Text("Practice")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                Spacer()

                if let firstScenario = entry.scenarios.first {
                    Button(intent: QuickPracticeIntent(scenarioId: firstScenario.id)) {
                        VStack(spacing: 8) {
                            // Glowing icon
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.2))
                                    .frame(width: 48, height: 48)
                                    .blur(radius: 6)

                                Image(systemName: firstScenario.icon)
                                    .font(.title)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.orange, .yellow.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }

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
        }
        .containerBackground(for: .widget) {
            Color.black.opacity(0.3)
                .background(.ultraThinMaterial)
        }
    }

    // MARK: - Home Screen Medium (iOS 26 Liquid Glass)

    private var mediumView: some View {
        ZStack {
            // Liquid Glass gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.06),
                    Color.orange.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 24, height: 24)
                            .blur(radius: 3)

                        Image(systemName: "waveform")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    Text("Quick Practice")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                HStack(spacing: 10) {
                    ForEach(entry.scenarios.prefix(4)) { scenario in
                        Button(intent: QuickPracticeIntent(scenarioId: scenario.id)) {
                            VStack(spacing: 6) {
                                // Glass button with glow
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                        .frame(height: 44)

                                    // Glow effect
                                    Circle()
                                        .fill(Color.orange.opacity(0.15))
                                        .frame(width: 30, height: 30)
                                        .blur(radius: 4)

                                    Image(systemName: scenario.icon)
                                        .font(.title3)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.orange, .yellow.opacity(0.8)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                }

                                Text(scenario.title)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .containerBackground(for: .widget) {
            Color.black.opacity(0.3)
                .background(.ultraThinMaterial)
        }
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
