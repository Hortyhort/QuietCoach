// UIBrandingTestView.swift
// QuietCoach
//
// UI branding test showcasing Xcode AI-inspired design language.
// Aurora gradients, shimmer effects, and glowing elements.

import SwiftUI

struct UIBrandingTestView: View {
    @State private var animateGradient = false
    @State private var shimmerOffset: CGFloat = -200
    @State private var pulseScale: CGFloat = 1.0
    @State private var isProcessing = false
    
    var body: some View {
        ZStack {
            // Aurora background
            AuroraBackground(animate: animateGradient)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header with AI branding
                    aiHeader
                    
                    // AI-styled cards
                    VStack(spacing: 20) {
                        aiFeatureCard(
                            icon: "sparkles",
                            title: "Intelligent Coaching",
                            description: "Real-time feedback powered by on-device AI"
                        )
                        
                        aiFeatureCard(
                            icon: "waveform.badge.magnifyingglass",
                            title: "Voice Analysis",
                            description: "Understand your clarity, pacing, and tone"
                        )
                        
                        aiFeatureCard(
                            icon: "brain.head.profile",
                            title: "Adaptive Learning",
                            description: "Personalized suggestions that evolve with you"
                        )
                    }
                    
                    // AI processing indicator
                    aiProcessingView
                    
                    // AI-styled button
                    aiActionButton
                    
                    // Shimmer text demo
                    shimmerTextDemo
                    
                    // Glow orb demo
                    glowOrbDemo
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
            startShimmer()
        }
    }
    
    // MARK: - AI Header
    
    private var aiHeader: some View {
        VStack(spacing: 12) {
            // Sparkle icon with glow
            ZStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(aiGradient)
                    .blur(radius: 20)
                    .opacity(0.6)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(aiGradient)
            }
            .scaleEffect(pulseScale)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    pulseScale = 1.15
                }
            }
            
            Text("Quiet Coach")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(aiGradient)
            
            Text("AI-Powered Practice")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - AI Feature Card
    
    private func aiFeatureCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(aiGradient.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(aiGradient)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(aiGradient.opacity(0.3), lineWidth: 1)
                }
        }
    }
    
    // MARK: - AI Processing View
    
    private var aiProcessingView: some View {
        VStack(spacing: 16) {
            Text("Processing")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Animated bars
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    ProcessingBar(delay: Double(index) * 0.1)
                }
            }
            .frame(height: 32)
            
            Text("Analyzing your voice patterns...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.purple.opacity(0.5), .blue.opacity(0.5), .cyan.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
    }
    
    // MARK: - AI Action Button
    
    private var aiActionButton: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                isProcessing.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isProcessing ? "stop.fill" : "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                
                Text(isProcessing ? "Stop Analysis" : "Start AI Analysis")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                ZStack {
                    // Glow layer
                    RoundedRectangle(cornerRadius: 14)
                        .fill(aiGradient)
                        .blur(radius: 8)
                        .opacity(0.6)
                        .offset(y: 4)
                    
                    // Main button
                    RoundedRectangle(cornerRadius: 14)
                        .fill(aiGradient)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Shimmer Text Demo
    
    private var shimmerTextDemo: some View {
        VStack(spacing: 12) {
            Text("Shimmer Effect")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Intelligent Feedback")
                .font(.title2.bold())
                .foregroundStyle(aiGradient)
                .overlay {
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.8), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 100)
                    .offset(x: shimmerOffset)
                    .mask {
                        Text("Intelligent Feedback")
                            .font(.title2.bold())
                    }
                }
                .clipped()
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }
    
    // MARK: - Glow Orb Demo
    
    private var glowOrbDemo: some View {
        VStack(spacing: 12) {
            Text("AI Indicator")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseScale)
                
                // Middle glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                
                // Core
                Circle()
                    .fill(aiGradient)
                    .frame(width: 40, height: 40)
                
                // Sparkle icon
                Image(systemName: "sparkle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
    }
    
    // MARK: - Gradient
    
    private var aiGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.6, green: 0.4, blue: 1.0),   // Purple
                Color(red: 0.4, green: 0.6, blue: 1.0),   // Blue
                Color(red: 0.3, green: 0.8, blue: 0.9),   // Cyan
                Color(red: 0.9, green: 0.5, blue: 0.8)    // Pink
            ],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
    }
    
    // MARK: - Shimmer Animation
    
    private func startShimmer() {
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            shimmerOffset = 200
        }
    }
}

// MARK: - Aurora Background

struct AuroraBackground: View {
    let animate: Bool
    
    var body: some View {
        ZStack {
            Color.black
            
            // Purple blob
            Circle()
                .fill(Color.purple.opacity(0.3))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(
                    x: animate ? 50 : -50,
                    y: animate ? -100 : -150
                )
            
            // Blue blob
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 350, height: 350)
                .blur(radius: 100)
                .offset(
                    x: animate ? -80 : 80,
                    y: animate ? 100 : 50
                )
            
            // Cyan blob
            Circle()
                .fill(Color.cyan.opacity(0.25))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(
                    x: animate ? 100 : -20,
                    y: animate ? -50 : 150
                )
            
            // Pink accent
            Circle()
                .fill(Color.pink.opacity(0.2))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(
                    x: animate ? -100 : 50,
                    y: animate ? 200 : 100
                )
        }
    }
}

// MARK: - Processing Bar

struct ProcessingBar: View {
    let delay: Double
    @State private var height: CGFloat = 8
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [.purple, .blue, .cyan],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 6, height: height)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    height = 32
                }
            }
    }
}

// MARK: - Preview

#Preview {
    UIBrandingTestView()
        .preferredColorScheme(.dark)
}
