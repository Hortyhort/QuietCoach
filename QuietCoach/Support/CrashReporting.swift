// CrashReporting.swift
// QuietCoach
//
// Crash reporting abstraction with breadcrumb tracking.
// Supports various backends (Firebase Crashlytics, Sentry, etc.)

import Foundation
import OSLog

// MARK: - Crash Reporter Protocol

/// Protocol for crash reporting backends
protocol CrashReporter: Sendable {
    /// Log a non-fatal error
    func recordError(_ error: Error, context: [String: String])

    /// Log a breadcrumb for debugging context
    func recordBreadcrumb(_ message: String, category: String, data: [String: String])

    /// Set a user identifier (anonymous)
    func setUserID(_ id: String?)

    /// Set a custom key-value pair
    func setCustomValue(_ value: String?, forKey key: String)
}

// MARK: - Crash Reporting Manager

/// Centralized crash reporting manager
@MainActor
final class CrashReporting {
    static let shared = CrashReporting()

    private var reporters: [any CrashReporter] = []
    private let logger = Logger(subsystem: "com.quietcoach", category: "CrashReporting")
    private var isEnabled: Bool

    // Breadcrumb history for debugging
    private var recentBreadcrumbs: [Breadcrumb] = []
    private let maxBreadcrumbs = 100

    private init() {
        let storedPreference = UserDefaults.standard.object(forKey: Constants.SettingsKeys.crashReportingEnabled) as? Bool
        isEnabled = storedPreference ?? false
        #if DEBUG
        reporters.append(LocalCrashReporter())
        #endif
    }

    // MARK: - Configuration

    /// Add a crash reporter backend
    func addReporter(_ reporter: any CrashReporter) {
        reporters.append(reporter)
    }

    /// Enable or disable crash reporting
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    /// Set anonymous user identifier
    func setUserID(_ id: String?) {
        guard isEnabled else { return }
        for reporter in reporters {
            reporter.setUserID(id)
        }
    }

    // MARK: - Error Recording

    /// Record a non-fatal error
    func recordError(_ error: Error, context: [String: String] = [:]) {
        guard isEnabled else { return }

        logger.error("Recording error: \(error.localizedDescription)")

        // Add breadcrumbs as context
        var fullContext = context
        fullContext["breadcrumb_count"] = String(recentBreadcrumbs.count)

        for reporter in reporters {
            reporter.recordError(error, context: fullContext)
        }
    }

    /// Record an AppError with its context
    func recordAppError(_ error: any AppError, file: String = #file, function: String = #function, line: Int = #line) {
        let context: [String: String] = [
            "error_type": String(describing: type(of: error)),
            "title": error.title,
            "recoverable": String(error.isRecoverable),
            "file": URL(fileURLWithPath: file).lastPathComponent,
            "function": function,
            "line": String(line)
        ]

        recordError(error, context: context)
    }

    // MARK: - Breadcrumbs

    /// Record a breadcrumb for debugging context
    func recordBreadcrumb(
        _ message: String,
        category: BreadcrumbCategory = .navigation,
        data: [String: String] = [:]
    ) {
        guard isEnabled else { return }

        let breadcrumb = Breadcrumb(
            message: message,
            category: category,
            data: data,
            timestamp: Date()
        )

        recentBreadcrumbs.append(breadcrumb)
        if recentBreadcrumbs.count > maxBreadcrumbs {
            recentBreadcrumbs.removeFirst()
        }

        logger.debug("Breadcrumb: [\(category.rawValue)] \(message)")

        for reporter in reporters {
            reporter.recordBreadcrumb(message, category: category.rawValue, data: data)
        }
    }

    /// Record screen navigation
    func recordScreenView(_ screen: String) {
        recordBreadcrumb("Viewed \(screen)", category: .navigation)
    }

    /// Record user action
    func recordUserAction(_ action: String, details: [String: String] = [:]) {
        recordBreadcrumb(action, category: .userAction, data: details)
    }

    /// Record state change
    func recordStateChange(_ state: String, details: [String: String] = [:]) {
        recordBreadcrumb(state, category: .stateChange, data: details)
    }

    // MARK: - Custom Values

    /// Set a custom value for crash context
    func setCustomValue(_ value: String?, forKey key: String) {
        guard isEnabled else { return }
        for reporter in reporters {
            reporter.setCustomValue(value, forKey: key)
        }
    }

    /// Set app version info
    func setAppVersion() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        setCustomValue("\(version) (\(build))", forKey: "app_version")
    }

    /// Set subscription status for context
    func setSubscriptionStatus(isPro: Bool) {
        setCustomValue(isPro ? "pro" : "free", forKey: "subscription_status")
    }

    // MARK: - Debug

    /// Get recent breadcrumbs for debugging
    var debugBreadcrumbs: [Breadcrumb] {
        recentBreadcrumbs
    }
}

// MARK: - Breadcrumb

struct Breadcrumb: Identifiable, Sendable {
    let id = UUID()
    let message: String
    let category: BreadcrumbCategory
    let data: [String: String]
    let timestamp: Date
}

enum BreadcrumbCategory: String, Sendable {
    case navigation = "navigation"
    case userAction = "user_action"
    case stateChange = "state_change"
    case network = "network"
    case audio = "audio"
    case error = "error"
}

// MARK: - Local Crash Reporter (Debug)

/// Local reporter that logs errors for debugging
final class LocalCrashReporter: CrashReporter, @unchecked Sendable {
    private let logger = Logger(subsystem: "com.quietcoach", category: "LocalCrashReporter")
    private var errorCount = 0

    func recordError(_ error: Error, context: [String: String]) {
        errorCount += 1
        logger.error("[\(self.errorCount)] Error: \(error.localizedDescription)")
        for (key, value) in context {
            logger.error("  \(key): \(value)")
        }
    }

    func recordBreadcrumb(_ message: String, category: String, data: [String: String]) {
        // Already logged by manager
    }

    func setUserID(_ id: String?) {
        logger.debug("User ID set: \(id ?? "nil")")
    }

    func setCustomValue(_ value: String?, forKey key: String) {
        logger.debug("Custom value: \(key) = \(value ?? "nil")")
    }
}

// MARK: - Integration Helpers

extension CrashReporting {

    /// Configure crash reporting on app launch
    func configure() {
        setAppVersion()
        recordBreadcrumb("App launched", category: .stateChange)
    }

    /// Record recording session context
    func setRecordingContext(scenarioId: String, duration: TimeInterval) {
        setCustomValue(scenarioId, forKey: "last_scenario")
        setCustomValue(String(Int(duration)), forKey: "last_recording_duration")
    }
}
