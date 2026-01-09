// StructureGuideSheet.swift
// QuietCoach
//
// A quick-reference guide for structuring your conversation.
// Open, Context, Ask, Next Step.

import SwiftUI

struct StructureGuideSheet: View {

    // MARK: - Properties

    let scenario: Scenario
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Structure steps
                    structureSteps

                    // Coaching hint
                    coachingHintSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, Constants.Layout.horizontalPadding)
                .padding(.top, 20)
            }
            .background(Color.qcBackground)
            .navigationTitle("Conversation Guide")
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
        VStack(spacing: 12) {
            Image(systemName: scenario.icon)
                .font(.system(size: 32))
                .foregroundColor(.qcAccent)

            Text(scenario.title)
                .font(.qcTitle3)
                .foregroundColor(.qcTextPrimary)

            Text("A simple structure to keep you focused")
                .font(.qcSubheadline)
                .foregroundColor(.qcTextSecondary)
        }
    }

    // MARK: - Structure Steps

    private var structureSteps: some View {
        VStack(spacing: 16) {
            StructureStepCard(
                step: 1,
                label: "Open",
                content: scenario.structureCard.opener,
                color: .qcMoodReady
            )

            StructureStepCard(
                step: 2,
                label: "Context",
                content: scenario.structureCard.context,
                color: .qcMoodEngaged
            )

            StructureStepCard(
                step: 3,
                label: "Ask",
                content: scenario.structureCard.ask,
                color: .qcMoodSuccess
            )

            StructureStepCard(
                step: 4,
                label: "Next Step",
                content: scenario.structureCard.nextStep,
                color: .qcAccent
            )
        }
    }

    // MARK: - Coaching Hint Section

    private var coachingHintSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.qcMoodCelebration)

                Text("Coach's Tip")
                    .font(.qcBodyMedium)
                    .foregroundColor(.qcTextPrimary)
            }

            Text(scenario.coachingHint)
                .font(.qcBody)
                .foregroundColor(.qcTextSecondary)
                .italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.qcSurface)
        .qcCardRadius()
    }
}

// MARK: - Structure Step Card

struct StructureStepCard: View {
    let step: Int
    let label: String
    let content: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)

                Text("\(step)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.qcCaption)
                    .foregroundColor(color)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(content)
                    .font(.qcBody)
                    .foregroundColor(.qcTextPrimary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.qcSurface)
        .qcCardRadius()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(step): \(label). \(content)")
    }
}

// MARK: - Preview

#Preview {
    StructureGuideSheet(scenario: Scenario.allScenarios[0])
        .preferredColorScheme(.dark)
}
