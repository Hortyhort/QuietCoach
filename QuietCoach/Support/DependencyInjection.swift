// DependencyInjection.swift
// QuietCoach
//
// Protocol-based dependency injection for testability.
// Provides protocols for all services and a central container.

import Foundation
import SwiftUI
import SwiftData

// MARK: - Service Protocols

/// Protocol for session data access
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

/// Protocol for feature gating
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

/// Protocol for speech analysis
protocol SpeechAnalyzerProtocol: Actor {
    func requestAuthorization() async -> Bool
    var isAuthorized: Bool { get }
    func analyze(audioURL: URL, duration: TimeInterval) async throws -> SpeechAnalysisResult
}

/// Protocol for analytics tracking
@MainActor
protocol AnalyticsProtocol: AnyObject {
    func track(_ event: AnalyticsEvent)
    func trackScreen(_ screen: String)
    func setUserProperty(_ property: String, value: String?)
}

/// Protocol for network monitoring
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

/// Protocol for performance monitoring
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

/// Protocol for crash reporting
@MainActor
protocol CrashReportingProtocol: AnyObject {
    func recordError(_ error: Error, context: [String: String])
    func recordBreadcrumb(_ message: String, category: BreadcrumbCategory, data: [String: String])
    func setUserID(_ id: String?)
    func setCustomValue(_ value: String?, forKey key: String)
    func recordScreenView(_ screen: String)
}

// MARK: - App Container

/// Central dependency container for the app
/// Provides both production and mock implementations
@MainActor
final class AppContainer: ObservableObject {

    // MARK: - Shared Instance

    static let shared = AppContainer()

    // MARK: - Service Dependencies

    /// Session repository for data access
    lazy var sessionRepository: SessionRepositoryProtocol = SessionRepository()

    /// Feature gates for pro/free access
    lazy var featureGates: FeatureGatesProtocol = FeatureGates.shared

    /// Speech analyzer for audio analysis
    lazy var speechAnalyzer: SpeechAnalyzerProtocol = SpeechAnalysisEngine.shared

    /// Analytics for event tracking
    lazy var analytics: AnalyticsProtocol = Analytics.shared

    /// Network monitor for connectivity
    lazy var networkMonitor: NetworkMonitorProtocol = NetworkMonitor.shared

    /// Performance monitor for timing
    lazy var performanceMonitor: PerformanceMonitorProtocol = PerformanceMonitor.shared

    /// Crash reporting
    lazy var crashReporting: CrashReportingProtocol = CrashReporting.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Testing Support

    #if DEBUG
    /// Create a container with custom dependencies for testing
    static func forTesting(
        sessionRepository: SessionRepositoryProtocol? = nil,
        featureGates: FeatureGatesProtocol? = nil,
        speechAnalyzer: SpeechAnalyzerProtocol? = nil,
        analytics: AnalyticsProtocol? = nil,
        networkMonitor: NetworkMonitorProtocol? = nil,
        performanceMonitor: PerformanceMonitorProtocol? = nil,
        crashReporting: CrashReportingProtocol? = nil
    ) -> AppContainer {
        let container = AppContainer()

        if let repo = sessionRepository {
            container.sessionRepository = repo
        }
        if let gates = featureGates {
            container.featureGates = gates
        }
        if let analyzer = speechAnalyzer {
            container.speechAnalyzer = analyzer
        }
        if let tracker = analytics {
            container.analytics = tracker
        }
        if let monitor = networkMonitor {
            container.networkMonitor = monitor
        }
        if let perf = performanceMonitor {
            container.performanceMonitor = perf
        }
        if let crash = crashReporting {
            container.crashReporting = crash
        }

        return container
    }

    /// Override a specific dependency
    func override<T>(_ keyPath: ReferenceWritableKeyPath<AppContainer, T>, with value: T) {
        self[keyPath: keyPath] = value
    }
    #endif
}

// MARK: - Protocol Conformances

extension SessionRepository: SessionRepositoryProtocol {}
extension FeatureGates: FeatureGatesProtocol {}
extension SpeechAnalysisEngine: SpeechAnalyzerProtocol {}
extension Analytics: AnalyticsProtocol {}
extension NetworkMonitor: NetworkMonitorProtocol {}
extension PerformanceMonitor: PerformanceMonitorProtocol {}
extension CrashReporting: CrashReportingProtocol {}

// MARK: - Environment Key

@MainActor
private enum AppContainerKey: EnvironmentKey {
    nonisolated(unsafe) static var defaultValue: AppContainer = {
        // This is safe because AppContainer.shared is only accessed on MainActor
        MainActor.assumeIsolated { AppContainer.shared }
    }()
}

extension EnvironmentValues {
    var appContainer: AppContainer {
        get { self[AppContainerKey.self] }
        set { self[AppContainerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Inject a custom app container (useful for testing/previews)
    func appContainer(_ container: AppContainer) -> some View {
        environment(\.appContainer, container)
    }
}

// MARK: - Injected Property Wrapper

/// Property wrapper for easy dependency injection in views
@propertyWrapper
struct Injected<T> {
    private let keyPath: KeyPath<AppContainer, T>

    init(_ keyPath: KeyPath<AppContainer, T>) {
        self.keyPath = keyPath
    }

    @MainActor
    var wrappedValue: T {
        AppContainer.shared[keyPath: keyPath]
    }
}

// MARK: - Mock Implementations for Testing

#if DEBUG

// MARK: - Mock Session Repository

@MainActor
final class MockSessionRepository: SessionRepositoryProtocol {
    var sessions: [RehearsalSession] = []
    var isLoaded: Bool = true
    var sessionCount: Int { sessions.count }
    var visibleSessions: [RehearsalSession] { sessions }
    var recentSessions: [RehearsalSession] { Array(sessions.prefix(3)) }

    // Track method calls for verification
    var configureCallCount = 0
    var fetchCallCount = 0
    var createCallCount = 0
    var deleteCallCount = 0

    func configure(with context: ModelContext) {
        configureCallCount += 1
    }

    func fetchSessions() {
        fetchCallCount += 1
    }

    func createSession(
        scenarioId: String,
        duration: TimeInterval,
        audioFileName: String,
        scores: FeedbackScores,
        coachNotes: [CoachNote],
        tryAgainFocus: TryAgainFocus,
        metrics: AudioMetrics
    ) -> RehearsalSession {
        createCallCount += 1
        let session = RehearsalSession(
            scenarioId: scenarioId,
            duration: duration,
            audioFileName: audioFileName
        )
        session.scores = scores
        session.coachNotes = coachNotes
        sessions.insert(session, at: 0)
        return session
    }

    func deleteSession(_ session: RehearsalSession) {
        deleteCallCount += 1
        sessions.removeAll { $0.id == session.id }
    }

    func deleteAllSessions() {
        deleteCallCount += 1
        sessions.removeAll()
    }

    func sessions(for scenarioId: String) -> [RehearsalSession] {
        sessions.filter { $0.scenarioId == scenarioId }
    }

    func previousSession(for scenarioId: String, before session: RehearsalSession) -> RehearsalSession? {
        nil
    }

    func bestScore(for scenarioId: String) -> Int? {
        sessions(for: scenarioId).compactMap { $0.scores?.overall }.max()
    }

    func exportAllData() -> Data? {
        nil
    }
}

// MARK: - Mock Feature Gates

@MainActor
final class MockFeatureGates: FeatureGatesProtocol {
    var isPro: Bool = false
    var isLoaded: Bool = true
    var hasUnlimitedHistory: Bool { isPro }
    var maxVisibleSessions: Int { isPro ? Int.max : 3 }
    var hasAdvancedFeedback: Bool { isPro }
    var subscriptions: SubscriptionManager { SubscriptionManager() }

    func canAccessScenario(_ scenario: Scenario) -> Bool {
        !scenario.isPro || isPro
    }

    func verifySubscriptionStatus() async {}

    func updateProStatus(_ newStatus: Bool) {
        isPro = newStatus
    }

    func restorePurchases() async {}
}

// MARK: - Mock Speech Analyzer

actor MockSpeechAnalyzer: SpeechAnalyzerProtocol {
    var isAuthorized: Bool = true
    var mockResult: SpeechAnalysisResult?
    var shouldFail: Bool = false

    func requestAuthorization() async -> Bool {
        isAuthorized
    }

    func analyze(audioURL: URL, duration: TimeInterval) async throws -> SpeechAnalysisResult {
        if shouldFail {
            throw SpeechAnalysisError.recognizerUnavailable
        }

        if let result = mockResult {
            return result
        }

        // Return a default mock result using actual struct types
        return SpeechAnalysisResult(
            transcription: TranscriptionResult(
                text: "This is a mock transcription for testing purposes.",
                segments: []
            ),
            clarity: ClarityAnalysis(
                fillerWordCount: 1,
                fillerWords: ["um"],
                repeatedWordCount: 0,
                incompleteSentenceCount: 0,
                averageWordLength: 4.5,
                lowConfidenceSegmentCount: 0,
                totalWordCount: 8
            ),
            pacing: PacingAnalysis(
                wordsPerMinute: 140,
                totalWordCount: 8,
                totalPauseCount: 2,
                shortPauses: 1,
                mediumPauses: 1,
                longPauses: 0,
                averagePauseDuration: 0.5,
                averageSentenceLength: 8.0,
                duration: duration
            ),
            confidence: ConfidenceAnalysis(
                hedgingPhraseCount: 0,
                hedgingPhrases: [],
                questionWordCount: 0,
                weakOpenerCount: 0,
                apologeticPhraseCount: 0,
                assertivePhraseCount: 1,
                totalWordCount: 8
            ),
            tone: ToneAnalysis(
                sentimentScore: 0.5,
                positiveWordCount: 1,
                negativeWordCount: 0,
                contractionCount: 0,
                formalPhraseCount: 0,
                sentenceCount: 1
            )
        )
    }
}

// MARK: - Mock Analytics

@MainActor
final class MockAnalytics: AnalyticsProtocol {
    var trackedEvents: [AnalyticsEvent] = []
    var trackedScreens: [String] = []
    var userProperties: [String: String?] = [:]

    func track(_ event: AnalyticsEvent) {
        trackedEvents.append(event)
    }

    func trackScreen(_ screen: String) {
        trackedScreens.append(screen)
    }

    func setUserProperty(_ property: String, value: String?) {
        userProperties[property] = value
    }
}

// MARK: - Mock Network Monitor

@MainActor
final class MockNetworkMonitor: NetworkMonitorProtocol {
    var status: NetworkStatus = .connected
    var connectionType: NetworkMonitor.ConnectionType = .wifi
    var isExpensive: Bool = false
    var isConstrained: Bool = false

    func withRetry<T>(
        maxAttempts: Int = 3,
        initialDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        operation: () async throws -> T
    ) async throws -> T {
        try await operation()
    }
}

// MARK: - Mock Performance Monitor

@MainActor
final class MockPerformanceMonitor: PerformanceMonitorProtocol {
    var isEnabled: Bool = true
    var spans: [String: PerformanceSpan] = [:]
    var memoryUsageMB: Double = 100.0

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    func startSpan(_ name: String, category: PerformanceCategory) -> PerformanceSpan {
        let span = PerformanceSpan(name: name, category: category)
        spans[name] = span
        return span
    }

    func endSpan(_ name: String, metadata: [String: String] = [:]) {
        spans[name]?.finish()
    }

    func measure<T>(_ name: String, category: PerformanceCategory, operation: () throws -> T) rethrows -> T {
        try operation()
    }

    func measureAsync<T>(_ name: String, category: PerformanceCategory, operation: () async throws -> T) async rethrows -> T {
        try await operation()
    }

    func logMemoryState(_ context: String) {}
}

// MARK: - Mock Crash Reporting

@MainActor
final class MockCrashReporting: CrashReportingProtocol {
    var recordedErrors: [(Error, [String: String])] = []
    var breadcrumbs: [(String, BreadcrumbCategory, [String: String])] = []
    var screenViews: [String] = []

    func recordError(_ error: Error, context: [String: String] = [:]) {
        recordedErrors.append((error, context))
    }

    func recordBreadcrumb(_ message: String, category: BreadcrumbCategory = .navigation, data: [String: String] = [:]) {
        breadcrumbs.append((message, category, data))
    }

    func setUserID(_ id: String?) {}
    func setCustomValue(_ value: String?, forKey key: String) {}
    func recordScreenView(_ screen: String) {
        screenViews.append(screen)
    }
}

#endif
