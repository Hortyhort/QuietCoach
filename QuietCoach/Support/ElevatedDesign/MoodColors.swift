// MoodColors.swift
// QuietCoach
//
// Mood-adaptive color system for dynamic UI states.

import SwiftUI

// MARK: - App Mood

/// Dynamic color palette that responds to app state
enum AppMood: Equatable {
    case ready      // Idle, waiting — warm amber
    case engaged    // Recording — soft coral
    case thinking   // Processing — cool violet
    case success    // Achievement — mint green
    case celebration // Triumph — gold burst

    var primaryColor: Color {
        switch self {
        case .ready: return Color.qcMoodReady
        case .engaged: return Color.qcMoodEngaged
        case .thinking: return Color.qcMoodThinking
        case .success: return Color.qcMoodSuccess
        case .celebration: return Color.qcMoodCelebration
        }
    }

    var glowColor: Color {
        primaryColor.opacity(0.4)
    }

    var backgroundAccent: Color {
        primaryColor.opacity(0.1)
    }
}

// MARK: - Mood Color Extensions

extension Color {
    static let qcMoodReady = Color(red: 0.98, green: 0.82, blue: 0.47)       // Warm amber
    static let qcMoodEngaged = Color(red: 0.98, green: 0.56, blue: 0.52)    // Soft coral
    static let qcMoodThinking = Color(red: 0.65, green: 0.55, blue: 0.88)   // Cool violet
    static let qcMoodSuccess = Color(red: 0.45, green: 0.82, blue: 0.68)    // Mint green
    static let qcMoodCelebration = Color(red: 1.0, green: 0.84, blue: 0.35) // Gold burst
}
