// SessionRepository.swift
// QuietCoach
//
// Central data access layer for rehearsal sessions.

import Foundation
import SwiftData
import OSLog

@Observable
@MainActor
final class SessionRepository {

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.quietcoach", category: "SessionRepository")
    private var modelContext: ModelContext?
    private let fileStore = FileStore.shared

    private(set) var sessions: [RehearsalSession] = []
    private(set) var isLoaded = false

    // Pagination support
    private let pageSize = 20
    private(set) var hasMoreSessions = true
    private(set) var isLoadingMore = false

    // MARK: - Initialization

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        if modelContext != nil {
            fetchSessions()
        }
    }

    /// Placeholder for SwiftUI initialization
    static let placeholder = SessionRepository()

    /// Configure with model context after view appears
    func configure(with context: ModelContext) {
        guard modelContext == nil else { return }
        modelContext = context
        fetchSessions()
    }

    // MARK: - Fetch Operations

    /// Fetch initial sessions with pagination, sorted by date (newest first)
    func fetchSessions() {
        guard let modelContext else {
            logger.warning("ModelContext not available for fetch")
            return
        }

        var descriptor = FetchDescriptor<RehearsalSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = pageSize

        do {
            sessions = try modelContext.fetch(descriptor)
            hasMoreSessions = sessions.count >= pageSize
            isLoaded = true
            logger.info("Fetched \(self.sessions.count) sessions (initial page)")
        } catch {
            logger.error("Failed to fetch sessions: \(error.localizedDescription)")
            sessions = []
        }
    }

    /// Load more sessions for infinite scroll
    func loadMoreSessions() {
        guard let modelContext, hasMoreSessions, !isLoadingMore else { return }

        isLoadingMore = true

        var descriptor = FetchDescriptor<RehearsalSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchOffset = sessions.count
        descriptor.fetchLimit = pageSize

        do {
            let moreSessions = try modelContext.fetch(descriptor)
            sessions.append(contentsOf: moreSessions)
            hasMoreSessions = moreSessions.count >= pageSize
            logger.info("Loaded \(moreSessions.count) more sessions (total: \(self.sessions.count))")
        } catch {
            logger.error("Failed to load more sessions: \(error.localizedDescription)")
        }

        isLoadingMore = false
    }

    /// Fetch all sessions (for operations that need complete data)
    func fetchAllSessions() {
        guard let modelContext else { return }

        let descriptor = FetchDescriptor<RehearsalSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            sessions = try modelContext.fetch(descriptor)
            hasMoreSessions = false
            logger.info("Fetched all \(self.sessions.count) sessions")
        } catch {
            logger.error("Failed to fetch all sessions: \(error.localizedDescription)")
        }
    }

    // MARK: - Create Operations

    /// Create and save a new session
    @discardableResult
    func createSession(
        scenarioId: String,
        duration: TimeInterval,
        audioFileName: String,
        scores: FeedbackScores,
        coachNotes: [CoachNote],
        tryAgainFocus: TryAgainFocus,
        metrics: AudioMetrics
    ) -> RehearsalSession {
        let session = RehearsalSession(
            scenarioId: scenarioId,
            duration: duration,
            audioFileName: audioFileName
        )

        session.scores = scores
        session.coachNotes = coachNotes
        session.tryAgainFocus = tryAgainFocus
        session.metrics = metrics

        modelContext?.insert(session)
        saveContext()
        fetchSessions()

        logger.info("Created session for scenario: \(scenarioId)")
        return session
    }

    // MARK: - Delete Operations

    /// Delete a single session and its audio file
    func deleteSession(_ session: RehearsalSession) {
        fileStore.deleteAudioFile(named: session.audioFileName)
        modelContext?.delete(session)
        saveContext()
        fetchSessions()

        logger.info("Deleted session: \(session.id)")
    }

    /// Delete all sessions and audio files
    func deleteAllSessions() {
        guard let modelContext else {
            sessions.removeAll()
            hasMoreSessions = false
            isLoadingMore = false
            logger.warning("ModelContext not available for deleteAllSessions")
            return
        }

        do {
            let descriptor = FetchDescriptor<RehearsalSession>()
            let allSessions = try modelContext.fetch(descriptor)

            fileStore.deleteAllAudioFiles()

            for session in allSessions {
                modelContext.delete(session)
            }

            try modelContext.save()

            sessions.removeAll()
            hasMoreSessions = false
            isLoadingMore = false
            isLoaded = true

            logger.info("Deleted all sessions (\(allSessions.count) records)")
        } catch {
            logger.error("Failed to delete all sessions: \(error.localizedDescription)")
        }
    }

    // MARK: - Query Operations

    /// Total number of sessions
    var sessionCount: Int {
        sessions.count
    }

    /// Sessions visible to the current user (respects Pro limits)
    var visibleSessions: [RehearsalSession] {
        let limit = FeatureGates.shared.maxVisibleSessions
        return Array(sessions.prefix(limit))
    }

    /// Recent sessions (for quick access)
    var recentSessions: [RehearsalSession] {
        Array(sessions.prefix(Constants.Limits.freeSessionLimit))
    }

    /// Sessions for a specific scenario
    func sessions(for scenarioId: String) -> [RehearsalSession] {
        sessions.filter { $0.scenarioId == scenarioId }
    }

    /// Fetch a specific session by ID
    func session(with id: UUID) -> RehearsalSession? {
        if let modelContext {
            let descriptor = FetchDescriptor<RehearsalSession>(
                predicate: #Predicate { $0.id == id }
            )
            do {
                return try modelContext.fetch(descriptor).first
            } catch {
                logger.error("Failed to fetch session \(id): \(error.localizedDescription)")
            }
        }
        return sessions.first { $0.id == id }
    }

    /// Get the previous session for comparison
    func previousSession(
        for scenarioId: String,
        before session: RehearsalSession
    ) -> RehearsalSession? {
        sessions.first {
            $0.scenarioId == scenarioId && $0.createdAt < session.createdAt
        }
    }

    /// Best score for a scenario
    func bestScore(for scenarioId: String) -> Int? {
        sessions(for: scenarioId)
            .compactMap { $0.scores?.overall }
            .max()
    }

    /// Baseline metrics for personalization (rolling average)
    func baselineMetrics(for scenarioId: String, limit: Int = 5) -> BaselineMetrics? {
        let recentSessions: [RehearsalSession]

        if let modelContext {
            var descriptor = FetchDescriptor<RehearsalSession>(
                predicate: #Predicate { $0.scenarioId == scenarioId },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            descriptor.fetchLimit = limit

            do {
                recentSessions = try modelContext.fetch(descriptor)
            } catch {
                logger.error("Failed to fetch baseline sessions: \(error.localizedDescription)")
                recentSessions = Array(sessions(for: scenarioId).prefix(limit))
            }
        } else {
            recentSessions = Array(sessions(for: scenarioId).prefix(limit))
        }

        let recentMetrics = recentSessions.compactMap { $0.metrics }

        guard !recentMetrics.isEmpty else { return nil }

        let analyzed = recentMetrics.map { AudioMetricsAnalyzer.analyze($0) }

        let segmentsPerMinute = average(analyzed.map { $0.segmentsPerMinute })
        let averageLevel = average(analyzed.map { $0.averageLevel })
        let silenceRatio = average(analyzed.map { $0.silenceRatio })
        let volumeStability = average(analyzed.map { $0.volumeStability })

        let wordsPerMinute = average(
            recentSessions.compactMap { session in
                guard let transcription = session.transcription else { return nil }
                let wordCount = transcription.split(separator: " ").count
                guard session.duration > 0 else { return nil }
                return Double(wordCount) / (session.duration / 60)
            }
        )

        return BaselineMetrics(
            segmentsPerMinute: segmentsPerMinute,
            averageLevel: averageLevel,
            silenceRatio: silenceRatio,
            volumeStability: volumeStability,
            wordsPerMinute: wordsPerMinute
        )
    }

    // MARK: - Export

    /// Export all session data as JSON
    func exportAllData() -> Data? {
        let exportSessions: [RehearsalSession]

        if let modelContext {
            var descriptor = FetchDescriptor<RehearsalSession>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )

            do {
                exportSessions = try modelContext.fetch(descriptor)
            } catch {
                logger.error("Failed to fetch sessions for export: \(error.localizedDescription)")
                exportSessions = sessions
            }
        } else {
            exportSessions = sessions
        }

        let exportData = exportSessions.map { session -> [String: Any] in
            var data: [String: Any] = [
                "id": session.id.uuidString,
                "scenario": session.scenarioId,
                "date": ISO8601DateFormatter().string(from: session.createdAt),
                "duration": session.duration
            ]

            if let scores = session.scores {
                data["scores"] = [
                    "clarity": scores.clarity,
                    "pacing": scores.pacing,
                    "tone": scores.tone,
                    "confidence": scores.confidence,
                    "overall": scores.overall
                ]
            }

            if let anchor = session.anchorLine {
                data["anchorLine"] = anchor
            }

            return data
        }

        return try? JSONSerialization.data(
            withJSONObject: exportData,
            options: .prettyPrinted
        )
    }

    // MARK: - Private Helpers

    private func average(_ values: [Float]) -> Float? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Float(values.count)
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func saveContext() {
        guard let modelContext else { return }

        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save context: \(error.localizedDescription)")
        }
    }
}
