// WatchComplications.swift
// QuietCoachWatch
//
// Watch complications for quick rehearsal access.

#if os(watchOS)
import WidgetKit
import SwiftUI

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
    QuickPracticeComplication()
} timeline: {
    QuickPracticeComplicationEntry(date: Date())
}
#endif
