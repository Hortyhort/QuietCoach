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
    /// Standard card corner radius with continuous corners
    func qcCardRadius() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius, style: .continuous))
    }

    /// Smaller corner radius
    func qcSmallRadius() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: Constants.Layout.smallCornerRadius, style: .continuous))
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
