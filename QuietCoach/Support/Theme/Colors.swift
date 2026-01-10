// Colors.swift
// QuietCoach
//
// The color palette. Dark mode first. Calm and intentional.

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

    /// Primary accent — warm, calm gold
    /// Not too bright, not too muted
    static let qcAccent = Color(red: 0.98, green: 0.82, blue: 0.47)

    /// Accent dimmed for backgrounds
    static let qcAccentDimmed = Color(red: 0.98, green: 0.82, blue: 0.47).opacity(0.15)

    // MARK: - Semantic Colors

    /// Recording state — warm red, but not alarming
    static let qcRecording = Color(red: 0.92, green: 0.34, blue: 0.34)

    /// Paused state — calm amber
    static let qcPaused = Color(red: 0.95, green: 0.68, blue: 0.32)

    /// Success state — soft green
    static let qcSuccess = Color(red: 0.34, green: 0.75, blue: 0.49)

    /// Warning state — attention without alarm
    static let qcWarning = Color(red: 0.95, green: 0.68, blue: 0.32)

    /// Error state — clear but not aggressive
    static let qcError = Color(red: 0.92, green: 0.34, blue: 0.34)

    // MARK: - Pro Badge

    /// Pro badge color — subtle gold
    static let qcPro = Color(red: 1.0, green: 0.75, blue: 0.27)

    // MARK: - Waveform

    /// Waveform active bars
    static let qcWaveformActive = Color.qcAccent

    /// Waveform inactive bars
    static let qcWaveformInactive = Color(white: 0.25)
}
