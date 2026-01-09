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
    // These fonts use relative scaling with .largeTitle/.title as base
    // to ensure accessibility while maintaining visual hierarchy

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

// MARK: - Mesh Gradients (iOS 18+)

/// Dynamic mesh gradient that responds to audio levels
struct AudioReactiveMeshGradient: View {
    let audioLevel: Float
    let isRecording: Bool

    var body: some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            meshGradientContent
        } else {
            // Fallback for older iOS versions
            fallbackGradient
        }
    }

    @available(iOS 18.0, macOS 15.0, *)
    private var meshGradientContent: some View {
        let offset = isRecording ? audioLevel * 0.05 : 0
        let points: [SIMD2<Float>] = [
            SIMD2(0.0, 0.0), SIMD2(0.5, 0.0 + offset), SIMD2(1.0, 0.0),
            SIMD2(0.0 - offset, 0.5), SIMD2(0.5, 0.5), SIMD2(1.0 + offset, 0.5),
            SIMD2(0.0, 1.0), SIMD2(0.5, 1.0 - offset), SIMD2(1.0, 1.0)
        ]
        return MeshGradient(
            width: 3,
            height: 3,
            points: points,
            colors: [
                .qcBackground, .qcSurface, .qcBackground,
                .qcSurface, isRecording ? .qcAccentDimmed : .qcSurface, .qcSurface,
                .qcBackground, .qcSurface, .qcBackground
            ]
        )
        .animation(.easeInOut(duration: 0.3), value: audioLevel)
        .animation(.easeInOut(duration: 0.5), value: isRecording)
    }

    private var fallbackGradient: some View {
        LinearGradient(
            colors: [.qcBackground, .qcSurface.opacity(0.3), .qcBackground],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

/// Calming ambient mesh gradient for backgrounds
struct AmbientMeshGradient: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            meshGradientContent
        } else {
            fallbackGradient
        }
    }

    @available(iOS 18.0, macOS 15.0, *)
    private var meshGradientContent: some View {
        let offset = Float(sin(phase) * 0.03)
        let points: [SIMD2<Float>] = [
            SIMD2(0.0, 0.0), SIMD2(0.5 + offset, 0.0), SIMD2(1.0, 0.0),
            SIMD2(0.0, 0.5 - offset), SIMD2(0.5, 0.5), SIMD2(1.0, 0.5 + offset),
            SIMD2(0.0, 1.0), SIMD2(0.5 - offset, 1.0), SIMD2(1.0, 1.0)
        ]
        return MeshGradient(
            width: 3,
            height: 3,
            points: points,
            colors: [
                .qcBackground, .qcBackground, .qcBackground,
                .qcSurface.opacity(0.3), .qcSurface.opacity(0.5), .qcSurface.opacity(0.3),
                .qcBackground, .qcBackground, .qcBackground
            ]
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                phase = .pi * 2
            }
        }
    }

    private var fallbackGradient: some View {
        Color.qcBackground
    }
}

/// Score celebration mesh gradient with accent colors
struct CelebrationMeshGradient: View {
    let intensity: Double // 0-1 based on score

    var body: some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            meshGradientContent
        } else {
            fallbackGradient
        }
    }

    @available(iOS 18.0, macOS 15.0, *)
    private var meshGradientContent: some View {
        let accent = Color.qcAccent.opacity(intensity * 0.3)
        let success = Color.qcSuccess.opacity(intensity * 0.2)
        let colors: [Color] = [
            .qcBackground, accent, .qcBackground,
            success, .qcSurface, accent,
            .qcBackground, success, .qcBackground
        ]
        return MeshGradient(
            width: 3,
            height: 3,
            points: [
                SIMD2(0.0, 0.0), SIMD2(0.5, 0.0), SIMD2(1.0, 0.0),
                SIMD2(0.0, 0.5), SIMD2(0.5, 0.5), SIMD2(1.0, 0.5),
                SIMD2(0.0, 1.0), SIMD2(0.5, 1.0), SIMD2(1.0, 1.0)
            ],
            colors: colors
        )
    }

    private var fallbackGradient: some View {
        RadialGradient(
            colors: [.qcAccent.opacity(intensity * 0.2), .qcBackground],
            center: .center,
            startRadius: 0,
            endRadius: 300
        )
    }
}

// MARK: - SF Symbol Animations

extension View {
    /// Animated waveform effect for recording indicators
    func qcWaveformAnimation(isActive: Bool) -> some View {
        self.symbolEffect(.variableColor.iterative, options: .repeating, value: isActive)
    }

    /// Bounce effect for score reveals and celebrations
    func qcBounceEffect(trigger: Bool) -> some View {
        self.symbolEffect(.bounce, value: trigger)
    }

    /// Pulse effect for attention-grabbing elements
    func qcPulseEffect(isActive: Bool) -> some View {
        self.symbolEffect(.pulse, options: .repeating, value: isActive)
    }

    /// Scale effect for button interactions (uses replace effect)
    func qcScaleEffect(trigger: Bool) -> some View {
        self.symbolEffect(.bounce.up, value: trigger)
    }

    /// Wiggle effect for errors/warnings (iOS 18+)
    @ViewBuilder
    func qcWiggleEffect(trigger: Bool) -> some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            self.symbolEffect(.wiggle, value: trigger)
        } else {
            self // Fallback: no effect
        }
    }

    /// Breathe effect for idle states (iOS 18+)
    @ViewBuilder
    func qcBreatheEffect(isActive: Bool) -> some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            self.symbolEffect(.breathe, options: .repeating, value: isActive)
        } else {
            self // Fallback: no effect
        }
    }
}

// MARK: - Scroll Transitions

extension View {
    /// Standard scroll transition for list items
    func qcScrollTransition() -> some View {
        self.scrollTransition { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.6)
                .scaleEffect(phase.isIdentity ? 1 : 0.96)
                .blur(radius: phase.isIdentity ? 0 : 1)
        }
    }

    /// Card-style scroll transition with more pronounced effect
    func qcCardScrollTransition() -> some View {
        self.scrollTransition(.animated(.spring(duration: 0.3))) { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.5)
                .scaleEffect(phase.isIdentity ? 1 : 0.92)
                .offset(y: phase.isIdentity ? 0 : phase.value * 10)
        }
    }

    /// Fade-only scroll transition for subtle lists
    func qcFadeScrollTransition() -> some View {
        self.scrollTransition { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.3)
        }
    }
}

// MARK: - Variable Fonts (iOS 18+)

extension Font {
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

// MARK: - Sensory Feedback Modifiers (iOS 17+)

extension View {
    /// Recording state change feedback
    func qcRecordingFeedback(trigger: Bool) -> some View {
        self.sensoryFeedback(.impact(weight: .medium, intensity: 0.8), trigger: trigger)
    }

    /// Score reveal feedback
    func qcScoreRevealFeedback(trigger: Bool) -> some View {
        self.sensoryFeedback(.success, trigger: trigger)
    }

    /// Level change feedback (for sliders, progress)
    func qcLevelFeedback<T: Equatable>(trigger: T) -> some View {
        self.sensoryFeedback(.levelChange, trigger: trigger)
    }

    /// Warning feedback
    func qcWarningFeedback(trigger: Bool) -> some View {
        self.sensoryFeedback(.warning, trigger: trigger)
    }

    /// Selection feedback
    func qcSelectionFeedback<T: Equatable>(trigger: T) -> some View {
        self.sensoryFeedback(.selection, trigger: trigger)
    }

    /// Error feedback
    func qcErrorFeedback(trigger: Bool) -> some View {
        self.sensoryFeedback(.error, trigger: trigger)
    }
}

// MARK: - Visual Effects

extension View {
    /// Glass background effect for visionOS-style cards
    func qcGlassBackground() -> some View {
        self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius, style: .continuous))
    }

    /// Glow effect for highlighted elements
    func qcGlow(color: Color = .qcAccent, radius: CGFloat = 10) -> some View {
        self.shadow(color: color.opacity(0.5), radius: radius)
            .shadow(color: color.opacity(0.3), radius: radius * 2)
    }

    /// Shimmer loading effect
    func qcShimmer(isActive: Bool) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }
}

/// Shimmer effect modifier
struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.2), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: phase)
                    .onAppear {
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            phase = 300
                        }
                    }
                }
            }
            .clipped()
    }
}

// MARK: - Interactive Press Effects

extension View {
    /// Press-down scale effect for buttons
    func qcPressEffect() -> some View {
        self.buttonStyle(QCPressButtonStyle())
    }
}

/// Custom button style with press animation
struct QCPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
