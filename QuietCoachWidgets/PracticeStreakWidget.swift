// PracticeStreakWidget.swift
// QuietCoachWidgets
//
// Shows the user's practice streak. A gentle reminder
// that consistency builds confidence.

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct PracticeStreakEntry: TimelineEntry {
    let date: Date
    let streakDays: Int
    let lastPracticeDate: Date?
    let totalSessions: Int
}

// MARK: - Timeline Provider

struct PracticeStreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> PracticeStreakEntry {
        PracticeStreakEntry(
            date: Date(),
            streakDays: 7,
            lastPracticeDate: Date(),
            totalSessions: 42
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PracticeStreakEntry) -> Void) {
        let entry = loadStreakData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PracticeStreakEntry>) -> Void) {
        let entry = loadStreakData()

        // Refresh at midnight to update streak
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)

        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }

    private func loadStreakData() -> PracticeStreakEntry {
        // Load from shared UserDefaults (App Group)
        let defaults = UserDefaults(suiteName: "group.com.quietcoach") ?? .standard

        let streakDays = defaults.integer(forKey: "widget.streakDays")
        let totalSessions = defaults.integer(forKey: "widget.totalSessions")
        let lastPracticeTimestamp = defaults.double(forKey: "widget.lastPracticeDate")
        let lastPracticeDate = lastPracticeTimestamp > 0 ? Date(timeIntervalSince1970: lastPracticeTimestamp) : nil

        return PracticeStreakEntry(
            date: Date(),
            streakDays: streakDays,
            lastPracticeDate: lastPracticeDate,
            totalSessions: totalSessions
        )
    }
}

// MARK: - Widget Views

struct PracticeStreakWidgetEntryView: View {
    var entry: PracticeStreakEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            accessoryCircularView
        case .accessoryRectangular:
            accessoryRectangularView
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    // MARK: - Lock Screen Circular

    private var accessoryCircularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                Text("\(entry.streakDays)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
        }
    }

    // MARK: - Lock Screen Rectangular

    private var accessoryRectangularView: some View {
        HStack {
            Image(systemName: "flame.fill")
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.streakDays) day streak")
                    .font(.headline)
                Text("\(entry.totalSessions) total sessions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Home Screen Small

    private var smallView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Spacer()
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.streakDays)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("day streak")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .containerBackground(.black, for: .widget)
    }

    // MARK: - Home Screen Medium

    private var mediumView: some View {
        HStack(spacing: 16) {
            // Streak section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text("Practice Streak")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("\(entry.streakDays) days")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                if let lastDate = entry.lastPracticeDate {
                    Text("Last: \(lastDate, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Stats section
            VStack(alignment: .trailing, spacing: 8) {
                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(entry.totalSessions)")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                    Text("total sessions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .containerBackground(.black, for: .widget)
    }
}

// MARK: - Widget Configuration

struct PracticeStreakWidget: Widget {
    let kind: String = "PracticeStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PracticeStreakProvider()) { entry in
            PracticeStreakWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Practice Streak")
        .description("Track your daily practice consistency")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .systemSmall,
            .systemMedium
        ])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    PracticeStreakWidget()
} timeline: {
    PracticeStreakEntry(date: Date(), streakDays: 7, lastPracticeDate: Date(), totalSessions: 42)
    PracticeStreakEntry(date: Date(), streakDays: 0, lastPracticeDate: nil, totalSessions: 0)
}
