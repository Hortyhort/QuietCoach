// CoachBullet.swift
// QuietCoach
//
// Actionable coaching feedback. Brief, specific, calm.
// Each note earns its place.

import SwiftUI

struct CoachBullet: View {

    // MARK: - Properties

    let note: CoachNote
    var animate: Bool = true
    var delay: Double = 0

    // MARK: - State

    @State private var isRevealed: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.qcBodyMedium)
                    .foregroundColor(.qcTextPrimary)

                Text(note.body)
                    .font(.qcSubheadline)
                    .foregroundColor(.qcTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.qcSurface)
        .qcCardRadius()
        .opacity(isRevealed ? 1 : 0)
        .offset(y: isRevealed ? 0 : 10)
        .onAppear {
            revealNote()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Coaching tip: \(note.title). \(note.body)")
    }

    // MARK: - Icon

    private var iconName: String {
        switch note.type {
        case .scenario: return "lightbulb.fill"
        case .pacing: return "metronome"
        case .intensity: return "waveform"
        case .general: return "text.bubble.fill"
        }
    }

    private var iconColor: Color {
        switch note.priority {
        case .high: return .qcAccent
        case .medium: return .qcTextSecondary
        case .low: return .qcTextTertiary
        }
    }

    // MARK: - Animation

    private func revealNote() {
        guard animate else {
            isRevealed = true
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isRevealed = true
            }
        }
    }
}

// MARK: - Coach Notes List

struct CoachNotesList: View {
    let notes: [CoachNote]
    var animate: Bool = true

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(notes.enumerated()), id: \.element.id) { index, note in
                CoachBullet(
                    note: note,
                    animate: animate,
                    delay: Double(index) * 0.15 + 0.4 // After scores animate
                )
            }
        }
    }
}

// MARK: - Try Again Focus Card

struct TryAgainFocusCard: View {
    let focus: TryAgainFocus
    let onTryAgain: () -> Void

    @State private var isRevealed: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.qcAccent)

                Text("Try Again Focus")
                    .font(.qcBodyMedium)
                    .foregroundColor(.qcTextPrimary)
            }

            // Goal
            Text(focus.goal)
                .font(.qcTitle3)
                .foregroundColor(.qcTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // Reason
            Text(focus.reason)
                .font(.qcSubheadline)
                .foregroundColor(.qcTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Try Again Button
            Button(action: {
                Haptics.buttonPress()
                onTryAgain()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))

                    Text("Try Again")
                        .font(.qcButton)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.qcAccent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(Color.qcSurface)
        .qcCardRadius()
        .opacity(isRevealed ? 1 : 0)
        .offset(y: isRevealed ? 0 : 20)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isRevealed = true
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Try again with focus: \(focus.goal). \(focus.reason)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Structure Card (Scenario Helper)

struct StructureCard: View {
    let structure: Scenario.StructureCard
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                Haptics.buttonPress()
            } label: {
                HStack {
                    Image(systemName: "text.quote")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.qcAccent)

                    Text("Structure Guide")
                        .font(.qcBodyMedium)
                        .foregroundColor(.qcTextPrimary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.qcTextTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    structureLine(label: "Open with", text: structure.opener)
                    structureLine(label: "Context", text: structure.context)
                    structureLine(label: "Your ask", text: structure.ask)
                    structureLine(label: "Next step", text: structure.nextStep)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.qcSurface)
        .qcCardRadius()
    }

    @ViewBuilder
    private func structureLine(label: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.qcCaption)
                .foregroundColor(.qcTextTertiary)

            Text(text)
                .font(.qcSubheadline)
                .foregroundColor(.qcTextSecondary)
                .italic()
        }
    }
}

// MARK: - Preview

#Preview("Coach Components") {
    ScrollView {
        VStack(spacing: 24) {
            CoachBullet(
                note: CoachNote(
                    title: "Slow down slightly",
                    body: "Try adding a breath between thoughts. Let your words land.",
                    type: .pacing,
                    priority: .high
                ),
                animate: false
            )

            TryAgainFocusCard(
                focus: TryAgainFocus(
                    goal: "State your main point in the first sentence.",
                    reason: "Opening with clarity sets up everything that follows."
                ),
                onTryAgain: {}
            )

            StructureCard(
                structure: Scenario.StructureCard(
                    opener: "I need to talk about something important.",
                    context: "When [specific situation happens]...",
                    ask: "I need [your boundary].",
                    nextStep: "Can we agree on this going forward?"
                )
            )
        }
        .padding()
    }
    .background(Color.qcBackground)
}
