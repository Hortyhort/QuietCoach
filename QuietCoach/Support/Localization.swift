// Localization.swift
// QuietCoach
//
// Type-safe localization infrastructure.
// All user-facing strings should be defined here for easy translation.

import Foundation
import SwiftUI

// MARK: - Localized Strings

/// Type-safe access to all localized strings
enum L10n {

    // MARK: - Common

    enum Common {
        static let appName = NSLocalizedString("common.app_name", value: "QuietCoach", comment: "App name")
        static let ok = NSLocalizedString("common.ok", value: "OK", comment: "OK button")
        static let cancel = NSLocalizedString("common.cancel", value: "Cancel", comment: "Cancel button")
        static let done = NSLocalizedString("common.done", value: "Done", comment: "Done button")
        static let next = NSLocalizedString("common.next", value: "Next", comment: "Next button")
        static let back = NSLocalizedString("common.back", value: "Back", comment: "Back button")
        static let tryAgain = NSLocalizedString("common.try_again", value: "Try Again", comment: "Try again button")
        static let close = NSLocalizedString("common.close", value: "Close", comment: "Close button")
        static let save = NSLocalizedString("common.save", value: "Save", comment: "Save button")
        static let delete = NSLocalizedString("common.delete", value: "Delete", comment: "Delete button")
        static let share = NSLocalizedString("common.share", value: "Share", comment: "Share button")
        static let settings = NSLocalizedString("common.settings", value: "Settings", comment: "Settings button")
    }

    // MARK: - Onboarding

    enum Onboarding {
        static let welcomeTitle = NSLocalizedString("onboarding.welcome_title", value: "Practice Speaking", comment: "Onboarding welcome title")
        static let welcomeSubtitle = NSLocalizedString("onboarding.welcome_subtitle", value: "Build confidence for conversations that matter", comment: "Onboarding welcome subtitle")
        static let getStarted = NSLocalizedString("onboarding.get_started", value: "Get Started", comment: "Get started button")
        static let skipIntro = NSLocalizedString("onboarding.skip_intro", value: "Skip Intro", comment: "Skip intro button")

        static let permissionTitle = NSLocalizedString("onboarding.permission_title", value: "Microphone Access", comment: "Permission screen title")
        static let permissionDescription = NSLocalizedString("onboarding.permission_description", value: "QuietCoach needs microphone access to record your practice sessions. All audio stays on your device.", comment: "Permission description")
        static let grantAccess = NSLocalizedString("onboarding.grant_access", value: "Grant Access", comment: "Grant access button")
    }

    // MARK: - Home

    enum Home {
        static let title = NSLocalizedString("home.title", value: "Practice", comment: "Home screen title")
        static let recentSessions = NSLocalizedString("home.recent_sessions", value: "Recent Sessions", comment: "Recent sessions section title")
        static let noSessions = NSLocalizedString("home.no_sessions", value: "No sessions yet", comment: "Empty state for no sessions")
        static let startPractice = NSLocalizedString("home.start_practice", value: "Start Practice", comment: "Start practice button")

        static let scenariosTitle = NSLocalizedString("home.scenarios_title", value: "Choose a Scenario", comment: "Scenarios section title")
        static let proLabel = NSLocalizedString("home.pro_label", value: "PRO", comment: "Pro feature label")
    }

    // MARK: - Recording

    enum Recording {
        static let tapToStart = NSLocalizedString("recording.tap_to_start", value: "Tap to Start", comment: "Tap to start recording instruction")
        static let recording = NSLocalizedString("recording.recording", value: "Recording", comment: "Recording status")
        static let tapToStop = NSLocalizedString("recording.tap_to_stop", value: "Tap to Stop", comment: "Tap to stop recording instruction")
        static let analyzing = NSLocalizedString("recording.analyzing", value: "Analyzing...", comment: "Analyzing status")

        static func duration(_ seconds: Int) -> String {
            let format = NSLocalizedString("recording.duration", value: "%d seconds", comment: "Recording duration in seconds")
            return String(format: format, seconds)
        }
    }

    // MARK: - Feedback

    enum Feedback {
        static let title = NSLocalizedString("feedback.title", value: "Your Feedback", comment: "Feedback screen title")
        static let overallScore = NSLocalizedString("feedback.overall_score", value: "Overall Score", comment: "Overall score label")

        static let clarity = NSLocalizedString("feedback.clarity", value: "Clarity", comment: "Clarity score label")
        static let pacing = NSLocalizedString("feedback.pacing", value: "Pacing", comment: "Pacing score label")
        static let tone = NSLocalizedString("feedback.tone", value: "Tone", comment: "Tone score label")
        static let confidence = NSLocalizedString("feedback.confidence", value: "Confidence", comment: "Confidence score label")

        static let insights = NSLocalizedString("feedback.insights", value: "Insights", comment: "Insights section title")
        static let tryAgain = NSLocalizedString("feedback.try_again", value: "Practice Again", comment: "Practice again button")
        static let shareResult = NSLocalizedString("feedback.share_result", value: "Share Result", comment: "Share result button")

        // Score tiers
        static let tierExcellent = NSLocalizedString("feedback.tier.excellent", value: "Excellent", comment: "Excellent score tier")
        static let tierGood = NSLocalizedString("feedback.tier.good", value: "Good", comment: "Good score tier")
        static let tierDeveloping = NSLocalizedString("feedback.tier.developing", value: "Developing", comment: "Developing score tier")
        static let tierNeedsWork = NSLocalizedString("feedback.tier.needs_work", value: "Needs Work", comment: "Needs work score tier")
    }

    // MARK: - Scores Explanation

    enum ScoreExplanation {
        static let clarityDescription = NSLocalizedString("score.clarity.description", value: "Based on pause patterns and silence. Clear speakers pause intentionally.", comment: "Clarity score explanation")
        static let pacingDescription = NSLocalizedString("score.pacing.description", value: "Based on rhythm—phrases per minute. Too fast or slow affects your score.", comment: "Pacing score explanation")
        static let toneDescription = NSLocalizedString("score.tone.description", value: "Based on volume stability. Consistent volume sounds calm and controlled.", comment: "Tone score explanation")
        static let confidenceDescription = NSLocalizedString("score.confidence.description", value: "Based on volume level and consistency. Steady delivery sounds assured.", comment: "Confidence score explanation")
    }

    // MARK: - Settings

    enum Settings {
        static let title = NSLocalizedString("settings.title", value: "Settings", comment: "Settings screen title")
        static let account = NSLocalizedString("settings.account", value: "Account", comment: "Account section")
        static let subscription = NSLocalizedString("settings.subscription", value: "Subscription", comment: "Subscription setting")
        static let restorePurchases = NSLocalizedString("settings.restore_purchases", value: "Restore Purchases", comment: "Restore purchases button")

        static let preferences = NSLocalizedString("settings.preferences", value: "Preferences", comment: "Preferences section")
        static let hapticFeedback = NSLocalizedString("settings.haptic_feedback", value: "Haptic Feedback", comment: "Haptic feedback toggle")
        static let soundEffects = NSLocalizedString("settings.sound_effects", value: "Sound Effects", comment: "Sound effects toggle")

        static let about = NSLocalizedString("settings.about", value: "About", comment: "About section")
        static let version = NSLocalizedString("settings.version", value: "Version", comment: "Version label")
        static let privacyPolicy = NSLocalizedString("settings.privacy_policy", value: "Privacy Policy", comment: "Privacy policy link")
        static let termsOfService = NSLocalizedString("settings.terms_of_service", value: "Terms of Service", comment: "Terms of service link")
        static let sendFeedback = NSLocalizedString("settings.send_feedback", value: "Send Feedback", comment: "Send feedback button")
    }

    // MARK: - Subscription

    enum Subscription {
        static let upgradeTitle = NSLocalizedString("subscription.upgrade_title", value: "Upgrade to Pro", comment: "Upgrade screen title")
        static let features = NSLocalizedString("subscription.features", value: "Pro Features", comment: "Pro features section")
        static let subscribe = NSLocalizedString("subscription.subscribe", value: "Subscribe", comment: "Subscribe button")
        static let restoring = NSLocalizedString("subscription.restoring", value: "Restoring...", comment: "Restoring status")

        static func pricePerMonth(_ price: String) -> String {
            let format = NSLocalizedString("subscription.price_per_month", value: "%@ / month", comment: "Price per month")
            return String(format: format, price)
        }
    }

    // MARK: - Errors

    enum Errors {
        static let microphoneAccessDenied = NSLocalizedString("error.microphone_denied", value: "Microphone access is required to record your practice sessions.", comment: "Microphone access denied error")
        static let recordingFailed = NSLocalizedString("error.recording_failed", value: "Recording failed. Please try again.", comment: "Recording failed error")
        static let analysisFailed = NSLocalizedString("error.analysis_failed", value: "Could not analyze your recording. Audio-only feedback will be provided.", comment: "Analysis failed error")
        static let saveFailed = NSLocalizedString("error.save_failed", value: "Could not save your session. Please try again.", comment: "Save failed error")
        static let networkError = NSLocalizedString("error.network", value: "Please check your internet connection and try again.", comment: "Network error")
    }

    // MARK: - Accessibility

    enum Accessibility {
        static let recordButton = NSLocalizedString("accessibility.record_button", value: "Record", comment: "Record button accessibility label")
        static let stopButton = NSLocalizedString("accessibility.stop_button", value: "Stop Recording", comment: "Stop button accessibility label")
        static let playButton = NSLocalizedString("accessibility.play_button", value: "Play Recording", comment: "Play button accessibility label")
        static let pauseButton = NSLocalizedString("accessibility.pause_button", value: "Pause", comment: "Pause button accessibility label")

        static func scoreValue(_ type: String, _ value: Int) -> String {
            let format = NSLocalizedString("accessibility.score_value", value: "%@ score: %d out of 100", comment: "Score value announcement")
            return String(format: format, type, value)
        }
    }
}

// MARK: - String Formatting Helpers

extension L10n {
    /// Format a score for display
    static func formatScore(_ score: Int) -> String {
        "\(score)"
    }

    /// Format duration for display
    static func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60

        if minutes > 0 {
            let format = NSLocalizedString("duration.minutes_seconds", value: "%d:%02d", comment: "Duration format")
            return String(format: format, minutes, secs)
        } else {
            return Recording.duration(Int(seconds))
        }
    }
}

// MARK: - SwiftUI Text Extensions

extension Text {
    /// Create localized text from L10n string
    init(localized string: String) {
        self.init(verbatim: string)
    }
}
