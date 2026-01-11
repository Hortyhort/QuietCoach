// ViewModifiers.swift
// QuietCoach
//
// Reusable view modifiers for consistent styling.

import SwiftUI

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
    /// Large card corner radius with continuous corners (24pt)
    func qcCardRadius() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius, style: .continuous))
    }

    /// Medium corner radius for buttons and inputs (16pt)
    func qcMediumRadius() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: Constants.Layout.mediumCornerRadius, style: .continuous))
    }

    /// Small corner radius for badges and pills (10pt)
    func qcSmallRadius() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: Constants.Layout.smallCornerRadius, style: .continuous))
    }
}

// MARK: - Glass Tier System

/// Glass tier for contextual depth hierarchy per Liquid Glass brand system
enum GlassTier {
    /// Ambient — subtle background atmosphere (4-8% opacity, 80pt blur)
    case ambient
    /// Surface — standard cards and containers (12-18% opacity, 40pt blur)
    case surface
    /// Interactive — buttons and controls (20-30% opacity, 20pt blur)
    case interactive
    /// Focal — modals and overlays (40-60% opacity, 8pt blur)
    case focal

    var opacity: Double {
        switch self {
        case .ambient: return 0.06
        case .surface: return 0.15
        case .interactive: return 0.25
        case .focal: return 0.50
        }
    }

    var blurRadius: CGFloat {
        switch self {
        case .ambient: return 80
        case .surface: return 40
        case .interactive: return 20
        case .focal: return 8
        }
    }
}

/// Glass tint for semantic meaning
enum GlassTint {
    /// Clear — neutral glass
    case clear
    /// Warm — coaching moments, amber tint
    case warm
    /// Cool — recording and analysis, blue tint
    case cool

    var color: Color {
        switch self {
        case .clear: return .qcGlassClear
        case .warm: return .qcGlassWarm
        case .cool: return .qcGlassCool
        }
    }
}

/// Modifier that applies tiered glass effect
struct GlassModifier: ViewModifier {
    let tier: GlassTier
    let tint: GlassTint
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Base material layer
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    // Tint overlay
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(tint.color.opacity(tier.opacity))

                    // Subtle edge highlight (0.5pt stroke at 8% white per brand spec)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
            }
    }
}

extension View {
    /// Tiered glass background with configurable tint
    /// - Parameters:
    ///   - tier: Glass opacity/blur tier (ambient, surface, interactive, focal)
    ///   - tint: Semantic tint (clear, warm, cool)
    ///   - cornerRadius: Corner radius for the glass shape
    func qcGlass(
        tier: GlassTier = .surface,
        tint: GlassTint = .clear,
        cornerRadius: CGFloat = Constants.Layout.cornerRadius
    ) -> some View {
        self.modifier(GlassModifier(tier: tier, tint: tint, cornerRadius: cornerRadius))
    }
}

// MARK: - Visual Effects

extension View {
    /// Glass background effect — uses surface tier glass
    /// For more control, use qcGlass(tier:tint:cornerRadius:)
    func qcGlassBackground() -> some View {
        self.qcGlass(tier: .surface)
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

// MARK: - Shimmer Modifier

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
