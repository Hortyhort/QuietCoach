// AchievementManager.swift
// QuietCoach
//
// Achievement badges to celebrate progress.
// Meaningful milestones, not gamification noise.

import Foundation
import SwiftUI
import OSLog

// MARK: - Achievement

struct Achievement: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: Color
    let category: Category

    enum Category: String, CaseIterable {
        case practice = "Practice"
        case streak = "Streak"
        case mastery = "Mastery"
        case exploration = "Exploration"
    }
}

// MARK: - Achievement Definitions

extension Achievement {

    // MARK: - Practice Achievements

    static let firstSession = Achievement(
        id: "first-session",
        title: "First Step",
        description: "Completed your first rehearsal",
        icon: "flag.fill",
        color: .qcMoodReady,
        category: .practice
    )

    static let tenSessions = Achievement(
        id: "ten-sessions",
        title: "Getting Serious",
        description: "Completed 10 rehearsals",
        icon: "star.fill",
        color: .qcAccent,
        category: .practice
    )

    static let fiftySessions = Achievement(
        id: "fifty-sessions",
        title: "Dedicated Practitioner",
        description: "Completed 50 rehearsals",
        icon: "star.circle.fill",
        color: .qcMoodCelebration,
        category: .practice
    )

    static let hundredSessions = Achievement(
        id: "hundred-sessions",
        title: "Master Communicator",
        description: "Completed 100 rehearsals",
        icon: "crown.fill",
        color: .orange,
        category: .practice
    )

    // MARK: - Streak Achievements

    static let sevenDayStreak = Achievement(
        id: "seven-day-streak",
        title: "Week Warrior",
        description: "Maintained a 7-day practice streak",
        icon: "flame.fill",
        color: .orange,
        category: .streak
    )

    static let thirtyDayStreak = Achievement(
        id: "thirty-day-streak",
        title: "Habit Former",
        description: "Maintained a 30-day practice streak",
        icon: "flame.circle.fill",
        color: .red,
        category: .streak
    )

    // MARK: - Mastery Achievements

    static let firstNinety = Achievement(
        id: "first-ninety",
        title: "Excellence",
        description: "Scored 90 or above on a rehearsal",
        icon: "trophy.fill",
        color: .qcMoodCelebration,
        category: .mastery
    )

    static let perfectScore = Achievement(
        id: "perfect-score",
        title: "Perfect Delivery",
        description: "Achieved a perfect 100 score",
        icon: "sparkles",
        color: .purple,
        category: .mastery
    )

    static let improver = Achievement(
        id: "improver",
        title: "Leveling Up",
        description: "Beat your previous best score on a scenario",
        icon: "arrow.up.circle.fill",
        color: .qcMoodSuccess,
        category: .mastery
    )

    // MARK: - Exploration Achievements

    static let allCategories = Achievement(
        id: "all-categories",
        title: "Well-Rounded",
        description: "Practiced in all scenario categories",
        icon: "circle.grid.2x2.fill",
        color: .blue,
        category: .exploration
    )

    static let triedSixScenarios = Achievement(
        id: "six-scenarios",
        title: "Explorer",
        description: "Tried 6 different scenarios",
        icon: "map.fill",
        color: .green,
        category: .exploration
    )

    // MARK: - All Achievements

    static let allAchievements: [Achievement] = [
        .firstSession,
        .tenSessions,
        .fiftySessions,
        .hundredSessions,
        .sevenDayStreak,
        .thirtyDayStreak,
        .firstNinety,
        .perfectScore,
        .improver,
        .allCategories,
        .triedSixScenarios
    ]
}

// MARK: - Achievement Manager

@MainActor
@Observable
final class AchievementManager {

    // MARK: - Singleton

    static let shared = AchievementManager()

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.quietcoach", category: "AchievementManager")
    private let defaults = UserDefaults.standard

    private(set) var unlockedAchievementIds: Set<String> = []
    private(set) var newlyUnlockedAchievement: Achievement?

    // MARK: - Keys

    private enum Keys {
        static let unlockedAchievements = "achievements.unlocked"
    }

    // MARK: - Initialization

    private init() {
        loadUnlockedAchievements()
    }

    // MARK: - Public Methods

    /// Check if an achievement is unlocked
    func isUnlocked(_ achievement: Achievement) -> Bool {
        unlockedAchievementIds.contains(achievement.id)
    }

    /// Get all unlocked achievements
    var unlockedAchievements: [Achievement] {
        Achievement.allAchievements.filter { isUnlocked($0) }
    }

    /// Get all locked achievements
    var lockedAchievements: [Achievement] {
        Achievement.allAchievements.filter { !isUnlocked($0) }
    }

    /// Progress toward unlocking (0.0 - 1.0)
    var overallProgress: Double {
        Double(unlockedAchievementIds.count) / Double(Achievement.allAchievements.count)
    }

    /// Clear the newly unlocked achievement (after showing celebration)
    func clearNewlyUnlocked() {
        newlyUnlockedAchievement = nil
    }

    // MARK: - Achievement Checking

    /// Check achievements after session completion
    func checkAchievements(
        totalSessions: Int,
        currentStreak: Int,
        longestStreak: Int,
        latestScore: Int?,
        previousBestScore: Int?,
        uniqueScenarioIds: Set<String>,
        uniqueCategories: Set<Scenario.Category>
    ) {
        // Practice achievements
        if totalSessions >= 1 {
            unlock(.firstSession)
        }
        if totalSessions >= 10 {
            unlock(.tenSessions)
        }
        if totalSessions >= 50 {
            unlock(.fiftySessions)
        }
        if totalSessions >= 100 {
            unlock(.hundredSessions)
        }

        // Streak achievements
        if longestStreak >= 7 || currentStreak >= 7 {
            unlock(.sevenDayStreak)
        }
        if longestStreak >= 30 || currentStreak >= 30 {
            unlock(.thirtyDayStreak)
        }

        // Mastery achievements
        if let score = latestScore {
            if score >= 90 {
                unlock(.firstNinety)
            }
            if score == 100 {
                unlock(.perfectScore)
            }
            if let previous = previousBestScore, score > previous {
                unlock(.improver)
            }
        }

        // Exploration achievements
        if uniqueScenarioIds.count >= 6 {
            unlock(.triedSixScenarios)
        }
        if uniqueCategories.count >= Scenario.Category.allCases.count {
            unlock(.allCategories)
        }
    }

    /// Sync achievements from existing session data
    func syncFromSessions(_ sessions: [RehearsalSession]) {
        let totalSessions = sessions.count
        let uniqueScenarioIds = Set(sessions.map { $0.scenarioId })
        let uniqueCategories = Set(sessions.compactMap { $0.scenario?.category })
        let bestScore = sessions.compactMap { $0.scores?.overall }.max()
        let hasNinety = sessions.contains { ($0.scores?.overall ?? 0) >= 90 }
        let hasPerfect = sessions.contains { ($0.scores?.overall ?? 0) == 100 }

        // Check practice achievements
        if totalSessions >= 1 { unlockSilently(.firstSession) }
        if totalSessions >= 10 { unlockSilently(.tenSessions) }
        if totalSessions >= 50 { unlockSilently(.fiftySessions) }
        if totalSessions >= 100 { unlockSilently(.hundredSessions) }

        // Check mastery achievements
        if hasNinety { unlockSilently(.firstNinety) }
        if hasPerfect { unlockSilently(.perfectScore) }

        // Check exploration achievements
        if uniqueScenarioIds.count >= 6 { unlockSilently(.triedSixScenarios) }
        if uniqueCategories.count >= Scenario.Category.allCases.count { unlockSilently(.allCategories) }

        // Streak achievements are synced from StreakTracker
        let streak = StreakTracker.shared
        if streak.longestStreak >= 7 || streak.currentStreak >= 7 { unlockSilently(.sevenDayStreak) }
        if streak.longestStreak >= 30 || streak.currentStreak >= 30 { unlockSilently(.thirtyDayStreak) }
    }

    // MARK: - Private Methods

    private func unlock(_ achievement: Achievement) {
        guard !isUnlocked(achievement) else { return }

        unlockedAchievementIds.insert(achievement.id)
        saveUnlockedAchievements()
        newlyUnlockedAchievement = achievement

        logger.info("Achievement unlocked: \(achievement.title)")
        Haptics.streakMilestone()
    }

    private func unlockSilently(_ achievement: Achievement) {
        guard !isUnlocked(achievement) else { return }

        unlockedAchievementIds.insert(achievement.id)
        saveUnlockedAchievements()

        logger.info("Achievement synced: \(achievement.title)")
    }

    private func loadUnlockedAchievements() {
        if let ids = defaults.array(forKey: Keys.unlockedAchievements) as? [String] {
            unlockedAchievementIds = Set(ids)
        }
    }

    private func saveUnlockedAchievements() {
        defaults.set(Array(unlockedAchievementIds), forKey: Keys.unlockedAchievements)
    }

    // MARK: - Reset (for testing)

    #if DEBUG
    func reset() {
        unlockedAchievementIds.removeAll()
        saveUnlockedAchievements()
        newlyUnlockedAchievement = nil
    }
    #endif
}
