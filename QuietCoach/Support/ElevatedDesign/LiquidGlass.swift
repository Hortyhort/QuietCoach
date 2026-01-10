// LiquidGlass.swift
// QuietCoach
//
// Glass card components with depth and parallax effects.

import SwiftUI

// MARK: - Liquid Glass Card

/// Glass card with depth and parallax
struct LiquidGlassCard<Content: View>: View {
    let content: Content
    var depth: CGFloat = 1.0

    @State private var offset: CGSize = .zero

    init(depth: CGFloat = 1.0, @ViewBuilder content: () -> Content) {
        self.depth = depth
        self.content = content()
    }

    var body: some View {
        content
            .background {
                ZStack {
                    // Base glass
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)

                    // Aurora edge glow
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1),
                                    Color.qcMoodReady.opacity(0.2),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )

                    // Inner shadow for depth
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        .blur(radius: 2)
                        .offset(x: 1, y: 1)
                        .mask(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.black)
                        )
                }
            }
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10 * depth)
            .rotation3DEffect(
                .degrees(Double(offset.width) / 20),
                axis: (x: 0, y: 1, z: 0)
            )
            .rotation3DEffect(
                .degrees(Double(-offset.height) / 20),
                axis: (x: 1, y: 0, z: 0)
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            offset = .zero
                        }
                    }
            )
    }
}

// MARK: - Breathing Modifier

/// Breathing UI element — gentle scale pulse on idle
struct BreathingModifier: ViewModifier {
    let isActive: Bool
    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                guard isActive else { return }
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    scale = 1.03
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        scale = 1.03
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        scale = 1.0
                    }
                }
            }
    }
}

extension View {
    func qcBreathing(isActive: Bool = true) -> some View {
        modifier(BreathingModifier(isActive: isActive))
    }
}
