// CoachNote.swift
// QuietCoach
//
// Actionable coaching feedback. We limit to 2-3 notes per session
// to avoid overwhelming the user.

import Foundation

struct CoachNote: Identifiable, Codable, Hashable {

    // MARK: - Properties

    let id: UUID
    let title: String
    let body: String
    let type: NoteType
    let priority: Priority

    // MARK: - Types

    enum NoteType: String, Codable {
        case scenario   // Scenario-specific coaching
        case pacing     // Rhythm and timing
        case intensity  // Volume and energy
        case general    // General delivery advice
    }

    enum Priority: Int, Codable, Comparable {
        case low = 0
        case medium = 1
        case high = 2

        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        type: NoteType,
        priority: Priority = .medium
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.type = type
        self.priority = priority
    }
}

// MARK: - Try Again Focus

/// A single, focused goal for the next rehearsal attempt
struct TryAgainFocus: Codable, Hashable {

    /// The specific goal to focus on
    let goal: String

    /// Brief explanation of why this matters
    let reason: String

    static let `default` = TryAgainFocus(
        goal: "Focus on your opening line.",
        reason: "A strong start sets the tone for everything after."
    )
}

// MARK: - Coach Note Templates

extension CoachNote {

    // MARK: - Pacing Notes

    static func tooFast() -> CoachNote {
        CoachNote(
            title: "Slow down slightly",
            body: "Try adding a breath between thoughts. Let your words land.",
            type: .pacing,
            priority: .high
        )
    }

    static func tooSlow() -> CoachNote {
        CoachNote(
            title: "Pick up the pace",
            body: "Maintain momentum while being deliberate. Silence is okay, but keep moving.",
            type: .pacing,
            priority: .medium
        )
    }

    static func addPauses() -> CoachNote {
        CoachNote(
            title: "Add strategic pauses",
            body: "Pauses after key points give them impact. Try pausing after your main ask.",
            type: .pacing,
            priority: .medium
        )
    }

    // MARK: - Intensity Notes

    static func tooManySpikes() -> CoachNote {
        CoachNote(
            title: "Smooth out intensity spikes",
            body: "Try to stay even, especially on key points. Calm is powerful.",
            type: .intensity,
            priority: .high
        )
    }

    static func inconsistentVolume() -> CoachNote {
        CoachNote(
            title: "Aim for consistency",
            body: "Steady volume throughout sounds more assured. Pick a level and hold it.",
            type: .intensity,
            priority: .medium
        )
    }

    static func speakUp() -> CoachNote {
        CoachNote(
            title: "Project more",
            body: "Imagine speaking to someone across a table. A bit louder sounds more confident.",
            type: .intensity,
            priority: .high
        )
    }

    // MARK: - General Notes

    static func fillTheSpace() -> CoachNote {
        CoachNote(
            title: "Fill the space",
            body: "It's okay to pause, but keep moving forward. Own the conversation.",
            type: .general,
            priority: .medium
        )
    }

    static func strongOpening() -> CoachNote {
        CoachNote(
            title: "Lead with your point",
            body: "State your main message in the first sentence. Don't bury the lede.",
            type: .general,
            priority: .high
        )
    }
}
