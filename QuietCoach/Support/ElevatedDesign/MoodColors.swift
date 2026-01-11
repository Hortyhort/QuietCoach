// MoodColors.swift
// QuietCoach
//
// Mood-adaptive color system for dynamic UI states.
// Updated for Liquid Glass brand system.

import SwiftUI

// MARK: - App Mood

/// Dynamic color palette that responds to app state
/// Aligned with Liquid Glass brand palette
enum AppMood: Equatable {
    case ready      // Idle, waiting — soft violet (matches qcAccent)
    case engaged    // Recording — soft coral (matches qcActive)
    case thinking   // Processing — deeper violet
    case success    // Achievement — muted teal (matches qcSuccess)
    case celebration // Triumph — warm amber (matches qcWarning)

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
    /// Ready state — soft violet, matches qcAccent (#9D8CFF)
    static let qcMoodReady = Color(red: 0.616, green: 0.549, blue: 1.0)

    /// Engaged/recording — soft coral, matches qcActive (#E87D6C)
    static let qcMoodEngaged = Color(red: 0.910, green: 0.490, blue: 0.424)

    /// Thinking/processing — deeper violet
    static let qcMoodThinking = Color(red: 0.55, green: 0.50, blue: 0.85)

    /// Success state — muted teal, matches qcSuccess (#6AC4A8)
    static let qcMoodSuccess = Color(red: 0.416, green: 0.769, blue: 0.659)

    /// Celebration — warm amber, matches qcWarning (#E8A855)
    static let qcMoodCelebration = Color(red: 0.910, green: 0.659, blue: 0.333)
}
