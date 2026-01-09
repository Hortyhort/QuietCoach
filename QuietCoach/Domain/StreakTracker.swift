// StreakTracker.swift
// QuietCoach
//
// Tracks daily practice streaks to encourage consistent rehearsal.
// One rehearsal per day keeps the doubt away.

import Foundation
import SwiftUI

@Observable
final class StreakTracker: @unchecked Sendable {

    // MARK: - Singleton

    static let shared = StreakTracker()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let currentStreak = "streak.currentStreak"
        static let longestStreak = "streak.longestStreak"
        static let lastPracticeDate = "streak.lastPracticeDate"
    }

    // MARK: - Properties

    private let userDefaults = UserDefaults.standard
    private let calendar = Calendar.current
    private let lock = NSLock()

    /// Current consecutive days of practice
    private(set) var currentStreak: Int {
        didSet {
            userDefaults.set(currentStreak, forKey: Keys.currentStreak)
        }
    }

    /// All-time longest streak
    private(set) var longestStreak: Int {
        didSet {
            userDefaults.set(longestStreak, forKey: Keys.longestStreak)
        }
    }

    /// Last date user practiced (nil if never)
    private(set) var lastPracticeDate: Date? {
        didSet {
            if let date = lastPracticeDate {
                userDefaults.set(date.timeIntervalSince1970, forKey: Keys.lastPracticeDate)
            } else {
                userDefaults.removeObject(forKey: Keys.lastPracticeDate)
            }
        }
    }

    /// Whether user has practiced today
    var hasPracticedToday: Bool {
        guard let lastDate = lastPracticeDate else { return false }
        return calendar.isDateInToday(lastDate)
    }

    /// Whether the streak is at risk (practiced yesterday but not today)
    var isStreakAtRisk: Bool {
        guard let lastDate = lastPracticeDate else { return false }
        return calendar.isDateInYesterday(lastDate)
    }

    /// Days until streak expires (0 = practiced today, 1 = practiced yesterday)
    var daysUntilStreakExpires: Int {
        guard let lastDate = lastPracticeDate else { return 0 }
        if calendar.isDateInToday(lastDate) { return 0 }
        if calendar.isDateInYesterday(lastDate) { return 1 }
        return 0
    }

    /// Milestone reached (for celebration)
    var currentMilestone: Milestone? {
        Milestone.milestone(for: currentStreak)
    }

    // MARK: - Initialization

    private init() {
        self.currentStreak = userDefaults.integer(forKey: Keys.currentStreak)
        self.longestStreak = userDefaults.integer(forKey: Keys.longestStreak)

        let timestamp = userDefaults.double(forKey: Keys.lastPracticeDate)
        self.lastPracticeDate = timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil

        // Check if streak has expired on launch
        validateStreak()
    }

    // MARK: - Public Methods

    /// Record a practice session
    func recordPractice() {
        let today = Date()

        if hasPracticedToday {
            // Already practiced today - no change
            return
        }

        if isStreakAtRisk {
            // Practiced yesterday, continue streak
            currentStreak += 1
        } else if lastPracticeDate == nil || !calendar.isDateInYesterday(lastPracticeDate!) {
            // First practice or streak was broken - start fresh
            currentStreak = 1
        }

        lastPracticeDate = today

        // Update longest streak if needed
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
    }

    /// Sync streak from session dates (call on app launch)
    func syncFromSessions(_ sessions: [RehearsalSession]) {
        guard !sessions.isEmpty else { return }

        // Get unique practice days, sorted newest first
        let practiceDays = Set(sessions.map { calendar.startOfDay(for: $0.createdAt) })
            .sorted(by: >)

        guard let mostRecentDay = practiceDays.first else { return }

        // Update last practice date
        lastPracticeDate = mostRecentDay

        // Calculate current streak
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        // If most recent practice wasn't today or yesterday, streak is 0
        let daysSincePractice = calendar.dateComponents([.day], from: mostRecentDay, to: checkDate).day ?? 0
        if daysSincePractice > 1 {
            currentStreak = 0
            return
        }

        // Count consecutive days
        for day in practiceDays {
            if calendar.isDate(day, inSameDayAs: checkDate) ||
               calendar.isDate(day, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: checkDate)!) {
                streak += 1
                checkDate = day
            } else {
                break
            }
        }

        currentStreak = streak

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
    }

    /// Reset all streak data (for testing or data deletion)
    func reset() {
        currentStreak = 0
        longestStreak = 0
        lastPracticeDate = nil
    }

    // MARK: - Private Methods

    private func validateStreak() {
        guard let lastDate = lastPracticeDate else { return }

        // If more than 1 day has passed since last practice, reset streak
        let daysSinceLastPractice = calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0

        if daysSinceLastPractice > 1 {
            currentStreak = 0
        }
    }
}

// MARK: - Milestone

extension StreakTracker {

    enum Milestone: Int, CaseIterable {
        case firstDay = 1
        case threeDays = 3
        case oneWeek = 7
        case twoWeeks = 14
        case oneMonth = 30
        case twoMonths = 60
        case threeMonths = 90
        case halfYear = 180
        case oneYear = 365

        var title: String {
            switch self {
            case .firstDay: return "First Step"
            case .threeDays: return "Building Momentum"
            case .oneWeek: return "One Week Strong"
            case .twoWeeks: return "Two Week Warrior"
            case .oneMonth: return "Monthly Master"
            case .twoMonths: return "Consistency Champion"
            case .threeMonths: return "Quarter Champion"
            case .halfYear: return "Half Year Hero"
            case .oneYear: return "Year of Growth"
            }
        }

        var icon: String {
            switch self {
            case .firstDay: return "flame"
            case .threeDays: return "flame.fill"
            case .oneWeek: return "star"
            case .twoWeeks: return "star.fill"
            case .oneMonth: return "trophy"
            case .twoMonths: return "trophy.fill"
            case .threeMonths: return "crown"
            case .halfYear: return "crown.fill"
            case .oneYear: return "sparkles"
            }
        }

        var color: Color {
            switch self {
            case .firstDay, .threeDays: return .orange
            case .oneWeek, .twoWeeks: return .yellow
            case .oneMonth, .twoMonths: return .mint
            case .threeMonths, .halfYear: return .purple
            case .oneYear: return .pink
            }
        }

        static func milestone(for streak: Int) -> Milestone? {
            Self.allCases.last { $0.rawValue <= streak }
        }
    }
}
