// RehearsalLiveActivity.swift
// QuietCoachWidgets
//
// Live Activity for rehearsal recording. Shows recording status
// in Dynamic Island and on the lock screen.

import WidgetKit
import SwiftUI

#if os(iOS)
import ActivityKit

// MARK: - Live Activity Attributes

struct RehearsalActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var elapsedTime: TimeInterval
        var isRecording: Bool
        var isPaused: Bool
    }

    let scenarioTitle: String
    let scenarioIcon: String
}

// MARK: - Live Activity Widget

struct RehearsalLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RehearsalActivityAttributes.self) { context in
            // Lock screen / banner presentation
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded regions
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: context.attributes.scenarioIcon)
                            .foregroundStyle(.orange)
                        Text(context.attributes.scenarioTitle)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    recordingIndicator(isRecording: context.state.isRecording, isPaused: context.state.isPaused)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        // Timer
                        Text(formatTime(context.state.elapsedTime))
                            .font(.system(size: 32, weight: .medium, design: .monospaced))
                            .foregroundStyle(.primary)

                        Spacer()

                        // Status
                        statusLabel(isRecording: context.state.isRecording, isPaused: context.state.isPaused)
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                // Compact leading
                Image(systemName: "waveform")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                // Compact trailing
                Text(formatTimeCompact(context.state.elapsedTime))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(context.state.isRecording ? .primary : .secondary)
            } minimal: {
                // Minimal presentation
                Image(systemName: context.state.isRecording ? "waveform" : "pause.fill")
                    .foregroundStyle(.orange)
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<RehearsalActivityAttributes>) -> some View {
        HStack(spacing: 16) {
            // Recording indicator
            recordingIndicator(isRecording: context.state.isRecording, isPaused: context.state.isPaused)
                .frame(width: 44, height: 44)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.scenarioTitle)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(formatTime(context.state.elapsedTime))
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(.secondary)

                    statusLabel(isRecording: context.state.isRecording, isPaused: context.state.isPaused)
                }
            }

            Spacer()

            // Icon
            Image(systemName: context.attributes.scenarioIcon)
                .font(.title2)
                .foregroundStyle(.orange)
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.8))
    }

    // MARK: - Recording Indicator

    @ViewBuilder
    private func recordingIndicator(isRecording: Bool, isPaused: Bool) -> some View {
        ZStack {
            Circle()
                .fill(indicatorColor(isRecording: isRecording, isPaused: isPaused).opacity(0.2))

            Circle()
                .fill(indicatorColor(isRecording: isRecording, isPaused: isPaused))
                .frame(width: 12, height: 12)
        }
    }

    private func indicatorColor(isRecording: Bool, isPaused: Bool) -> Color {
        if isPaused {
            return .yellow
        } else if isRecording {
            return .red
        } else {
            return .gray
        }
    }

    // MARK: - Status Label

    @ViewBuilder
    private func statusLabel(isRecording: Bool, isPaused: Bool) -> some View {
        if isPaused {
            Label("Paused", systemImage: "pause.fill")
                .font(.caption)
                .foregroundStyle(.yellow)
        } else if isRecording {
            Label("Recording", systemImage: "circle.fill")
                .font(.caption)
                .foregroundStyle(.red)
        } else {
            Label("Stopped", systemImage: "stop.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Time Formatting

    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func formatTimeCompact(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: RehearsalActivityAttributes(scenarioTitle: "Set a Boundary", scenarioIcon: "hand.raised.fill")) {
    RehearsalLiveActivity()
} contentStates: {
    RehearsalActivityAttributes.ContentState(elapsedTime: 45, isRecording: true, isPaused: false)
    RehearsalActivityAttributes.ContentState(elapsedTime: 120, isRecording: true, isPaused: true)
}

#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: RehearsalActivityAttributes(scenarioTitle: "Set a Boundary", scenarioIcon: "hand.raised.fill")) {
    RehearsalLiveActivity()
} contentStates: {
    RehearsalActivityAttributes.ContentState(elapsedTime: 45, isRecording: true, isPaused: false)
}

#endif
