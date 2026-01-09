// WatchStreakComplication.swift
// QuietCoachWatch
//
// Watch face complication showing streak data.

import SwiftUI
import WidgetKit

// MARK: - Streak Entry

struct WatchStreakEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let lastPractice: Date?
}

// MARK: - Streak Provider

struct WatchStreakProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> WatchStreakEntry {
        WatchStreakEntry(date: Date(), streak: 7, lastPractice: Date())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WatchStreakEntry) -> Void) {
        // In real implementation, fetch from shared UserDefaults
        let entry = WatchStreakEntry(date: Date(), streak: 5, lastPractice: Date())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchStreakEntry>) -> Void) {
        // In real implementation, fetch from shared UserDefaults
        let entry = WatchStreakEntry(date: Date(), streak: 5, lastPractice: Date())
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Streak Complication View

struct WatchStreakComplicationView: View {
    let entry: WatchStreakEntry
    
    @Environment(\.widgetFamily) private var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryCorner:
            cornerView
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
                    .font(.caption)
                    .foregroundStyle(.orange)
                
                Text("\(entry.streak)")
                    .font(.system(.title3, design: .rounded, weight: .bold))
            }
        }
    }
    
    // MARK: - Rectangular
    
    private var rectangularView: some View {
        HStack {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading) {
                Text("\(entry.streak) day streak")
                    .font(.headline)
                
                if entry.streak > 0 {
                    Text("Keep it going!")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Start practicing")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Corner
    
    private var cornerView: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            Image(systemName: "flame.fill")
                .font(.title3)
                .foregroundStyle(.orange)
        }
        .widgetLabel {
            Text("\(entry.streak)")
        }
    }
    
    // MARK: - Inline
    
    private var inlineView: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
            Text("\(entry.streak) day streak")
        }
    }
}

// MARK: - Widget Configuration

struct WatchStreakWidget: Widget {
    let kind: String = "WatchStreakWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchStreakProvider()) { entry in
            WatchStreakComplicationView(entry: entry)
        }
        .configurationDisplayName("Practice Streak")
        .description("Track your daily practice streak.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
            .accessoryInline
        ])
    }
}

// MARK: - Preview

#Preview(as: .accessoryCircular) {
    WatchStreakWidget()
} timeline: {
    WatchStreakEntry(date: Date(), streak: 7, lastPractice: Date())
    WatchStreakEntry(date: Date(), streak: 0, lastPractice: nil)
}
