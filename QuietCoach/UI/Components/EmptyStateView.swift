// EmptyStateView.swift
// QuietCoach
//
// Beautiful empty states with Liquid Glass design.
// Every empty moment is an opportunity.

import SwiftUI

// MARK: - Empty State Configuration

struct EmptyStateConfig {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var glowColor: Color = .qcMoodReady
    var animation: EmptyStateAnimation = .breathe

    enum EmptyStateAnimation {
        case breathe
        case float
        case pulse
        case none
    }
}

// MARK: - Preset Configurations

extension EmptyStateConfig {
    static let noSessions = EmptyStateConfig(
        icon: "waveform",
        title: "No sessions yet",
        subtitle: "Your rehearsal history will appear here after your first practice",
        actionTitle: "Start practicing",
        glowColor: .qcMoodReady
    )

    static let noAchievements = EmptyStateConfig(
        icon: "trophy",
        title: "Achievements await",
        subtitle: "Complete rehearsals to unlock badges and celebrate your progress",
        glowColor: .qcMoodCelebration,
        animation: .pulse
    )

    static let noFavorites = EmptyStateConfig(
        icon: "heart",
        title: "No favorites yet",
        subtitle: "Tap the heart on scenarios you want to practice again",
        glowColor: .pink
    )

    static let noSearchResults = EmptyStateConfig(
        icon: "magnifyingglass",
        title: "No results found",
        subtitle: "Try a different search term",
        glowColor: .qcTextSecondary,
        animation: .none
    )

    static let connectionRequired = EmptyStateConfig(
        icon: "wifi.slash",
        title: "No connection",
        subtitle: "Connect to the internet to sync your sessions",
        actionTitle: "Retry",
        glowColor: .qcMoodEngaged
    )

    static let recordingReady = EmptyStateConfig(
        icon: "mic.fill",
        title: "Ready to record",
        subtitle: "Tap the button below to start your rehearsal",
        glowColor: .qcMoodReady,
        animation: .breathe
    )

    static let loadingFailed = EmptyStateConfig(
        icon: "exclamationmark.triangle",
        title: "Something went wrong",
        subtitle: "We couldn't load your data. Please try again.",
        actionTitle: "Try again",
        glowColor: .qcError
    )
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let config: EmptyStateConfig
    var action: (() -> Void)? = nil

    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animated icon with glow
            iconView
                .accessibilityHidden(true)

            // Text content
            VStack(spacing: 12) {
                Text(config.title)
                    .font(.qcTitle3)
                    .foregroundColor(.qcTextPrimary)
                    .multilineTextAlignment(.center)

                Text(config.subtitle)
                    .font(.qcSubheadline)
                    .foregroundColor(.qcTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Action button (if provided)
            if let actionTitle = config.actionTitle, let action = action {
                actionButton(title: actionTitle, action: action)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if !reduceMotion {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(config.title). \(config.subtitle)")
    }

    // MARK: - Icon View

    private var iconView: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(config.glowColor.opacity(isAnimating ? 0.15 : 0.08))
                .frame(width: 120, height: 120)
                .blur(radius: 20)
                .scaleEffect(animationScale)

            // Glass circle
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 88, height: 88)
                .overlay {
                    Circle()
                        .stroke(config.glowColor.opacity(0.2), lineWidth: 1)
                }

            // Icon
            Image(systemName: config.icon)
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [config.glowColor, config.glowColor.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: config.glowColor.opacity(0.3), radius: 8)
                .offset(y: floatOffset)
        }
        .animation(animationStyle, value: isAnimating)
    }

    private var animationScale: CGFloat {
        guard !reduceMotion else { return 1.0 }
        switch config.animation {
        case .breathe, .pulse:
            return isAnimating ? 1.1 : 1.0
        case .float, .none:
            return 1.0
        }
    }

    private var floatOffset: CGFloat {
        guard !reduceMotion else { return 0 }
        switch config.animation {
        case .float:
            return isAnimating ? -8 : 0
        case .breathe, .pulse, .none:
            return 0
        }
    }

    private var animationStyle: Animation? {
        guard !reduceMotion else { return nil }
        switch config.animation {
        case .breathe:
            return .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
        case .float:
            return .easeInOut(duration: 3.0).repeatForever(autoreverses: true)
        case .pulse:
            return .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
        case .none:
            return nil
        }
    }

    // MARK: - Action Button

    private func actionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                Image(systemName: "arrow.right")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    config.glowColor
                    LinearGradient(
                        colors: [.white.opacity(0.3), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(Capsule())
            .shadow(color: config.glowColor.opacity(0.3), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Empty State

/// Smaller empty state for inline use (e.g., in lists or cards)
struct CompactEmptyStateView: View {
    let icon: String
    let message: String
    var glowColor: Color = .qcTextSecondary

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(glowColor.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(glowColor)
            }

            Text(message)
                .font(.qcSubheadline)
                .foregroundColor(.qcTextSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.qcSurface)
        .qcSmallRadius()
    }
}

// MARK: - Loading State (Companion to Empty State)

struct LoadingStateView: View {
    let message: String

    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Glow
                Circle()
                    .fill(Color.qcMoodReady.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .blur(radius: 15)

                // Spinning ring
                Circle()
                    .stroke(Color.qcSurface, lineWidth: 4)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.qcMoodReady, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(rotation))
            }

            Text(message)
                .font(.qcSubheadline)
                .foregroundColor(.qcTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Preview

#Preview("Empty States") {
    ScrollView {
        VStack(spacing: 40) {
            EmptyStateView(config: .noSessions) {
                // Preview action
            }
            .frame(height: 300)

            EmptyStateView(config: .noAchievements)
                .frame(height: 300)

            CompactEmptyStateView(
                icon: "magnifyingglass",
                message: "No matching scenarios"
            )

            LoadingStateView(message: "Loading sessions...")
                .frame(height: 200)
        }
        .padding()
    }
    .background(Color.qcBackground)
    .preferredColorScheme(.dark)
}
