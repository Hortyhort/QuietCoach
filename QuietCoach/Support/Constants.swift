// Constants.swift
// QuietCoach
//
// The configuration spine of the app. Every magic number lives here.
// Every threshold is named, not buried in code.

import Foundation

enum Constants {

    // MARK: - App Identity

    enum App {
        static let name = "Quiet Coach"
        static let tagline = "Practice the hard conversations."
        static let version = "1.0.0"
        static let bundleIdentifier = "com.quietcoach.app"
        static let supportEmail = "support@quietcoach.app"
        static let privacyURL = "https://quietcoach.app/privacy"
        static let supportURL = "https://quietcoach.app/support"

        // CloudKit container identifier
        static let cloudKitContainerID = "iCloud.com.quietcoach"
    }

    // MARK: - Recording Limits

    enum Limits {
        /// Maximum recording duration in seconds (6 minutes)
        static let maxRecordingDuration: TimeInterval = 360

        /// Minimum recording duration to be considered valid (3 seconds)
        static let minRecordingDuration: TimeInterval = 3

        /// Number of sessions visible to free users
        static let freeSessionLimit = 10

        /// Number of scenarios available to free users
        static let freeScenariosCount = 6

        /// Interval between audio metering updates (100ms = 10Hz)
        static let meteringInterval: TimeInterval = 0.1

        /// Number of samples to display in waveform
        static let waveformSampleCount = 50
    }

    // MARK: - Calm Start Timing

    enum CalmStart {
        /// Duration of the "breathe" phase
        static let breathDuration: TimeInterval = 2.0

        /// Duration of the prompt display phase
        static let promptDuration: TimeInterval = 2.0

        /// Total calm start duration before recording begins
        static let totalDuration: TimeInterval = 4.0
    }

    // MARK: - Audio Quality Thresholds

    enum AudioQuality {
        /// RMS level below which we consider audio too quiet
        static let tooQuietThreshold: Float = 0.02

        /// Peak level above which we consider audio too loud (clipping risk)
        static let tooLoudThreshold: Float = 0.95

        /// Noise floor above which environment is considered noisy
        static let noisyEnvironmentThreshold: Float = 0.05

        /// Number of windows to analyze for warning checks
        static let warningCheckWindowSize = 10

        /// Duration in seconds to calibrate noise floor
        static let noiseFloorCalibrationDuration: TimeInterval = 0.3
    }

    // MARK: - File Storage

    enum Directories {
        /// Subdirectory for audio recordings in Application Support
        static let recordings = "Recordings"
    }

    // MARK: - Haptics & Sounds

    /// User-configurable settings stored via UserDefaults
    /// Access these through UserDefaults.standard or @AppStorage
    enum SettingsKeys {
        static let hapticsEnabled = "settings.hapticsEnabled"
        static let soundsEnabled = "settings.soundsEnabled"
        static let focusSoundsEnabled = "settings.focusSoundsEnabled"
    }

    enum Haptics {
        /// Master switch for haptic feedback (reads from UserDefaults)
        static var enabled: Bool {
            // Default to true if not set
            if UserDefaults.standard.object(forKey: SettingsKeys.hapticsEnabled) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: SettingsKeys.hapticsEnabled)
        }
    }

    enum Sounds {
        /// Master switch for UI sounds (reads from UserDefaults)
        static var enabled: Bool {
            // Default to true if not set
            if UserDefaults.standard.object(forKey: SettingsKeys.soundsEnabled) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: SettingsKeys.soundsEnabled)
        }

        /// Focus/ambient sounds during recording
        static var focusEnabled: Bool {
            // Default to false - opt-in feature
            return UserDefaults.standard.bool(forKey: SettingsKeys.focusSoundsEnabled)
        }
    }

    // MARK: - Animation

    enum Animation {
        /// Default spring response time
        static let springResponse: Double = 0.4

        /// Default spring damping fraction
        static let springDamping: Double = 0.7

        /// Quick spring for micro-interactions
        static let quickSpringResponse: Double = 0.25

        /// Gentle spring for larger transitions
        static let gentleSpringResponse: Double = 0.5
    }

    // MARK: - Layout

    enum Layout {
        /// Standard horizontal padding
        static let horizontalPadding: CGFloat = 24

        /// Standard vertical spacing between sections
        static let sectionSpacing: CGFloat = 24

        /// Corner radius for cards and containers
        static let cornerRadius: CGFloat = 16

        /// Corner radius for smaller elements
        static let smallCornerRadius: CGFloat = 12

        /// Minimum touch target size (Apple HIG)
        static let minTouchTarget: CGFloat = 44

        /// Recording button size
        static let recordButtonSize: CGFloat = 80

        /// Secondary button size
        static let secondaryButtonSize: CGFloat = 64
    }
}
