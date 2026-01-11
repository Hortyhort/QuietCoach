// Colors.swift
// QuietCoach
//
// The color palette. Dark mode first. Calm and intentional.
// Updated for Liquid Glass brand system.

import SwiftUI

// MARK: - Colors

extension Color {

    // MARK: - Backgrounds

    /// Primary background — true black for OLED
    static let qcBackground = Color(white: 0.0)

    /// Elevated surface — subtle lift for cards
    static let qcSurface = Color(white: 0.11)

    /// Secondary surface — for nested elements
    static let qcSurfaceSecondary = Color(white: 0.15)

    // MARK: - Text

    /// Primary text — high contrast white
    static let qcTextPrimary = Color(white: 0.95)

    /// Secondary text — softer, for supporting copy
    static let qcTextSecondary = Color(white: 0.6)

    /// Tertiary text — very subtle, for hints
    static let qcTextTertiary = Color(white: 0.4)

    // MARK: - Accent

    /// Primary accent — soft violet for AI moments and primary actions
    /// #9D8CFF
    static let qcAccent = Color(red: 0.616, green: 0.549, blue: 1.0)

    /// Accent dimmed for backgrounds
    static let qcAccentDimmed = Color.qcAccent.opacity(0.15)

    // MARK: - Glass Tints

    /// Clear glass tint — neutral, 6% white
    static let qcGlassClear = Color.white.opacity(0.06)

    /// Warm glass tint — amber 4%, for coaching moments
    static let qcGlassWarm = Color(red: 0.910, green: 0.659, blue: 0.333).opacity(0.04)

    /// Cool glass tint — blue 4%, for recording and analysis
    static let qcGlassCool = Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.04)

    // MARK: - Semantic Colors

    /// Active/recording state — soft coral
    /// #E87D6C
    static let qcActive = Color(red: 0.910, green: 0.490, blue: 0.424)

    /// Recording state — deprecated, use qcActive
    @available(*, deprecated, renamed: "qcActive")
    static let qcRecording = qcActive

    /// Paused state — calm amber
    static let qcPaused = Color(red: 0.95, green: 0.68, blue: 0.32)

    /// Success state — muted teal
    /// #6AC4A8
    static let qcSuccess = Color(red: 0.416, green: 0.769, blue: 0.659)

    /// Warning state — warm amber
    /// #E8A855
    static let qcWarning = Color(red: 0.910, green: 0.659, blue: 0.333)

    /// Error state — soft coral (matches active for consistency)
    static let qcError = Color(red: 0.910, green: 0.490, blue: 0.424)

    // MARK: - Pro Badge

    /// Pro badge color — warm amber
    static let qcPro = Color(red: 0.910, green: 0.659, blue: 0.333)

    // MARK: - Waveform

    /// Waveform active bars
    static let qcWaveformActive = Color.qcAccent

    /// Waveform inactive bars
    static let qcWaveformInactive = Color(white: 0.25)
}
