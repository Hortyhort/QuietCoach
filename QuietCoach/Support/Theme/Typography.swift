// Typography.swift
// QuietCoach
//
// Typographic system. All fonts scale with Dynamic Type.
// Updated for Liquid Glass brand system.

import SwiftUI

// MARK: - Typography

extension Font {

    // MARK: - Brand Display (Liquid Glass)

    /// Display font — SF Pro Rounded, Medium weight per brand spec
    /// Use for headlines on glass surfaces
    static let qcDisplay = Font.system(.largeTitle, design: .rounded, weight: .medium)

    /// Large display — SF Pro Rounded, Medium weight
    static let qcDisplayLarge = Font.system(.largeTitle, design: .rounded, weight: .medium)

    /// Medium display — SF Pro Rounded, Medium weight
    static let qcDisplayMedium = Font.system(.title, design: .rounded, weight: .medium)

    /// Small display — SF Pro Rounded, Medium weight
    static let qcDisplaySmall = Font.system(.title2, design: .rounded, weight: .medium)

    // MARK: - Display (Legacy)

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

    // MARK: - Dynamic Type Scaled Fonts

    /// Hero score display - scales from largeTitle with limits
    static let qcHeroScore = Font.system(.largeTitle, design: .rounded, weight: .bold)

    /// Timer display - scales from title with monospaced digits
    static let qcTimerDisplay = Font.system(.title, design: .monospaced, weight: .medium)

    /// Large numeric display - scales from title2
    static let qcLargeNumeric = Font.system(.title2, design: .rounded, weight: .bold)

    /// Medium numeric display - scales from title3
    static let qcMediumNumeric = Font.system(.title3, design: .rounded, weight: .semibold)

    /// Small numeric display - scales from headline
    static let qcSmallNumeric = Font.system(.headline, design: .rounded, weight: .medium)

    /// Icon-sized text - scales from callout
    static let qcIconLabel = Font.system(.callout, weight: .medium)
}

// MARK: - Dynamic Type View Modifiers

extension View {
    /// Limits Dynamic Type scaling for UI elements that would break at extreme sizes
    /// Use this for timers, scores, and constrained layouts
    func qcDynamicTypeScaled(
        minimum: DynamicTypeSize = .xSmall,
        maximum: DynamicTypeSize = .accessibility2
    ) -> some View {
        self.dynamicTypeSize(minimum...maximum)
    }

    /// For elements that should only scale slightly (scores, badges)
    func qcCompactDynamicType() -> some View {
        self.dynamicTypeSize(.xSmall...DynamicTypeSize.large)
    }

    /// For hero text that can scale more freely
    func qcHeroDynamicType() -> some View {
        self.dynamicTypeSize(.xSmall...DynamicTypeSize.accessibility3)
    }

    // MARK: - Glass-Optimized Text

    /// Applies glass-optimized text styling with +0.5pt tracking
    /// Per brand spec: text on glass needs increased tracking for readability
    func qcGlassTextStyle() -> some View {
        self.tracking(0.5)
    }

    /// Display text on glass with rounded font and tracking
    func qcGlassDisplayStyle() -> some View {
        self
            .font(.qcDisplay)
            .tracking(0.5)
    }

    /// Body text on glass with tracking
    func qcGlassBodyStyle() -> some View {
        self
            .font(.qcBodyMedium)
            .tracking(0.5)
    }

    /// Applies proper scaling with appropriate limits based on content type
    func qcScaledFont(_ style: QCFontStyle) -> some View {
        self
            .font(style.font)
            .dynamicTypeSize(style.sizeRange)
    }
}

/// Font styles with appropriate Dynamic Type limits
enum QCFontStyle {
    case heroScore       // Large scores - limited scaling to prevent overflow
    case timer           // Timers - moderate scaling
    case cardTitle       // Card titles - standard scaling
    case body            // Body text - full accessibility scaling
    case caption         // Captions - standard scaling
    case button          // Buttons - moderate scaling
    case badge           // Badges - compact scaling

    var font: Font {
        switch self {
        case .heroScore: return .qcHeroScore
        case .timer: return .qcTimerDisplay
        case .cardTitle: return .qcTitle3
        case .body: return .qcBody
        case .caption: return .qcCaption
        case .button: return .qcButton
        case .badge: return .qcSmallNumeric
        }
    }

    var sizeRange: ClosedRange<DynamicTypeSize> {
        switch self {
        case .heroScore: return .small...DynamicTypeSize.xxxLarge
        case .timer: return .small...DynamicTypeSize.xxLarge
        case .cardTitle: return .xSmall...DynamicTypeSize.accessibility2
        case .body: return .xSmall...DynamicTypeSize.accessibility5
        case .caption: return .xSmall...DynamicTypeSize.accessibility3
        case .button: return .small...DynamicTypeSize.accessibility1
        case .badge: return .small...DynamicTypeSize.large
        }
    }
}

// MARK: - Scaled Metric for Custom Layouts

/// Custom scaled metrics for layouts that need to respond to Dynamic Type
enum QCScaleFactors {
    /// Scale factor based on current Dynamic Type size
    static func scaleFactor(for size: DynamicTypeSize) -> CGFloat {
        switch size {
        case .xSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .xLarge: return 1.2
        case .xxLarge: return 1.3
        case .xxxLarge: return 1.4
        case .accessibility1: return 1.5
        case .accessibility2: return 1.7
        case .accessibility3: return 1.9
        case .accessibility4: return 2.1
        case .accessibility5: return 2.3
        @unknown default: return 1.0
        }
    }
}

/// View modifier that scales dimensions based on Dynamic Type
struct DynamicTypeSizeModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let baseSize: CGFloat
    let maxScale: CGFloat

    func body(content: Content) -> some View {
        let scale = min(QCScaleFactors.scaleFactor(for: dynamicTypeSize), maxScale)
        content.frame(width: baseSize * scale, height: baseSize * scale)
    }
}

extension View {
    /// Scales a view's frame based on Dynamic Type settings
    func qcScaledFrame(base: CGFloat, maxScale: CGFloat = 1.5) -> some View {
        modifier(DynamicTypeSizeModifier(baseSize: base, maxScale: maxScale))
    }
}
