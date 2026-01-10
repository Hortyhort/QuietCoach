// Typography.swift
// QuietCoach
//
// Typographic system. All fonts scale with Dynamic Type.

import SwiftUI

// MARK: - Typography

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

    /// Timer display — rounded for warmth, scales with Dynamic Type
    static let qcTimer = Font.system(.largeTitle, design: .rounded, weight: .medium)

    /// Score display — rounded, scales with Dynamic Type
    static let qcScore = Font.system(.title, design: .rounded, weight: .bold)

    /// Small numeric — scales with Dynamic Type
    static let qcScoreSmall = Font.system(.title3, design: .rounded, weight: .semibold)

    // MARK: - UI

    /// Button text — scales with .body
    static let qcButton = Font.body.weight(.semibold)

    /// Small button — scales with .subheadline
    static let qcButtonSmall = Font.subheadline.weight(.medium)

    // MARK: - Variable Fonts

    /// Display font with variable weight and width
    static func qcDisplay(size: CGFloat = 32, weight: Font.Weight = .bold, width: Font.Width = .standard) -> Font {
        .system(size: size, weight: weight, design: .default)
        .width(width)
    }

    /// Condensed display for space-constrained areas
    static func qcCondensedDisplay(size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .default)
        .width(.condensed)
    }

    /// Expanded display for hero moments
    static func qcExpandedDisplay(size: CGFloat = 36) -> Font {
        .system(size: size, weight: .bold, design: .default)
        .width(.expanded)
    }

    /// Numeric display with tabular figures
    static func qcNumeric(size: CGFloat = 48, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
        .monospacedDigit()
    }
}
