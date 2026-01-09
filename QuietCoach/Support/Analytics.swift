// Analytics.swift
// QuietCoach
//
// Privacy-respecting analytics foundation.
// No personal data collection. All data is anonymous.

import Foundation
import OSLog

// MARK: - Analytics Protocol

/// Protocol for analytics backends
/// Implementations can use TelemetryDeck, Firebase, or custom solutions
protocol AnalyticsProvider: Sendable {
    /// Track an event
    func track(_ event: AnalyticsEvent)

    /// Track a screen view
    func trackScreen(_ screen: String)

    /// Set a user property (anonymous)
    func setUserProperty(_ property: String, value: String?)
}

// MARK: - Analytics Events

/// All trackable events in the app
enum AnalyticsEvent: Sendable {
    // MARK: - Onboarding
    case onboardingStarted
    case onboardingCompleted
    case onboardingSkipped

    // MARK: - Recording
    case recordingStarted(scenario: String)
    case recordingCompleted(durationSeconds: Int)
    case recordingCancelled
    case recordingError(reason: String)

    // MARK: - Feedback
    case feedbackViewed(overallScore: Int)
    case feedbackShared
    case insightTapped(type: String)

    // MARK: - Subscription
    case paywallViewed(source: String)
    case purchaseStarted(productId: String)
    case purchaseCompleted(productId: String)
    case purchaseFailed(reason: String)
    case restoreStarted
    case restoreCompleted(success: Bool)

    // MARK: - Settings
    case settingsOpened
    case settingChanged(name: String, value: String)

    // MARK: - Progress
    case sessionMilestone(count: Int)
    case streakAchieved(days: Int)
    case scoreImproved(category: String, delta: Int)

    // MARK: - Errors
    case errorOccurred(type: String, recoverable: Bool)
    case speechRecognitionFailed(reason: String)
    case permissionDenied(type: String)

    /// Event name for tracking
    var name: String {
        switch self {
        case .onboardingStarted: return "onboarding_started"
        case .onboardingCompleted: return "onboarding_completed"
        case .onboardingSkipped: return "onboarding_skipped"
        case .recordingStarted: return "recording_started"
        case .recordingCompleted: return "recording_completed"
        case .recordingCancelled: return "recording_cancelled"
        case .recordingError: return "recording_error"
        case .feedbackViewed: return "feedback_viewed"
        case .feedbackShared: return "feedback_shared"
        case .insightTapped: return "insight_tapped"
        case .paywallViewed: return "paywall_viewed"
        case .purchaseStarted: return "purchase_started"
        case .purchaseCompleted: return "purchase_completed"
        case .purchaseFailed: return "purchase_failed"
        case .restoreStarted: return "restore_started"
        case .restoreCompleted: return "restore_completed"
        case .settingsOpened: return "settings_opened"
        case .settingChanged: return "setting_changed"
        case .sessionMilestone: return "session_milestone"
        case .streakAchieved: return "streak_achieved"
        case .scoreImproved: return "score_improved"
        case .errorOccurred: return "error_occurred"
        case .speechRecognitionFailed: return "speech_recognition_failed"
        case .permissionDenied: return "permission_denied"
        }
    }

    /// Event parameters
    var parameters: [String: String] {
        switch self {
        case .onboardingStarted, .onboardingCompleted, .onboardingSkipped:
            return [:]

        case .recordingStarted(let scenario):
            return ["scenario": scenario]

        case .recordingCompleted(let duration):
            // Bucket duration to protect privacy
            let bucket = durationBucket(duration)
            return ["duration_bucket": bucket]

        case .recordingCancelled:
            return [:]

        case .recordingError(let reason):
            return ["reason": reason]

        case .feedbackViewed(let score):
            // Bucket score to protect privacy
            let bucket = scoreBucket(score)
            return ["score_bucket": bucket]

        case .feedbackShared:
            return [:]

        case .insightTapped(let type):
            return ["type": type]

        case .paywallViewed(let source):
            return ["source": source]

        case .purchaseStarted(let productId), .purchaseCompleted(let productId):
            return ["product_id": productId]

        case .purchaseFailed(let reason):
            return ["reason": reason]

        case .restoreStarted:
            return [:]

        case .restoreCompleted(let success):
            return ["success": success ? "true" : "false"]

        case .settingsOpened:
            return [:]

        case .settingChanged(let name, let value):
            return ["name": name, "value": value]

        case .sessionMilestone(let count):
            // Only track specific milestones
            return ["count": String(count)]

        case .streakAchieved(let days):
            return ["days": String(days)]

        case .scoreImproved(let category, let delta):
            return ["category": category, "delta_bucket": deltaBucket(delta)]

        case .errorOccurred(let type, let recoverable):
            return ["type": type, "recoverable": recoverable ? "true" : "false"]

        case .speechRecognitionFailed(let reason):
            return ["reason": reason]

        case .permissionDenied(let type):
            return ["type": type]
        }
    }

    // MARK: - Privacy Bucketing

    /// Bucket duration into ranges to protect privacy
    private func durationBucket(_ seconds: Int) -> String {
        switch seconds {
        case 0..<15: return "0-15s"
        case 15..<30: return "15-30s"
        case 30..<60: return "30-60s"
        case 60..<120: return "1-2min"
        case 120..<300: return "2-5min"
        default: return "5min+"
        }
    }

    /// Bucket score into ranges to protect privacy
    private func scoreBucket(_ score: Int) -> String {
        switch score {
        case 0..<50: return "0-49"
        case 50..<70: return "50-69"
        case 70..<85: return "70-84"
        case 85..<100: return "85-99"
        default: return "100"
        }
    }

    /// Bucket delta into ranges to protect privacy
    private func deltaBucket(_ delta: Int) -> String {
        switch delta {
        case ..<(-10): return "large_decrease"
        case -10..<0: return "small_decrease"
        case 0: return "no_change"
        case 1...10: return "small_increase"
        default: return "large_increase"
        }
    }
}

// MARK: - Analytics Manager

/// Centralized analytics manager
@MainActor
final class Analytics {
    static let shared = Analytics()

    private var providers: [any AnalyticsProvider] = []
    private let logger = Logger(subsystem: "com.quietcoach", category: "Analytics")
    private var isEnabled = true

    private init() {
        // Add default local provider for debugging
        #if DEBUG
        providers.append(LocalAnalyticsProvider())
        #endif
    }

    // MARK: - Configuration

    /// Add an analytics provider
    func addProvider(_ provider: any AnalyticsProvider) {
        providers.append(provider)
    }

    /// Enable or disable analytics
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        logger.info("Analytics \(enabled ? "enabled" : "disabled")")
    }

    // MARK: - Tracking

    /// Track an event
    func track(_ event: AnalyticsEvent) {
        guard isEnabled else { return }

        logger.debug("Tracking: \(event.name) \(event.parameters)")

        for provider in providers {
            provider.track(event)
        }
    }

    /// Track a screen view
    func trackScreen(_ screen: String) {
        guard isEnabled else { return }

        logger.debug("Screen: \(screen)")

        for provider in providers {
            provider.trackScreen(screen)
        }
    }

    /// Set a user property
    func setUserProperty(_ property: String, value: String?) {
        guard isEnabled else { return }

        for provider in providers {
            provider.setUserProperty(property, value: value)
        }
    }

    // MARK: - Convenience

    /// Track recording started
    func recordingStarted(scenario: Scenario) {
        track(.recordingStarted(scenario: scenario.id))
    }

    /// Track recording completed
    func recordingCompleted(duration: TimeInterval) {
        track(.recordingCompleted(durationSeconds: Int(duration)))
    }

    /// Track feedback viewed
    func feedbackViewed(score: Int) {
        track(.feedbackViewed(overallScore: score))
    }

    /// Track error
    func trackError(_ error: any AppError) {
        track(.errorOccurred(type: String(describing: type(of: error)), recoverable: error.isRecoverable))
    }
}

// MARK: - Local Analytics Provider (Debug)

/// Local provider that logs events for debugging
final class LocalAnalyticsProvider: AnalyticsProvider, @unchecked Sendable {
    private let logger = Logger(subsystem: "com.quietcoach", category: "LocalAnalytics")
    private var eventCount = 0

    func track(_ event: AnalyticsEvent) {
        eventCount += 1
        logger.debug("[\(self.eventCount)] Event: \(event.name) params: \(event.parameters)")
    }

    func trackScreen(_ screen: String) {
        logger.debug("Screen view: \(screen)")
    }

    func setUserProperty(_ property: String, value: String?) {
        logger.debug("User property: \(property) = \(value ?? "nil")")
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

/// View modifier to track screen views
struct ScreenTrackingModifier: ViewModifier {
    let screenName: String

    func body(content: Content) -> some View {
        content
            .onAppear {
                Task { @MainActor in
                    Analytics.shared.trackScreen(screenName)
                }
            }
    }
}

extension View {
    /// Track when this view appears as a screen
    func trackScreen(_ name: String) -> some View {
        modifier(ScreenTrackingModifier(screenName: name))
    }
}
