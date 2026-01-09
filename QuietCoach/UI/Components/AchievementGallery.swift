// AchievementGallery.swift
// QuietCoach
//
// Badge gallery showing unlocked and locked achievements.
// Celebrates progress, motivates growth.

import SwiftUI

struct AchievementGalleryView: View {

    // MARK: - State

    @State private var achievementManager = AchievementManager.shared
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress header
                    progressHeader

                    // Unlocked achievements
                    if !achievementManager.unlockedAchievements.isEmpty {
                        achievementSection(
                            title: "Unlocked",
                            achievements: achievementManager.unlockedAchievements,
                            isLocked: false
                        )
                    }

                    // Locked achievements
                    if !achievementManager.lockedAchievements.isEmpty {
                        achievementSection(
                            title: "Keep Going",
                            achievements: achievementManager.lockedAchievements,
                            isLocked: true
                        )
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, Constants.Layout.horizontalPadding)
                .padding(.top, 20)
            }
            .background(Color.qcBackground)
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.qcAccent)
                }
            }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 16) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.qcSurface, lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: achievementManager.overallProgress)
                    .stroke(Color.qcAccent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(achievementManager.unlockedAchievements.count)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.qcTextPrimary)

                    Text("of \(Achievement.allAchievements.count)")
                        .font(.qcCaption)
                        .foregroundColor(.qcTextSecondary)
                }
            }

            Text("Keep practicing to unlock more")
                .font(.qcSubheadline)
                .foregroundColor(.qcTextSecondary)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Achievement Section

    private func achievementSection(
        title: String,
        achievements: [Achievement],
        isLocked: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.qcTitle3)
                .foregroundColor(.qcTextPrimary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(achievements) { achievement in
                    AchievementCard(
                        achievement: achievement,
                        isLocked: isLocked
                    )
                }
            }
        }
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let achievement: Achievement
    let isLocked: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(isLocked ? Color.qcSurface : achievement.color.opacity(0.2))
                    .frame(width: 56, height: 56)

                Image(systemName: achievement.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isLocked ? .qcTextTertiary : achievement.color)
            }

            // Title and description
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.qcBodyMedium)
                    .foregroundColor(isLocked ? .qcTextTertiary : .qcTextPrimary)
                    .multilineTextAlignment(.center)

                Text(achievement.description)
                    .font(.qcCaption)
                    .foregroundColor(.qcTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.qcSurface)
        .qcCardRadius()
        .opacity(isLocked ? 0.6 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(achievement.title). \(achievement.description). \(isLocked ? "Locked" : "Unlocked")")
    }
}

// MARK: - Achievement Celebration Overlay

struct AchievementCelebrationOverlay: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Achievement card
            VStack(spacing: 24) {
                // Icon with glow
                ZStack {
                    Circle()
                        .fill(achievement.color.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)

                    Circle()
                        .fill(achievement.color.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: achievement.icon)
                        .font(.system(size: 48))
                        .foregroundColor(achievement.color)
                }

                // Text
                VStack(spacing: 8) {
                    Text("Achievement Unlocked!")
                        .font(.qcCaption)
                        .foregroundColor(.qcTextSecondary)
                        .textCase(.uppercase)
                        .tracking(1)

                    Text(achievement.title)
                        .font(.qcTitle2)
                        .foregroundColor(.qcTextPrimary)

                    Text(achievement.description)
                        .font(.qcBody)
                        .foregroundColor(.qcTextSecondary)
                        .multilineTextAlignment(.center)
                }

                // Dismiss button
                Button {
                    onDismiss()
                } label: {
                    Text("Nice!")
                        .font(.qcButton)
                        .foregroundColor(.black)
                        .frame(width: 120, height: 44)
                        .background(achievement.color)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(32)
            .background(Color.qcSurface)
            .qcCardRadius()
            .padding(.horizontal, 40)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AchievementGalleryView()
        .preferredColorScheme(.dark)
}
