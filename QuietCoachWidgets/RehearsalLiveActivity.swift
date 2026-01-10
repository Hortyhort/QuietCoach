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
                // Expanded regions with Liquid Glass design
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        // Glowing icon
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 24, height: 24)
                                .blur(radius: 2)

                            Image(systemName: context.attributes.scenarioIcon)
                                .font(.caption)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .yellow.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }

                        Text(context.attributes.scenarioTitle)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    recordingIndicator(isRecording: context.state.isRecording, isPaused: context.state.isPaused)
                        .frame(width: 28, height: 28)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        // Glowing timer
                        Text(formatTime(context.state.elapsedTime))
                            .font(.system(size: 32, weight: .medium, design: .monospaced))
                            .foregroundStyle(.primary)
                            .shadow(color: indicatorColor(isRecording: context.state.isRecording, isPaused: context.state.isPaused).opacity(0.3), radius: 4)

                        Spacer()

                        // Status pill
                        statusLabel(isRecording: context.state.isRecording, isPaused: context.state.isPaused)
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                // Compact leading with glow
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .blur(radius: 2)

                    Image(systemName: "waveform")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            } compactTrailing: {
                // Compact trailing with color indicator
                Text(formatTimeCompact(context.state.elapsedTime))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(context.state.isRecording ? .primary : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(indicatorColor(isRecording: context.state.isRecording, isPaused: context.state.isPaused).opacity(0.2))
                    )
            } minimal: {
                // Minimal with pulsing glow
                ZStack {
                    Circle()
                        .fill(indicatorColor(isRecording: context.state.isRecording, isPaused: context.state.isPaused).opacity(0.3))
                        .blur(radius: 2)

                    Image(systemName: context.state.isRecording ? "waveform" : "pause.fill")
                        .font(.caption2)
                        .foregroundStyle(indicatorColor(isRecording: context.state.isRecording, isPaused: context.state.isPaused))
                }
            }
        }
    }

    // MARK: - Lock Screen View (iOS 26 Liquid Glass)

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<RehearsalActivityAttributes>) -> some View {
        ZStack {
            // Liquid Glass gradient background
            LinearGradient(
                colors: [
                    indicatorColor(isRecording: context.state.isRecording, isPaused: context.state.isPaused).opacity(0.15),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 16) {
                // Glowing recording indicator
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

                // Glowing scenario icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .blur(radius: 4)

                    Image(systemName: context.attributes.scenarioIcon)
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .yellow.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            .padding()
        }
        .activityBackgroundTint(.black.opacity(0.6))
    }

    // MARK: - Recording Indicator (Liquid Glass)

    @ViewBuilder
    private func recordingIndicator(isRecording: Bool, isPaused: Bool) -> some View {
        let color = indicatorColor(isRecording: isRecording, isPaused: isPaused)

        ZStack {
            // Outer glow
            Circle()
                .fill(color.opacity(0.2))
                .blur(radius: 4)

            // Glass ring
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 2)

            // Pulsing inner dot
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color, color.opacity(0.6)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 8
                    )
                )
                .frame(width: 16, height: 16)
                .shadow(color: color.opacity(0.6), radius: 4)
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

    // MARK: - Status Label (Liquid Glass)

    @ViewBuilder
    private func statusLabel(isRecording: Bool, isPaused: Bool) -> some View {
        let (text, icon, color): (String, String, Color) = {
            if isPaused {
                return ("Paused", "pause.fill", .yellow)
            } else if isRecording {
                return ("Recording", "circle.fill", .red)
            } else {
                return ("Stopped", "stop.fill", .gray)
            }
        }()

        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(text)
                .font(.caption2)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
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
