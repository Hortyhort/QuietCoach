// RecordingTypes.swift
// QuietCoach
//
// Recording state machine types and formatted time helpers.

import Foundation

// MARK: - Recording State

/// Recording state machine states
enum RecordingState: Equatable, Sendable {
    case idle
    case recording
    case paused
    case finished
}

/// Warnings displayed during recording
enum RecordingWarning: Equatable, Sendable {
    case tooQuiet
    case tooLoud
    case noisyEnvironment

    var icon: String {
        switch self {
        case .tooQuiet: return "speaker.slash.fill"
        case .tooLoud: return "speaker.wave.3.fill"
        case .noisyEnvironment: return "waveform.badge.exclamationmark"
        }
    }

    var message: String {
        switch self {
        case .tooQuiet: return "Speak up or move closer"
        case .tooLoud: return "Too loud — move back slightly"
        case .noisyEnvironment: return "Noisy environment detected"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .tooQuiet: return "Warning: Audio too quiet. Speak up or move closer to the microphone."
        case .tooLoud: return "Warning: Audio too loud. Move back slightly from the microphone."
        case .noisyEnvironment: return "Warning: Noisy environment detected. Consider moving to a quieter location."
        }
    }
}

// MARK: - Formatted Time Extension

extension RehearsalRecorder {
    /// Current time formatted as "M:SS"
    var formattedCurrentTime: String {
        currentTime.qcFormattedDuration
    }

    /// Remaining time before max duration
    var remainingTime: TimeInterval {
        max(0, Constants.Limits.maxRecordingDuration - currentTime)
    }

    /// Whether recording is near max duration (last 30 seconds)
    var isNearMaxDuration: Bool {
        remainingTime < 30 && state == .recording
    }
}
