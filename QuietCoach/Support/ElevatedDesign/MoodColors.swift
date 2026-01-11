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
    /// Ready state — soft violet, references qcAccent
    static var qcMoodReady: Color { .qcAccent }

    /// Engaged/recording — soft coral, references qcActive
    static var qcMoodEngaged: Color { .qcActive }

    /// Thinking/processing — deeper violet (unique to mood system)
    static let qcMoodThinking = Color(red: 0.55, green: 0.50, blue: 0.85)

    /// Success state — muted teal, references qcSuccess
    static var qcMoodSuccess: Color { .qcSuccess }

    /// Celebration — warm amber, references qcWarning
    static var qcMoodCelebration: Color { .qcWarning }
}
