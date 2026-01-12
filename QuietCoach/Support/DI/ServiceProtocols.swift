// ServiceProtocols.swift
// QuietCoach
//
// Protocol definitions for dependency injection.
// Defines the contracts for all app services.

import Foundation
import SwiftUI
import SwiftData

// MARK: - Session Repository Protocol

@MainActor
protocol SessionRepositoryProtocol: AnyObject {
    var sessions: [RehearsalSession] { get }
    var isLoaded: Bool { get }
    var sessionCount: Int { get }
    var visibleSessions: [RehearsalSession] { get }
    var recentSessions: [RehearsalSession] { get }

    func configure(with context: ModelContext)
    func fetchSessions()
    func createSession(
        scenarioId: String,
        duration: TimeInterval,
        audioFileName: String,
        scores: FeedbackScores,
        coachNotes: [CoachNote],
        tryAgainFocus: TryAgainFocus,
        metrics: AudioMetrics
    ) -> RehearsalSession
    func deleteSession(_ session: RehearsalSession)
    func deleteAllSessions()
    func sessions(for scenarioId: String) -> [RehearsalSession]
    func previousSession(for scenarioId: String, before session: RehearsalSession) -> RehearsalSession?
    func bestScore(for scenarioId: String) -> Int?
    func exportAllData() -> Data?
}

// MARK: - Feature Gates Protocol

@MainActor
protocol FeatureGatesProtocol: AnyObject {
    var isPro: Bool { get }
    var isLoaded: Bool { get }
    var hasUnlimitedHistory: Bool { get }
    var maxVisibleSessions: Int { get }
    var hasAdvancedFeedback: Bool { get }
    var subscriptions: SubscriptionManager { get }

    func canAccessScenario(_ scenario: Scenario) -> Bool
    func verifySubscriptionStatus() async
    func updateProStatus(_ newStatus: Bool)
    func restorePurchases() async
}

// MARK: - Speech Analyzer Protocol

protocol SpeechAnalyzerProtocol: Actor {
    func requestAuthorization() async -> Bool
    var isAuthorized: Bool { get }
    func analyze(
        audioURL: URL,
        duration: TimeInterval,
        profile: ScoringProfile
    ) async throws -> SpeechAnalysisResult
}

// MARK: - Analytics Protocol

@MainActor
protocol AnalyticsProtocol: AnyObject {
    func track(_ event: AnalyticsEvent)
    func trackScreen(_ screen: String)
    func setUserProperty(_ property: String, value: String?)
}

// MARK: - Network Monitor Protocol

@MainActor
protocol NetworkMonitorProtocol: AnyObject {
    var status: NetworkStatus { get }
    var connectionType: NetworkMonitor.ConnectionType { get }
    var isExpensive: Bool { get }
    var isConstrained: Bool { get }

    func withRetry<T>(
        maxAttempts: Int,
        initialDelay: TimeInterval,
        maxDelay: TimeInterval,
        operation: () async throws -> T
    ) async throws -> T
}

// MARK: - Performance Monitor Protocol

@MainActor
protocol PerformanceMonitorProtocol: AnyObject {
    var isEnabled: Bool { get }

    func setEnabled(_ enabled: Bool)
    func startSpan(_ name: String, category: PerformanceCategory) -> PerformanceSpan
    func endSpan(_ name: String, metadata: [String: String])
    func measure<T>(_ name: String, category: PerformanceCategory, operation: () throws -> T) rethrows -> T
    func measureAsync<T>(_ name: String, category: PerformanceCategory, operation: () async throws -> T) async rethrows -> T
    var memoryUsageMB: Double { get }
    func logMemoryState(_ context: String)
}

// MARK: - Crash Reporting Protocol

@MainActor
protocol CrashReportingProtocol: AnyObject {
    func recordError(_ error: Error, context: [String: String])
    func recordBreadcrumb(_ message: String, category: BreadcrumbCategory, data: [String: String])
    func setUserID(_ id: String?)
    func setCustomValue(_ value: String?, forKey key: String)
    func recordScreenView(_ screen: String)
}

// MARK: - Protocol Conformances

extension SessionRepository: SessionRepositoryProtocol {}
extension FeatureGates: FeatureGatesProtocol {}
extension SpeechAnalysisEngine: SpeechAnalyzerProtocol {}
extension Analytics: AnalyticsProtocol {}
extension NetworkMonitor: NetworkMonitorProtocol {}
extension PerformanceMonitor: PerformanceMonitorProtocol {}
extension CrashReporting: CrashReportingProtocol {}
