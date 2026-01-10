// Analytics.swift
// QuietCoach
//
// Privacy-respecting analytics foundation.
// No personal data collection. All data is anonymous.

import Foundation
import OSLog
#if canImport(UIKit)
import UIKit
#endif

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

    // MARK: - Funnel Events (Critical Path)
    case firstSessionStarted
    case firstSessionCompleted(score: Int)
    case sessionAbandoned(reason: String, durationSeconds: Int)
    case widgetTapped(widgetType: String, scenarioId: String)

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
        case .firstSessionStarted: return "first_session_started"
        case .firstSessionCompleted: return "first_session_completed"
        case .sessionAbandoned: return "session_abandoned"
        case .widgetTapped: return "widget_tapped"
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

        case .firstSessionStarted:
            return [:]

        case .firstSessionCompleted(let score):
            return ["score_bucket": scoreBucket(score)]

        case .sessionAbandoned(let reason, let duration):
            return ["reason": reason, "duration_bucket": durationBucket(duration)]

        case .widgetTapped(let widgetType, let scenarioId):
            return ["widget_type": widgetType, "scenario_id": scenarioId]
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
        #else
        // Production: Add TelemetryDeck provider
        // Replace with your actual TelemetryDeck App ID
        if let appId = Bundle.main.infoDictionary?["TELEMETRYDECK_APP_ID"] as? String {
            providers.append(TelemetryDeckProvider(appID: appId))
        } else {
            // Fallback to placeholder - will log but not send
            providers.append(TelemetryDeckProvider())
        }
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

    // MARK: - Funnel Tracking

    /// Track first session started (only fires once per install)
    func trackFirstSessionStartedIfNeeded() {
        guard SessionTracker.shared.isFirstSession else { return }
        let key = "com.quietcoach.analytics.firstSessionTracked"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        track(.firstSessionStarted)
    }

    /// Track first session completed (only fires once per install)
    func trackFirstSessionCompletedIfNeeded(score: Int) {
        let key = "com.quietcoach.analytics.firstSessionCompleted"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        track(.firstSessionCompleted(score: score))
    }

    /// Track session abandonment
    func sessionAbandoned(reason: String, duration: TimeInterval) {
        track(.sessionAbandoned(reason: reason, durationSeconds: Int(duration)))
    }

    /// Track widget tap
    func widgetTapped(widgetType: String, scenarioId: String) {
        track(.widgetTapped(widgetType: widgetType, scenarioId: scenarioId))
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

// MARK: - TelemetryDeck Provider (Production)

/// Production analytics provider using TelemetryDeck
/// Privacy-focused, GDPR-compliant analytics
final class TelemetryDeckProvider: AnalyticsProvider, @unchecked Sendable {
    private let logger = Logger(subsystem: "com.quietcoach", category: "TelemetryDeck")

    /// App ID from TelemetryDeck dashboard
    /// Set this in production or via environment variable
    private let appID: String

    /// Base URL for TelemetryDeck API
    private let baseURL = URL(string: "https://nom.telemetrydeck.com/v2/")!

    /// Anonymous user identifier (consistent per install, not trackable)
    private let userIdentifier: String

    init(appID: String = "YOUR_TELEMETRYDECK_APP_ID") {
        self.appID = appID

        // Generate or retrieve anonymous user identifier
        let key = "com.quietcoach.analytics.anonymousId"
        if let existingId = UserDefaults.standard.string(forKey: key) {
            self.userIdentifier = existingId
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: key)
            self.userIdentifier = newId
        }

        logger.info("TelemetryDeck initialized with anonymous ID")
    }

    func track(_ event: AnalyticsEvent) {
        let payload = buildPayload(type: event.name, additionalPayload: event.parameters)
        sendSignal(payload)
    }

    func trackScreen(_ screen: String) {
        let payload = buildPayload(type: "screen_view", additionalPayload: ["screen": screen])
        sendSignal(payload)
    }

    func setUserProperty(_ property: String, value: String?) {
        // TelemetryDeck handles user properties via payload enrichment
        // Store locally for inclusion in future events
        let key = "com.quietcoach.analytics.property.\(property)"
        UserDefaults.standard.set(value, forKey: key)
    }

    // MARK: - Payload Building

    private func buildPayload(type: String, additionalPayload: [String: String]) -> [String: String] {
        var payload: [String: String] = [
            "appID": appID,
            "clientUser": userIdentifier,
            "type": type
        ]

        // Flatten additional payload with prefix
        for (key, value) in additionalPayload {
            payload["param_\(key)"] = value
        }

        // Add system info (non-identifying)
        #if os(iOS)
        payload["platform"] = "iOS"
        payload["systemVersion"] = ProcessInfo.processInfo.operatingSystemVersionString
        #elseif os(macOS)
        payload["platform"] = "macOS"
        payload["systemVersion"] = ProcessInfo.processInfo.operatingSystemVersionString
        #elseif os(visionOS)
        payload["platform"] = "visionOS"
        payload["systemVersion"] = ProcessInfo.processInfo.operatingSystemVersionString
        #else
        payload["platform"] = "unknown"
        payload["systemVersion"] = "unknown"
        #endif
        payload["appVersion"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        payload["buildNumber"] = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"

        // Add session info
        payload["sessionID"] = SessionTracker.shared.currentSessionId

        return payload
    }

    // MARK: - Network

    private func sendSignal(_ payload: [String: String]) {
        guard appID != "YOUR_TELEMETRYDECK_APP_ID" else {
            logger.debug("TelemetryDeck not configured - skipping signal")
            return
        }

        // Copy payload for safe sending
        let payloadCopy = payload

        Task.detached {
            do {
                var request = URLRequest(url: self.baseURL)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: [payloadCopy])

                let (_, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    // Log silently - analytics failures shouldn't disrupt user
                }
            } catch {
                // Silently fail - analytics shouldn't disrupt user experience
            }
        }
    }
}

// MARK: - Session Tracker

/// Tracks app session for analytics continuity
final class SessionTracker: @unchecked Sendable {
    static let shared = SessionTracker()

    private(set) var currentSessionId: String
    private(set) var sessionStartTime: Date
    private(set) var isFirstSession: Bool

    private init() {
        self.currentSessionId = UUID().uuidString
        self.sessionStartTime = Date()

        // Check if this is the first session ever
        let hasLaunchedKey = "com.quietcoach.analytics.hasLaunched"
        self.isFirstSession = !UserDefaults.standard.bool(forKey: hasLaunchedKey)
        UserDefaults.standard.set(true, forKey: hasLaunchedKey)
    }

    /// Start a new session (call on app foreground)
    func startNewSession() {
        currentSessionId = UUID().uuidString
        sessionStartTime = Date()
    }

    /// Get session duration in seconds
    var sessionDuration: Int {
        Int(Date().timeIntervalSince(sessionStartTime))
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
