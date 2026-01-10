// MicroInteractions.swift
// QuietCoach
//
// Enhanced micro-interactions for buttons and cards.

import SwiftUI
import UIKit

// MARK: - Magnetic Button

/// Magnetic pull button effect
struct MagneticButton<Content: View>: View {
    let action: () -> Void
    let content: Content

    @State private var offset: CGSize = .zero
    @State private var isPressed: Bool = false
    @GestureState private var dragOffset: CGSize = .zero

    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }

    var body: some View {
        content
            .offset(x: offset.width + dragOffset.width * 0.3,
                    y: offset.height + dragOffset.height * 0.3)
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: offset)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onChanged { _ in
                        isPressed = true
                    }
                    .onEnded { value in
                        isPressed = false

                        // Snap back with particle burst would go here
                        if abs(value.translation.width) < 50 && abs(value.translation.height) < 50 {
                            action()
                            triggerHaptic()
                        }
                    }
            )
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: 0.8)
    }
}

// MARK: - Tilt Card Modifier

/// Tilt card effect on hover/press
struct TiltCardModifier: ViewModifier {
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    @GestureState private var dragLocation: CGPoint = .zero

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .rotation3DEffect(
                    .degrees(rotationX),
                    axis: (x: 1, y: 0, z: 0)
                )
                .rotation3DEffect(
                    .degrees(rotationY),
                    axis: (x: 0, y: 1, z: 0)
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .updating($dragLocation) { value, state, _ in
                            state = value.location
                        }
                        .onChanged { value in
                            let centerX = geometry.size.width / 2
                            let centerY = geometry.size.height / 2

                            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6)) {
                                rotationY = Double((value.location.x - centerX) / centerX) * 10
                                rotationX = Double((centerY - value.location.y) / centerY) * 10
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                rotationX = 0
                                rotationY = 0
                            }
                        }
                )
        }
    }
}

extension View {
    func qcTiltEffect() -> some View {
        modifier(TiltCardModifier())
    }
}
