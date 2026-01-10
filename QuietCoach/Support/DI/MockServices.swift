// MockServices.swift
// QuietCoach
//
// Mock implementations for testing and previews.

#if DEBUG
import Foundation
import SwiftData

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
        // Return serialized sessions as JSON
        guard !sessions.isEmpty else { return nil }
        let exportData = sessions.map { session in
            [
                "id": session.id.uuidString,
                "scenarioId": session.scenarioId,
                "duration": session.duration,
                "createdAt": session.createdAt.timeIntervalSince1970
            ] as [String: Any]
        }
        return try? JSONSerialization.data(withJSONObject: exportData)
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

        // Return a default mock result
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
