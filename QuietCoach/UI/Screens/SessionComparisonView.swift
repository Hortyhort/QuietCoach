// SessionComparisonView.swift
// QuietCoach
//
// Side-by-side comparison of two sessions.
// See your progress over time.

import SwiftUI

struct SessionComparisonView: View {

    // MARK: - Properties

    let sessionA: RehearsalSession
    let sessionB: RehearsalSession

    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed Properties

    /// Determine which session is "before" and "after"
    private var beforeSession: RehearsalSession {
        sessionA.createdAt < sessionB.createdAt ? sessionA : sessionB
    }

    private var afterSession: RehearsalSession {
        sessionA.createdAt < sessionB.createdAt ? sessionB : sessionA
    }

    private var overallImprovement: Int {
        let beforeScore = beforeSession.scores?.overall ?? 0
        let afterScore = afterSession.scores?.overall ?? 0
        return afterScore - beforeScore
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with improvement summary
                    headerSection

                    // Overall score comparison
                    overallScoreComparison

                    // Detailed score breakdown
                    detailedBreakdown

                    // Session details
                    sessionDetails

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, Constants.Layout.horizontalPadding)
                .padding(.top, 20)
            }
            .background(Color.qcBackground)
            .navigationTitle("Compare Sessions")
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

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            if let scenario = beforeSession.scenario {
                Image(systemName: scenario.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.qcAccent)

                Text(scenario.title)
                    .font(.qcTitle3)
                    .foregroundColor(.qcTextPrimary)
            }

            // Improvement badge
            if overallImprovement != 0 {
                HStack(spacing: 8) {
                    Image(systemName: overallImprovement > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundColor(overallImprovement > 0 ? .qcMoodSuccess : .qcMoodEngaged)

                    Text(overallImprovement > 0 ? "+\(overallImprovement) points" : "\(overallImprovement) points")
                        .font(.qcBodyMedium)
                        .foregroundColor(overallImprovement > 0 ? .qcMoodSuccess : .qcMoodEngaged)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background((overallImprovement > 0 ? Color.qcMoodSuccess : Color.qcMoodEngaged).opacity(0.15))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Overall Score Comparison

    private var overallScoreComparison: some View {
        HStack(spacing: 0) {
            // Before session
            VStack(spacing: 8) {
                Text("Before")
                    .font(.qcCaption)
                    .foregroundColor(.qcTextSecondary)
                    .textCase(.uppercase)

                Text("\(beforeSession.scores?.overall ?? 0)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.qcTextTertiary)

                Text(beforeSession.formattedDate)
                    .font(.qcCaption)
                    .foregroundColor(.qcTextTertiary)
            }
            .frame(maxWidth: .infinity)

            // Arrow
            Image(systemName: "arrow.right")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.qcTextTertiary)

            // After session
            VStack(spacing: 8) {
                Text("After")
                    .font(.qcCaption)
                    .foregroundColor(.qcTextSecondary)
                    .textCase(.uppercase)

                Text("\(afterSession.scores?.overall ?? 0)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.qcAccent)

                Text(afterSession.formattedDate)
                    .font(.qcCaption)
                    .foregroundColor(.qcTextTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(24)
        .background(Color.qcSurface)
        .qcCardRadius()
    }

    // MARK: - Detailed Breakdown

    private var detailedBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Breakdown")
                .font(.qcTitle3)
                .foregroundColor(.qcTextPrimary)

            VStack(spacing: 12) {
                ComparisonRow(
                    label: "Clarity",
                    icon: "text.alignleft",
                    beforeValue: beforeSession.scores?.clarity ?? 0,
                    afterValue: afterSession.scores?.clarity ?? 0
                )

                ComparisonRow(
                    label: "Pacing",
                    icon: "metronome",
                    beforeValue: beforeSession.scores?.pacing ?? 0,
                    afterValue: afterSession.scores?.pacing ?? 0
                )

                ComparisonRow(
                    label: "Tone",
                    icon: "waveform",
                    beforeValue: beforeSession.scores?.tone ?? 0,
                    afterValue: afterSession.scores?.tone ?? 0
                )

                ComparisonRow(
                    label: "Confidence",
                    icon: "flame",
                    beforeValue: beforeSession.scores?.confidence ?? 0,
                    afterValue: afterSession.scores?.confidence ?? 0
                )
            }
        }
    }

    // MARK: - Session Details

    private var sessionDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Session Details")
                .font(.qcTitle3)
                .foregroundColor(.qcTextPrimary)

            HStack(spacing: 12) {
                // Before session details
                SessionDetailCard(
                    label: "Before",
                    session: beforeSession,
                    isHighlighted: false
                )

                // After session details
                SessionDetailCard(
                    label: "After",
                    session: afterSession,
                    isHighlighted: true
                )
            }
        }
    }
}

// MARK: - Comparison Row

struct ComparisonRow: View {
    let label: String
    let icon: String
    let beforeValue: Int
    let afterValue: Int

    private var diff: Int {
        afterValue - beforeValue
    }

    private var diffColor: Color {
        if diff > 0 {
            return .qcMoodSuccess
        } else if diff < 0 {
            return .qcMoodEngaged
        } else {
            return .qcTextTertiary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon and label
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.qcAccent)
                    .frame(width: 20)

                Text(label)
                    .font(.qcBody)
                    .foregroundColor(.qcTextPrimary)
            }
            .frame(width: 100, alignment: .leading)

            Spacer()

            // Before value
            Text("\(beforeValue)")
                .font(.qcBodyMedium)
                .foregroundColor(.qcTextTertiary)
                .frame(width: 40)

            // Arrow
            Image(systemName: "arrow.right")
                .font(.system(size: 12))
                .foregroundColor(.qcTextTertiary)

            // After value
            Text("\(afterValue)")
                .font(.qcBodyMedium)
                .foregroundColor(.qcTextPrimary)
                .frame(width: 40)

            // Diff badge
            HStack(spacing: 2) {
                if diff != 0 {
                    Image(systemName: diff > 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 10, weight: .bold))
                }
                Text(diff > 0 ? "+\(diff)" : diff == 0 ? "—" : "\(diff)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundColor(diffColor)
            .frame(width: 50, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.qcSurface)
        .qcSmallRadius()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(beforeValue) to \(afterValue), \(diff > 0 ? "up" : diff < 0 ? "down" : "unchanged") by \(abs(diff))")
    }
}

// MARK: - Session Detail Card

struct SessionDetailCard: View {
    let label: String
    let session: RehearsalSession
    let isHighlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.qcCaption)
                .foregroundColor(isHighlighted ? .qcAccent : .qcTextSecondary)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text(session.formattedDuration)
                }

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                    Text(session.formattedDate)
                }
            }
            .font(.qcCaption)
            .foregroundColor(.qcTextTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(isHighlighted ? Color.qcAccent.opacity(0.1) : Color.qcSurface)
        .qcSmallRadius()
    }
}

// MARK: - Preview

#Preview {
    SessionComparisonView(
        sessionA: {
            let session = RehearsalSession(
                scenarioId: "set-boundary",
                duration: 35,
                audioFileName: "test1.m4a"
            )
            session.scores = FeedbackScores(clarity: 70, pacing: 65, tone: 72, confidence: 60)
            return session
        }(),
        sessionB: {
            let session = RehearsalSession(
                scenarioId: "set-boundary",
                duration: 42,
                audioFileName: "test2.m4a"
            )
            session.scores = FeedbackScores(clarity: 82, pacing: 78, tone: 85, confidence: 75)
            return session
        }()
    )
    .preferredColorScheme(.dark)
}
