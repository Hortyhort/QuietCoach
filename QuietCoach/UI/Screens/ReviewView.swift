// ReviewView.swift
// QuietCoach
//
// The feedback reveal. Scores animate in, coach notes follow.
// The "Try Again" button makes repetition addictive.

import SwiftUI

struct ReviewView: View {

    // MARK: - Properties

    let session: RehearsalSession
    let onTryAgain: () -> Void
    let onDone: () -> Void

    // MARK: - State

    @State private var player = AudioPlayerViewModel()
    @State private var showingShareSheet = false
    @State private var showingScoreInfo = false
    @State private var showScoreAnimation = false
    @State private var showConfidencePulse = true

    // MARK: - Environment

    @Environment(SessionRepository.self) private var repository

    // MARK: - Computed Properties

    private var scoreIntensity: Double {
        guard let scores = session.scores else { return 0 }
        return Double(scores.overall) / 100.0
    }

    /// Waveform samples from recorded audio metrics
    private var waveformSamples: [Float] {
        // Use real waveform data if available, otherwise generate placeholder
        if let metrics = session.metrics {
            // Downsample to ~60 bars for display
            let normalized = metrics.normalizedWaveform
            if normalized.count > 60 {
                let step = normalized.count / 60
                return stride(from: 0, to: normalized.count, by: step).map { normalized[$0] }
            }
            return normalized
        }
        // Fallback for legacy sessions without metrics
        return (0..<60).map { _ in Float.random(in: 0.2...0.8) }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with scenario info
                headerSection

                // Playback section
                playbackSection

                // Scores
                if let scores = session.scores {
                    scoresSection(scores)
                }

                // Coach notes
                if !session.coachNotes.isEmpty {
                    coachNotesSection
                }

                // Try Again focus
                if let focus = session.tryAgainFocus {
                    TryAgainFocusCard(focus: focus, onTryAgain: onTryAgain)
                }

                // Bottom spacing
                Spacer(minLength: 40)
            }
            .padding(.horizontal, Constants.Layout.horizontalPadding)
            .padding(.top, 16)
        }
        .background {
            // Celebration mesh gradient based on score
            CelebrationMeshGradient(intensity: showScoreAnimation ? scoreIntensity : 0)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.0), value: showScoreAnimation)
        }
        .qcScoreRevealFeedback(trigger: showScoreAnimation)
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        Haptics.share()
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.qcTextSecondary)
                    }
                    .accessibilityLabel("Share")
                    .accessibilityHint("Share your rehearsal results")

                    Button("Done") {
                        onDone()
                    }
                    .foregroundColor(.qcAccent)
                    .fontWeight(.semibold)
                    .accessibilityLabel("Done")
                    .accessibilityHint("Return to home screen")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareCardSheet(session: session)
        }
        .sheet(isPresented: $showingScoreInfo) {
            ScoreInfoSheet()
        }
        .overlay {
            // Confidence Pulse animation on first appearance
            if showConfidencePulse, let scores = session.scores {
                ConfidencePulseView(score: scores.overall) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showConfidencePulse = false
                        showScoreAnimation = true
                    }
                    // Play celebration sound for high scores, milestone for others
                    if scores.overall >= 80 {
                        SoundManager.shared.play(.celebration)
                    } else {
                        SoundManager.shared.play(.milestone)
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            player.load(session: session)
            // If no scores, skip the pulse animation
            if session.scores == nil {
                showConfidencePulse = false
                showScoreAnimation = true
            }
        }
        .onDisappear {
            player.cleanup()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            if let scenario = session.scenario {
                Image(systemName: scenario.icon)
                    .font(.system(size: 28))
                    .foregroundColor(.qcAccent)
                    .qcBounceEffect(trigger: showScoreAnimation)
                    .accessibilityHidden(true)

                Text(scenario.title)
                    .font(.qcTitle3)
                    .foregroundColor(.qcTextPrimary)
            }

            HStack(spacing: 16) {
                Label(session.formattedDuration, systemImage: "clock")
                Label(session.formattedDate, systemImage: "calendar")
            }
            .font(.qcCaption)
            .foregroundColor(.qcTextTertiary)
        }
        .qcScrollTransition()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rehearsal: \(session.scenario?.title ?? "Unknown"). Duration: \(session.formattedDuration). Recorded: \(session.formattedDate)")
    }

    // MARK: - Playback Section

    private var playbackSection: some View {
        VStack(spacing: 16) {
            // Waveform scrubber with real audio data
            CompactWaveformView(
                samples: waveformSamples,
                progress: player.progress
            )
            .onTapGesture { location in
                // Seek on tap
                let progress = location.x / UIScreen.main.bounds.width
                player.seekToProgress(progress)
            }

            // Playback controls
            HStack(spacing: 24) {
                // Time display
                Text(player.formattedCurrentTime)
                    .font(.qcCaption)
                    .foregroundColor(.qcTextTertiary)
                    .monospacedDigit()
                    .frame(width: 50, alignment: .leading)
                    .accessibilityLabel("Current time: \(player.formattedCurrentTime)")

                // Skip back
                Button {
                    player.seekBackward(seconds: 10)
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 20))
                        .foregroundColor(.qcTextSecondary)
                }
                .frame(width: 44, height: 44)
                .accessibilityLabel("Skip back 10 seconds")

                // Play/Pause
                Button {
                    player.togglePlayPause()
                } label: {
                    Image(systemName: player.state == .playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.qcAccent)
                }
                .frame(width: 56, height: 56)
                .background(Color.qcSurface)
                .clipShape(Circle())
                .accessibilityLabel(player.state == .playing ? "Pause" : "Play")
                .accessibilityHint("Double tap to \(player.state == .playing ? "pause" : "play") your recording")

                // Skip forward
                Button {
                    player.seekForward(seconds: 10)
                } label: {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 20))
                        .foregroundColor(.qcTextSecondary)
                }
                .frame(width: 44, height: 44)
                .accessibilityLabel("Skip forward 10 seconds")

                // Duration display
                Text(player.formattedDuration)
                    .font(.qcCaption)
                    .foregroundColor(.qcTextTertiary)
                    .monospacedDigit()
                    .frame(width: 50, alignment: .trailing)
                    .accessibilityLabel("Total duration: \(player.formattedDuration)")
            }
        }
        .padding(16)
        .background(Color.qcSurface)
        .qcCardRadius()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Audio playback controls")
    }

    // MARK: - Scores Section

    private func scoresSection(_ scores: FeedbackScores) -> some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("Your Scores")
                    .font(.qcTitle3)
                    .foregroundColor(.qcTextPrimary)

                Spacer()

                Button {
                    showingScoreInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.qcTextTertiary)
                }
                .accessibilityLabel("Score information")
                .accessibilityHint("Double tap to learn what each score means")
            }

            // Score interpretation with coach personality
            HStack(spacing: 8) {
                Text(CoachPersonality.emoji(for: scores.overall))
                Text(CoachPersonality.interpret(score: scores.overall))
                    .font(.qcSubheadline)
                    .foregroundColor(.qcTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Score grid
            let previousSession = repository.previousSession(for: session.scenarioId, before: session)
            ScoreGrid(
                scores: scores,
                previousScores: previousSession?.scores
            )
        }
    }

    // MARK: - Coach Notes Section

    private var coachNotesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Coaching Notes")
                .font(.qcTitle3)
                .foregroundColor(.qcTextPrimary)

            CoachNotesList(notes: session.coachNotes)
        }
    }

}

// MARK: - Score Info Sheet

struct ScoreInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(FeedbackScores.ScoreType.allCases, id: \.self) { scoreType in
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: scoreType.icon)
                                    .foregroundColor(.qcAccent)
                                Text(scoreType.rawValue)
                                    .font(.qcBodyMedium)
                            }

                            Text(scoreType.explanation)
                                .font(.qcSubheadline)
                                .foregroundColor(.qcTextSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("How Scores Work")
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
}

// MARK: - Share Card Sheet

struct ShareCardSheet: View {
    let session: RehearsalSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Share your progress")
                    .font(.qcTitle3)
                    .foregroundColor(.qcTextPrimary)

                // Preview card
                ShareCardView(session: session)
                    .frame(maxWidth: 300)
                    .qcCardShadow()

                // Share button
                if session.scores != nil, let scenario = session.scenario {
                    ShareLink(
                        item: generateShareImage(),
                        preview: SharePreview(
                            "Quiet Coach: \(scenario.title)",
                            image: Image(systemName: "waveform")
                        )
                    ) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(.qcButton)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.qcAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, 40)
                }

                Spacer()
            }
            .padding(.top, 40)
            .background(Color.qcBackground)
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

    @MainActor
    private func generateShareImage() -> Image {
        // Render ShareCardView to image using ImageRenderer
        let shareCard = ShareCardView(session: session)
            .frame(width: 350, height: 450)
            .background(Color.qcBackground)

        let renderer = ImageRenderer(content: shareCard)
        renderer.scale = UIScreen.main.scale

        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }

        // Fallback if rendering fails
        return Image(systemName: "waveform")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReviewView(
            session: {
                let session = RehearsalSession(
                    scenarioId: "set-boundary",
                    duration: 45,
                    audioFileName: "test.m4a"
                )
                session.scores = FeedbackScores(clarity: 82, pacing: 75, tone: 88, confidence: 70)
                session.coachNotes = [
                    CoachNote(title: "For this conversation", body: "Start with what you need, not with an apology.", type: .scenario, priority: .high),
                    CoachNote(title: "Add strategic pauses", body: "Pauses after key points give them impact.", type: .pacing, priority: .medium)
                ]
                session.tryAgainFocus = TryAgainFocus(
                    goal: "State your main point in the first sentence.",
                    reason: "Opening with clarity sets up everything that follows."
                )
                return session
            }(),
            onTryAgain: {},
            onDone: {}
        )
    }
    .environment(SessionRepository.placeholder)
    .preferredColorScheme(.dark)
}
