// ParticleEffects.swift
// QuietCoach
//
// Aurora glow and particle burst visual effects.

import SwiftUI

// MARK: - Aurora Glow Modifier

struct AuroraGlowModifier: ViewModifier {
    let color: Color
    let isActive: Bool

    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    color.opacity(0.8),
                                    color.opacity(0.2),
                                    color.opacity(0.8),
                                    color.opacity(0.2),
                                    color.opacity(0.8)
                                ],
                                center: .center,
                                startAngle: .degrees(phase),
                                endAngle: .degrees(phase + 360)
                            ),
                            lineWidth: 2
                        )
                        .blur(radius: 4)
                }
            }
            .onAppear {
                guard isActive else { return }
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    phase = 360
                }
            }
    }
}

extension View {
    func qcAuroraGlow(color: Color = .qcMoodReady, isActive: Bool = true) -> some View {
        modifier(AuroraGlowModifier(color: color, isActive: isActive))
    }
}

// MARK: - Particle Burst View

struct ParticleBurstView: View {
    let color: Color
    @Binding var trigger: Bool

    @State private var particles: [Particle] = []

    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var opacity: Double
    }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .offset(x: particle.x, y: particle.y)
            }
        }
        .onChange(of: trigger) { _, newValue in
            if newValue {
                createBurst()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    trigger = false
                }
            }
        }
    }

    private func createBurst() {
        particles = (0..<12).map { _ in
            Particle(x: 0, y: 0, scale: 1, opacity: 1)
        }

        for (index, _) in particles.enumerated() {
            let angle = Double(index) * (360.0 / 12.0) * .pi / 180
            let distance: CGFloat = 60

            withAnimation(.easeOut(duration: 0.5)) {
                particles[index].x = cos(angle) * distance
                particles[index].y = sin(angle) * distance
                particles[index].scale = 0
                particles[index].opacity = 0
            }
        }
    }
}
