// StreakBadgeView.swift
// QuietCoach
//
// Visual display of practice streak. Celebrates consistency.

import SwiftUI

struct StreakBadgeView: View {

    // MARK: - Properties

    let streak: Int
    let isAtRisk: Bool
    let hasPracticedToday: Bool

    // MARK: - Animation State

    @State private var isAnimating = false

    // MARK: - Computed

    private var streakColor: Color {
        if hasPracticedToday {
            return .qcMoodCelebration
        } else if isAtRisk {
            return .orange
        } else {
            return .qcTextTertiary
        }
    }

    private var iconName: String {
        if streak == 0 {
            return "flame"
        } else if hasPracticedToday {
            return "flame.fill"
        } else if isAtRisk {
            return "flame.fill"
        } else {
            return "flame"
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(streakColor)
                .symbolEffect(.bounce, value: isAnimating)

            if streak > 0 {
                Text("\(streak)")
                    .font(.qcBodyMedium)
                    .foregroundColor(streakColor)
                    .contentTransition(.numericText())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(streakColor.opacity(0.15))
        )
        .overlay(
            Capsule()
                .strokeBorder(streakColor.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            if hasPracticedToday || isAtRisk {
                withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
                    isAnimating = true
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if streak == 0 {
            return "No current streak. Start practicing to build one."
        } else if hasPracticedToday {
            return "\(streak) day streak. Practiced today."
        } else if isAtRisk {
            return "\(streak) day streak at risk. Practice today to keep it going."
        } else {
            return "Streak ended. Start a new one by practicing today."
        }
    }
}

// MARK: - Expanded Streak View (for header)

struct StreakHeaderView: View {

    let tracker: StreakTracker

    @State private var showingMilestoneDetails = false

    var body: some View {
        HStack(spacing: 12) {
            // Streak badge
            StreakBadgeView(
                streak: tracker.currentStreak,
                isAtRisk: tracker.isStreakAtRisk,
                hasPracticedToday: tracker.hasPracticedToday
            )

            // Message
            VStack(alignment: .leading, spacing: 2) {
                Text(messageTitle)
                    .font(.qcSubheadline)
                    .foregroundColor(.qcTextPrimary)

                Text(messageSubtitle)
                    .font(.qcCaption)
                    .foregroundColor(.qcTextSecondary)
            }

            Spacer()

            // Milestone badge (if applicable)
            if let milestone = tracker.currentMilestone, tracker.currentStreak >= 3 {
                Button {
                    showingMilestoneDetails = true
                } label: {
                    Image(systemName: milestone.icon)
                        .font(.system(size: 20))
                        .foregroundColor(milestone.color)
                }
                .accessibilityLabel("Milestone: \(milestone.title)")
            }
        }
        .padding(16)
        .background(Color.qcSurface)
        .qcCardRadius()
        .sheet(isPresented: $showingMilestoneDetails) {
            if let milestone = tracker.currentMilestone {
                MilestoneDetailSheet(milestone: milestone, streak: tracker.currentStreak)
            }
        }
    }

    private var messageTitle: String {
        if tracker.currentStreak == 0 {
            return "Start your streak"
        } else if tracker.hasPracticedToday {
            if tracker.currentStreak == 1 {
                return "Day 1 complete!"
            } else {
                return "\(tracker.currentStreak) days strong"
            }
        } else if tracker.isStreakAtRisk {
            return "Keep it going!"
        } else {
            return "Start fresh"
        }
    }

    private var messageSubtitle: String {
        if tracker.currentStreak == 0 {
            return "One rehearsal a day builds confidence"
        } else if tracker.hasPracticedToday {
            return "Come back tomorrow to continue"
        } else if tracker.isStreakAtRisk {
            return "Practice today to maintain your streak"
        } else {
            return "A new streak starts with one rehearsal"
        }
    }
}

// MARK: - Milestone Detail Sheet

struct MilestoneDetailSheet: View {

    let milestone: StreakTracker.Milestone
    let streak: Int

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Big milestone icon
                Image(systemName: milestone.icon)
                    .font(.system(size: 80))
                    .foregroundColor(milestone.color)
                    .symbolEffect(.pulse.wholeSymbol)

                VStack(spacing: 8) {
                    Text(milestone.title)
                        .font(.qcTitle)
                        .foregroundColor(.qcTextPrimary)

                    Text("\(streak) day streak")
                        .font(.qcTitle2)
                        .foregroundColor(.qcTextSecondary)
                }

                Text(milestoneMessage)
                    .font(.qcBody)
                    .foregroundColor(.qcTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Keep Going")
                        .font(.qcButton)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(milestone.color)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(Color.qcBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.qcAccent)
                }
            }
        }
    }

    private var milestoneMessage: String {
        switch milestone {
        case .firstDay:
            return "Every journey starts with a single step. You've taken yours."
        case .threeDays:
            return "Three days of showing up. That's how habits begin."
        case .oneWeek:
            return "A full week of practice. You're building something real."
        case .twoWeeks:
            return "Two weeks of consistency. Your confidence is growing."
        case .oneMonth:
            return "A month of daily practice. This is who you're becoming."
        case .twoMonths:
            return "Two months strong. Difficult conversations feel different now."
        case .threeMonths:
            return "A quarter year of growth. Your voice has power."
        case .halfYear:
            return "Half a year of dedication. You inspire others."
        case .oneYear:
            return "365 days. A year of finding your voice. Remarkable."
        }
    }
}

// MARK: - Streak Celebration Overlay

struct StreakCelebrationOverlay: View {

    let milestone: StreakTracker.Milestone
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 24) {
                if #available(iOS 18.0, *) {
                    Image(systemName: milestone.icon)
                        .font(.system(size: 64))
                        .foregroundColor(milestone.color)
                        .symbolEffect(.bounce.up.byLayer, options: .repeating)
                } else {
                    Image(systemName: milestone.icon)
                        .font(.system(size: 64))
                        .foregroundColor(milestone.color)
                }

                Text(milestone.title)
                    .font(.qcTitle)
                    .foregroundColor(.white)

                Text("Tap to continue")
                    .font(.qcCaption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            Haptics.streakMilestone()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

// MARK: - Previews

#Preview("Badge - Active") {
    HStack(spacing: 16) {
        StreakBadgeView(streak: 7, isAtRisk: false, hasPracticedToday: true)
        StreakBadgeView(streak: 5, isAtRisk: true, hasPracticedToday: false)
        StreakBadgeView(streak: 0, isAtRisk: false, hasPracticedToday: false)
    }
    .padding()
    .background(Color.qcBackground)
}

#Preview("Header") {
    StreakHeaderView(tracker: StreakTracker.shared)
        .padding()
        .background(Color.qcBackground)
}

#Preview("Milestone Sheet") {
    MilestoneDetailSheet(milestone: .oneWeek, streak: 7)
}
