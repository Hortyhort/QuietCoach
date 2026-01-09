// RehearsalSession.swift
// QuietCoach
//
// The persisted record of a rehearsal. Uses SwiftData for local storage.

import Foundation
import SwiftData

@Model
final class RehearsalSession: Hashable {

    // MARK: - Hashable

    static func == (lhs: RehearsalSession, rhs: RehearsalSession) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Stored Properties

    /// Unique identifier
    var id: UUID

    /// ID of the scenario practiced
    var scenarioId: String

    /// When the session was recorded
    var createdAt: Date

    /// Recording duration in seconds
    var duration: TimeInterval

    /// Filename of the audio recording
    var audioFileName: String

    /// Encoded feedback scores
    var scoresData: Data?

    /// Encoded coach notes
    var coachNotesData: Data?

    /// Encoded try again focus
    var tryAgainFocusData: Data?

    /// Encoded audio metrics (for potential future analysis)
    var metricsData: Data?

    /// User's personal anchor line (optional)
    var anchorLine: String?

    // MARK: - Initialization

    init(
        scenarioId: String,
        duration: TimeInterval,
        audioFileName: String
    ) {
        self.id = UUID()
        self.scenarioId = scenarioId
        self.createdAt = Date()
        self.duration = duration
        self.audioFileName = audioFileName
    }

    // MARK: - Computed Properties

    /// The scenario for this session (if still available)
    var scenario: Scenario? {
        Scenario.scenario(for: scenarioId)
    }

    /// Decoded feedback scores
    var scores: FeedbackScores? {
        get {
            guard let data = scoresData else { return nil }
            return try? JSONDecoder().decode(FeedbackScores.self, from: data)
        }
        set {
            scoresData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Decoded coach notes
    var coachNotes: [CoachNote] {
        get {
            guard let data = coachNotesData else { return [] }
            return (try? JSONDecoder().decode([CoachNote].self, from: data)) ?? []
        }
        set {
            coachNotesData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Decoded try again focus
    var tryAgainFocus: TryAgainFocus? {
        get {
            guard let data = tryAgainFocusData else { return nil }
            return try? JSONDecoder().decode(TryAgainFocus.self, from: data)
        }
        set {
            tryAgainFocusData = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Formatting

    /// Duration formatted as "M:SS"
    var formattedDuration: String {
        duration.qcFormattedDuration
    }

    /// Date formatted for display
    var formattedDate: String {
        createdAt.qcRelativeString
    }
}
