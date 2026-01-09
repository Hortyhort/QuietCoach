// QuickRecordControl.swift
// QuietCoachWidgets
//
// Control Center widget for quick practice access.
// Available on iOS 18+ for instant scenario launching.

import WidgetKit
import SwiftUI
import AppIntents

#if os(iOS)

// MARK: - Control Center Widget (iOS 18+)

@available(iOS 18.0, *)
struct QuickRecordControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.quietcoach.quickrecord") {
            ControlWidgetButton(action: LaunchQuickPracticeIntent()) {
                Label("Practice", systemImage: "waveform")
            }
        }
        .displayName("Quick Practice")
        .description("Start a practice session")
    }
}

// MARK: - Launch Intent

@available(iOS 18.0, *)
struct LaunchQuickPracticeIntent: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Launch Quick Practice"
    static let description = IntentDescription("Opens Quiet Coach to start practicing")

    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // Store flag for the app to pick up
        let defaults = UserDefaults(suiteName: "group.com.quietcoach") ?? .standard
        defaults.set(true, forKey: "launchToQuickPractice")
        return .result()
    }
}

// MARK: - Toggle Recording Control (iOS 18+)

@available(iOS 18.0, *)
struct RecordingToggleControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.quietcoach.recordingtoggle") {
            ControlWidgetToggle(
                "Recording",
                isOn: RecordingToggleProvider.shared.isRecording,
                action: ToggleRecordingIntent()
            ) { isRecording in
                Label(
                    isRecording ? "Recording" : "Paused",
                    systemImage: isRecording ? "waveform" : "pause.fill"
                )
            }
        }
        .displayName("Recording")
        .description("Toggle recording state")
    }
}

// MARK: - Recording State Provider

@available(iOS 18.0, *)
final class RecordingToggleProvider: Sendable {
    static let shared = RecordingToggleProvider()

    // UserDefaults access is thread-safe, so this can be nonisolated
    var isRecording: Bool {
        let defaults = UserDefaults(suiteName: "group.com.quietcoach") ?? .standard
        return defaults.bool(forKey: "isCurrentlyRecording")
    }

    private init() {}
}

// MARK: - Toggle Recording Intent

@available(iOS 18.0, *)
struct ToggleRecordingIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Toggle Recording"
    static let description = IntentDescription("Toggle the recording state")

    @Parameter(title: "Recording")
    var value: Bool

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.quietcoach") ?? .standard
        defaults.set(value, forKey: "toggleRecordingRequested")
        defaults.set(value, forKey: "requestedRecordingState")

        // Notify the app
        ControlCenter.shared.reloadAllControls()

        return .result()
    }
}

#endif
