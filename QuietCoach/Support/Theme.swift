// Theme.swift
// QuietCoach
//
// The visual language of Quiet Coach.
// Dark mode first. Calm palette. Typographic discipline.

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

// MARK: - Typography
//
// All fonts scale with Dynamic Type using relative sizing.
// Base text styles ensure accessibility compliance.

extension Font {

    // MARK: - Display

    /// Large title for hero moments — scales with .largeTitle
    static let qcLargeTitle = Font.largeTitle.weight(.bold)

    /// Primary title — scales with .title
    static let qcTitle = Font.title.weight(.bold)

    /// Secondary title — scales with .title2
    static let qcTitle2 = Font.title2.weight(.bold)

    /// Tertiary title — scales with .title3
    static let qcTitle3 = Font.title3.weight(.semibold)

    // MARK: - Body

    /// Primary body text — scales with .body
    static let qcBody = Font.body

    /// Medium weight body — scales with .body
    static let qcBodyMedium = Font.body.weight(.medium)

    /// Subheadline — scales with .subheadline
    static let qcSubheadline = Font.subheadline

    /// Footnote — scales with .footnote
    static let qcFootnote = Font.footnote

    /// Caption — scales with .caption
    static let qcCaption = Font.caption

    // MARK: - Numeric
    // Note: Timer and score fonts use fixed sizes for design consistency
    // but use .monospacedDigit() for proper number alignment

    /// Timer display — rounded for warmth
    static let qcTimer = Font.system(size: 48, weight: .medium, design: .rounded)

    /// Score display — rounded
    static let qcScore = Font.system(size: 32, weight: .bold, design: .rounded)

    /// Small numeric
    static let qcScoreSmall = Font.system(size: 20, weight: .semibold, design: .rounded)

    // MARK: - UI

    /// Button text — scales with .body
    static let qcButton = Font.body.weight(.semibold)

    /// Small button — scales with .subheadline
    static let qcButtonSmall = Font.subheadline.weight(.medium)
}

// MARK: - Time Formatting

extension TimeInterval {
    /// Format as MM:SS for display
    var qcFormattedDuration: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Date Formatting

extension Date {
    /// Short date format: "Jan 15"
    var qcShortString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    /// Medium date format: "January 15, 2024"
    var qcMediumString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Relative time: "Today", "Yesterday", "3 days ago"
    var qcRelativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Shadow Styles

extension View {
    /// Subtle card shadow
    func qcCardShadow() -> some View {
        self.shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }

    /// Deeper shadow for modals
    func qcModalShadow() -> some View {
        self.shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Corner Radius

extension View {
    /// Standard card corner radius with continuous corners
    func qcCardRadius() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius, style: .continuous))
    }

    /// Smaller corner radius
    func qcSmallRadius() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: Constants.Layout.smallCornerRadius, style: .continuous))
    }
}
