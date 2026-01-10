// MeshGradients.swift
// QuietCoach
//
// Dynamic mesh gradients for iOS 18+.

import SwiftUI

// MARK: - Audio Reactive Mesh Gradient

/// Dynamic mesh gradient that responds to audio levels
struct AudioReactiveMeshGradient: View {
    let audioLevel: Float
    let isRecording: Bool

    var body: some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            meshGradientContent
        } else {
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

// MARK: - Ambient Mesh Gradient

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

// MARK: - Celebration Mesh Gradient

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
