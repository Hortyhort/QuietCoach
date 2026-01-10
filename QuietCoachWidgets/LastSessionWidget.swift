// LastSessionWidget.swift
// QuietCoachWidgets
//
// Shows the user's most recent rehearsal score.
// A quick glance at how their last practice went.

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct LastSessionEntry: TimelineEntry {
    let date: Date
    let scenarioTitle: String
    let overallScore: Int
    let sessionDate: Date?
    let isEmpty: Bool

    static var placeholder: LastSessionEntry {
        LastSessionEntry(
            date: Date(),
            scenarioTitle: "Set a Boundary",
            overallScore: 78,
            sessionDate: Date().addingTimeInterval(-3600),
            isEmpty: false
        )
    }

    static var empty: LastSessionEntry {
        LastSessionEntry(
            date: Date(),
            scenarioTitle: "",
            overallScore: 0,
            sessionDate: nil,
            isEmpty: true
        )
    }
}

// MARK: - Timeline Provider

struct LastSessionProvider: TimelineProvider {
    func placeholder(in context: Context) -> LastSessionEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (LastSessionEntry) -> Void) {
        let entry = loadLastSession()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LastSessionEntry>) -> Void) {
        let entry = loadLastSession()

        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadLastSession() -> LastSessionEntry {
        let defaults = UserDefaults(suiteName: "group.com.quietcoach") ?? .standard

        guard let scenarioTitle = defaults.string(forKey: "widget.lastScenarioTitle"),
              !scenarioTitle.isEmpty else {
            return .empty
        }

        let overallScore = defaults.integer(forKey: "widget.lastOverallScore")
        let sessionTimestamp = defaults.double(forKey: "widget.lastSessionDate")
        let sessionDate = sessionTimestamp > 0 ? Date(timeIntervalSince1970: sessionTimestamp) : nil

        return LastSessionEntry(
            date: Date(),
            scenarioTitle: scenarioTitle,
            overallScore: overallScore,
            sessionDate: sessionDate,
            isEmpty: false
        )
    }
}

// MARK: - Widget Views

struct LastSessionWidgetEntryView: View {
    var entry: LastSessionEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if entry.isEmpty {
            emptyView
        } else {
            switch family {
            case .accessoryRectangular:
                accessoryRectangularView
            case .systemSmall:
                smallView
            default:
                smallView
            }
        }
    }

    // MARK: - Empty State (iOS 26 Liquid Glass)

    private var emptyView: some View {
        ZStack {
            // Subtle gradient
            LinearGradient(
                colors: [
                    Color.gray.opacity(0.08),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 48, height: 48)
                        .blur(radius: 4)

                    Image(systemName: "waveform")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }

                Text("No sessions yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Start practicing!")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .containerBackground(for: .widget) {
            Color.black.opacity(0.3)
                .background(.ultraThinMaterial)
        }
    }

    // MARK: - Lock Screen Rectangular

    private var accessoryRectangularView: some View {
        HStack {
            scoreCircle(size: 32, fontSize: 14)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.scenarioTitle)
                    .font(.headline)
                    .lineLimit(1)

                if let date = entry.sessionDate {
                    Text(date, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Home Screen Small (iOS 26 Liquid Glass)

    private var smallView: some View {
        ZStack {
            // Liquid Glass gradient based on score
            LinearGradient(
                colors: [
                    scoreColor.opacity(0.15),
                    scoreColor.opacity(0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                HStack {
                    Text("Last Session")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                Spacer()

                // Glowing score circle
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(scoreColor.opacity(0.2))
                        .frame(width: 72, height: 72)
                        .blur(radius: 8)

                    scoreCircle(size: 64, fontSize: 24)
                }

                Text(entry.scenarioTitle)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let date = entry.sessionDate {
                    Text(date, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
        }
        .containerBackground(for: .widget) {
            Color.black.opacity(0.3)
                .background(.ultraThinMaterial)
        }
    }

    // MARK: - Score Circle

    private func scoreCircle(size: CGFloat, fontSize: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(scoreColor.opacity(0.3), lineWidth: 4)

            Circle()
                .trim(from: 0, to: CGFloat(entry.overallScore) / 100)
                .stroke(
                    LinearGradient(
                        colors: [scoreColor, scoreColor.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(entry.overallScore)")
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
        }
        .frame(width: size, height: size)
    }

    private var scoreColor: Color {
        switch entry.overallScore {
        case 80...: return .green
        case 60..<80: return .yellow
        default: return .orange
        }
    }
}

// MARK: - Widget Configuration

struct LastSessionWidget: Widget {
    let kind: String = "LastSessionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LastSessionProvider()) { entry in
            LastSessionWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Last Session")
        .description("See your most recent rehearsal score")
        .supportedFamilies([
            .accessoryRectangular,
            .systemSmall
        ])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    LastSessionWidget()
} timeline: {
    LastSessionEntry.placeholder
    LastSessionEntry.empty
}
