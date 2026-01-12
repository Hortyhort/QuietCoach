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
    @State private var showScoreAnimation = false
    @State private var anchorPhrase: String = ""
    @FocusState private var isAnchorFocused: Bool

    // MARK: - Environment
    @Bindable private var privacySettings = PrivacySettings.shared

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

    private var showsAudioOnlyNote: Bool {
        !privacySettings.transcriptionEnabled && session.transcription == nil
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with scenario info
                headerSection

                // Playback section
                playbackSection

                // Coach notes
                if !session.coachNotes.isEmpty {
                    coachNotesSection
                }

                if showsAudioOnlyNote {
                    audioOnlyNote
                }

                // Anchor phrase
                anchorPhraseSection

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
                    .accessibilityHint("Share your rehearsal card")

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
        .onAppear {
            player.load(session: session)
            anchorPhrase = session.anchorLine ?? ""
            withAnimation(.easeInOut(duration: 1.0)) {
                showScoreAnimation = true
            }
        }
        .onDisappear {
            player.cleanup()
        }
        .onChange(of: anchorPhrase) { _, newValue in
            // Save anchor phrase to session
            session.anchorLine = newValue.isEmpty ? nil : newValue
        }
    }

    private var audioOnlyNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.qcAccent)

            Text("Audio-only feedback. Enable on-device transcription for richer coaching.")
                .font(.qcCaption)
                .foregroundColor(.qcTextTertiary)
        }
        .padding(12)
        .background(Color.qcSurface.opacity(0.6))
        .qcSmallRadius()
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

    // MARK: - Coach Notes Section

    private var coachNotesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Feedback")
                .font(.qcTitle3)
                .foregroundColor(.qcTextPrimary)

            CoachNotesList(notes: session.coachNotes)
        }
    }

    // MARK: - Anchor Phrase Section

    private var anchorPhraseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 14))
                    .foregroundColor(.qcAccent)

                Text("Anchor Phrase")
                    .font(.qcTitle3)
                    .foregroundColor(.qcTextPrimary)
            }

            Text("One phrase you'll say next time")
                .font(.qcCaption)
                .foregroundColor(.qcTextTertiary)

            TextField("e.g., \"I need to share something important...\"", text: $anchorPhrase, axis: .vertical)
                .font(.qcBody)
                .foregroundColor(.qcTextPrimary)
                .padding(12)
                .background(Color.qcSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .focused($isAnchorFocused)
                .lineLimit(2...4)
                .submitLabel(.done)
                .onSubmit {
                    isAnchorFocused = false
                }
        }
        .padding(16)
        .background(Color.qcSurface.opacity(0.5))
        .qcCardRadius()
    }

}

// MARK: - Share Card Sheet

struct ShareCardSheet: View {
    let session: RehearsalSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Share this rehearsal")
                    .font(.qcTitle3)
                    .foregroundColor(.qcTextPrimary)

                // Preview card
                ShareCardView(session: session)
                    .frame(maxWidth: 300)
                    .qcCardShadow()

                // Share button
                if let scenario = session.scenario {
                    ShareLink(
                        item: generateShareImage(),
                        preview: SharePreview(
                            "Quiet Coach: \(scenario.title)",
                            image: Image(systemName: "waveform")
                        )
                    ) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Card")
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
        let uiImage = ShareCardView(session: session)
            .renderToImage()
        return Image(uiImage: uiImage)
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
