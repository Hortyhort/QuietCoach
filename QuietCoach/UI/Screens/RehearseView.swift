// RehearseView.swift
// QuietCoach
//
// The recording experience. Focused, calm, powerful.
// One button. One waveform. One timer. That's it.

import SwiftUI

struct RehearseView: View {

    // MARK: - Properties

    let scenario: Scenario
    let onComplete: (RehearsalSession) -> Void
    let onCancel: () -> Void

    // MARK: - State

    @State private var recorder = RehearsalRecorder()
    @Environment(SessionRepository.self) private var repository

    @State private var showingCancelConfirmation = false
    @State private var isProcessing = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background - audio reactive mesh gradient
            AudioReactiveMeshGradient(
                audioLevel: recorder.currentLevel,
                isRecording: recorder.state == .recording
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top section: Scenario info
                topSection

                Spacer()

                // Middle section: Waveform and timer
                centerSection

                Spacer()

                // Warning banner (if active)
                warningSection

                // Bottom section: Controls
                controlsSection
            }
            .padding(.horizontal, Constants.Layout.horizontalPadding)
            .padding(.bottom, 40)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    handleCancel()
                }
                .foregroundColor(.qcTextSecondary)
                .accessibilityLabel("Cancel rehearsal")
                .accessibilityHint("Double tap to cancel and discard recording")
            }

            ToolbarItem(placement: .topBarTrailing) {
                if recorder.state == .recording || recorder.state == .paused {
                    Button("Done") {
                        finishRecording()
                    }
                    .foregroundColor(.qcAccent)
                    .fontWeight(.semibold)
                    .accessibilityLabel("Finish rehearsal")
                    .accessibilityHint("Double tap to stop recording and see feedback")
                }
            }
        }
        .confirmationDialog(
            "Cancel Rehearsal?",
            isPresented: $showingCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel Rehearsal", role: .destructive) {
                recorder.cancelRecording()
                onCancel()
            }
            Button("Keep Recording", role: .cancel) {}
        } message: {
            Text("Your recording will be deleted.")
        }
        .onAppear {
            recorder.setupAudioSession()
        }
        .interactiveDismissDisabled(recorder.state == .recording || recorder.state == .paused)
    }

    // MARK: - Top Section

    private var topSection: some View {
        VStack(spacing: 8) {
            // Scenario icon with breathing animation when idle
            Image(systemName: scenario.icon)
                .font(.system(size: 32))
                .foregroundColor(.qcAccent)
                .qcBreatheEffect(isActive: recorder.state == .idle)
                .qcPulseEffect(isActive: recorder.state == .recording)
                .accessibilityHidden(true)

            // Scenario title
            Text(scenario.title)
                .font(.qcTitle2)
                .foregroundColor(.qcTextPrimary)

            // Prompt
            Text(scenario.promptText)
                .font(.qcSubheadline)
                .foregroundColor(.qcTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rehearsing: \(scenario.title). \(scenario.promptText)")
    }

    // MARK: - Center Section

    private var centerSection: some View {
        VStack(spacing: 32) {
            // Waveform
            Group {
                if recorder.state == .idle {
                    IdleWaveformView(barCount: 40, height: 80)
                } else {
                    WaveformView(
                        samples: recorder.waveformSamples,
                        isActive: recorder.state == .recording,
                        barCount: 40,
                        maxBarHeight: 80
                    )
                }
            }
            .frame(height: 80)
            .padding(.horizontal, 20)

            // Timer
            TimerDisplay(
                time: recorder.currentTime,
                isWarning: recorder.isNearMaxDuration
            )
        }
    }

    // MARK: - Warning Section

    @ViewBuilder
    private var warningSection: some View {
        if let warning = recorder.activeWarning {
            RecordingWarningBanner(warning: warning)
                .padding(.bottom, 20)
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack(spacing: 40) {
            // Pause button (when recording)
            if recorder.state == .recording {
                SecondaryActionButton(
                    icon: "pause.fill",
                    label: "Pause",
                    action: {
                        Haptics.pauseRecording()
                        recorder.pauseRecording()
                    }
                )
            } else if recorder.state == .paused {
                // Cancel button (when paused)
                SecondaryActionButton(
                    icon: "xmark",
                    label: "Cancel",
                    action: handleCancel
                )
            } else {
                // Placeholder for alignment
                Color.clear
                    .frame(width: Constants.Layout.secondaryButtonSize)
            }

            // Main record button
            RecordButton(
                state: recorder.state,
                onTap: handleRecordTap
            )

            // Structure guide or done button
            if recorder.state == .idle {
                // Structure guide (expandable)
                SecondaryActionButton(
                    icon: "text.quote",
                    label: "Guide",
                    action: {
                        // TODO: Show structure card sheet
                    }
                )
            } else if recorder.state == .recording || recorder.state == .paused {
                SecondaryActionButton(
                    icon: "checkmark",
                    label: "Done",
                    action: finishRecording
                )
            } else {
                Color.clear
                    .frame(width: Constants.Layout.secondaryButtonSize)
            }
        }
    }

    // MARK: - Actions

    private func handleRecordTap() {
        switch recorder.state {
        case .idle:
            recorder.startRecording()

        case .recording:
            finishRecording()

        case .paused:
            recorder.resumeRecording()

        case .finished:
            // Start new recording
            recorder.resetForNewRecording()
            recorder.startRecording()
        }
    }

    private func handleCancel() {
        if recorder.state == .recording || recorder.state == .paused {
            showingCancelConfirmation = true
        } else {
            onCancel()
        }
    }

    private func finishRecording() {
        guard recorder.currentTime >= Constants.Limits.minRecordingDuration else {
            // Too short - show feedback
            Haptics.warning()
            return
        }

        isProcessing = true

        // Log memory state before processing
        PerformanceMonitor.shared.logMemoryState("Pre-feedback")

        // Stop recording and get metrics
        let metrics = recorder.stopRecording()

        guard let fileName = recorder.currentFileName else {
            isProcessing = false
            return
        }

        // Use async speech analysis for richer feedback
        Task {
            await processRecordingAsync(metrics: metrics, fileName: fileName)
        }
    }

    private func processRecordingAsync(metrics: AudioMetrics, fileName: String) async {
        let audioURL = FileStore.shared.audioFileURL(for: fileName)

        // Try async analysis with full NLP, fallback to sync if it fails
        let result: FeedbackResult
        do {
            result = try await FeedbackEngine.generateScores(
                from: metrics,
                audioURL: audioURL,
                scenario: scenario
            )
        } catch {
            // Fallback to audio-only analysis
            let scores = FeedbackEngine.generateScores(from: metrics, scenario: scenario)
            result = FeedbackResult(
                scores: scores,
                transcription: nil,
                speechAnalysis: nil,
                usedSpeechAnalysis: false
            )
        }

        // Generate coach notes using the enhanced analysis
        let notes: [CoachNote]
        let focus: TryAgainFocus

        if result.usedSpeechAnalysis, let analysis = result.speechAnalysis {
            notes = CoachNotesEngine.generateNotes(
                metrics: metrics,
                scores: result.scores,
                scenario: scenario,
                speechAnalysis: analysis
            )
            focus = CoachNotesEngine.generateTryAgainFocus(
                scores: result.scores,
                scenario: scenario,
                insights: result.insights
            )
        } else {
            notes = CoachNotesEngine.generateNotes(metrics: metrics, scores: result.scores, scenario: scenario)
            focus = CoachNotesEngine.generateTryAgainFocus(scores: result.scores, scenario: scenario)
        }

        // Save session with transcription if available
        let session = repository.createSession(
            scenarioId: scenario.id,
            duration: metrics.duration,
            audioFileName: fileName,
            scores: result.scores,
            coachNotes: notes,
            tryAgainFocus: focus,
            metrics: metrics
        )

        // Store transcription if available
        if let transcription = result.transcription {
            session.transcription = transcription
        }

        // Log memory state after processing
        PerformanceMonitor.shared.logMemoryState("Post-feedback")

        Haptics.scoresRevealed()
        isProcessing = false
        onComplete(session)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RehearseView(
            scenario: Scenario.allScenarios[0],
            onComplete: { _ in },
            onCancel: {}
        )
    }
    .environment(SessionRepository.placeholder)
    .preferredColorScheme(.dark)
}
