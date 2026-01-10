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

    // MARK: - Home Screen Small (iOS 26 Liquid Glass)

    private var smallView: some View {
        ZStack {
            // Liquid Glass gradient background
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.15),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                HStack {
                    // Glowing flame icon
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .blur(radius: 4)

                        Image(systemName: "flame.fill")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    Spacer()
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(entry.streakDays)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(entry.streakDays == 1 ? "day streak" : "day streak")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .containerBackground(for: .widget) {
            // Frosted glass effect
            Color.black.opacity(0.3)
                .background(.ultraThinMaterial)
        }
    }

    // MARK: - Home Screen Medium (iOS 26 Liquid Glass)

    private var mediumView: some View {
        ZStack {
            // Liquid Glass gradient background
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.12),
                    Color.purple.opacity(0.08),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 16) {
                // Streak section with floating card effect
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        // Glowing flame icon
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.25))
                                .frame(width: 28, height: 28)
                                .blur(radius: 3)

                            Image(systemName: "flame.fill")
                                .font(.subheadline)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }

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
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                // Stats section with glass pill
                VStack(alignment: .trailing, spacing: 8) {
                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(entry.totalSessions)")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                        Text("total sessions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
