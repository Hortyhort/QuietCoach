// WatchComplications.swift
// QuietCoachWatch
//
// Watch complications for practice streak display.
// Shows streak on watch face for motivation.

#if os(watchOS)
import WidgetKit
import SwiftUI

// MARK: - Streak Complication Entry

struct StreakComplicationEntry: TimelineEntry {
    let date: Date
    let streakDays: Int
    let lastPracticeDate: Date?
}

// MARK: - Streak Complication Provider

struct StreakComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakComplicationEntry {
        StreakComplicationEntry(date: Date(), streakDays: 7, lastPracticeDate: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakComplicationEntry) -> Void) {
        let entry = loadStreakData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakComplicationEntry>) -> Void) {
        let entry = loadStreakData()

        // Refresh at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)

        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }

    private func loadStreakData() -> StreakComplicationEntry {
        let defaults = UserDefaults(suiteName: "group.com.quietcoach") ?? .standard
        let streakDays = defaults.integer(forKey: "widget.streakDays")
        let lastPracticeTimestamp = defaults.double(forKey: "widget.lastPracticeDate")
        let lastPracticeDate = lastPracticeTimestamp > 0 ? Date(timeIntervalSince1970: lastPracticeTimestamp) : nil

        return StreakComplicationEntry(
            date: Date(),
            streakDays: streakDays,
            lastPracticeDate: lastPracticeDate
        )
    }
}

// MARK: - Streak Complication Views

struct StreakComplicationView: View {
    var entry: StreakComplicationEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryCorner:
            cornerView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            circularView
        }
    }

    // MARK: - Circular

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.orange)

                Text("\(entry.streakDays)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
        }
    }

    // MARK: - Corner

    private var cornerView: some View {
        ZStack {
            AccessoryWidgetBackground()

            Text("\(entry.streakDays)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
        }
        .widgetLabel {
            Text("day streak")
        }
    }

    // MARK: - Rectangular

    private var rectangularView: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.streakDays) day streak")
                    .font(.headline)

                if let lastDate = entry.lastPracticeDate {
                    Text("Last: \(lastDate, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Inline

    private var inlineView: some View {
        HStack {
            Image(systemName: "flame.fill")
            Text("\(entry.streakDays) day streak")
        }
    }
}

// MARK: - Streak Complication Widget

struct StreakComplication: Widget {
    let kind: String = "StreakComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakComplicationProvider()) { entry in
            StreakComplicationView(entry: entry)
        }
        .configurationDisplayName("Practice Streak")
        .description("Track your daily practice consistency")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Quick Practice Complication

struct QuickPracticeComplicationEntry: TimelineEntry {
    let date: Date
}

struct QuickPracticeComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickPracticeComplicationEntry {
        QuickPracticeComplicationEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickPracticeComplicationEntry) -> Void) {
        completion(QuickPracticeComplicationEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickPracticeComplicationEntry>) -> Void) {
        let entry = QuickPracticeComplicationEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct QuickPracticeComplicationView: View {
    var entry: QuickPracticeComplicationEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "waveform")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }
        case .accessoryCorner:
            Image(systemName: "waveform")
                .font(.title3)
                .foregroundStyle(.orange)
                .widgetLabel {
                    Text("Practice")
                }
        default:
            Image(systemName: "waveform")
                .foregroundStyle(.orange)
        }
    }
}

struct QuickPracticeComplication: Widget {
    let kind: String = "QuickPracticeComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickPracticeComplicationProvider()) { entry in
            QuickPracticeComplicationView(entry: entry)
        }
        .configurationDisplayName("Quick Practice")
        .description("Launch a practice session")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner
        ])
    }
}

// MARK: - Preview

#Preview(as: .accessoryCircular) {
    StreakComplication()
} timeline: {
    StreakComplicationEntry(date: Date(), streakDays: 7, lastPracticeDate: Date())
}
#endif
