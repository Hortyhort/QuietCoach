// WatchHomeView.swift
// QuietCoachWatch
//
// Main view for the watchOS companion app.
// Quick 30-second practice sessions with haptic feedback.

#if os(watchOS)
import SwiftUI
import WatchKit

struct WatchHomeView: View {

    // MARK: - State

    @State private var selectedScenario: WatchScenario?
    @State private var showingRecorder = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    headerView

                    // Quick scenarios
                    scenariosList
                }
                .padding()
            }
            .navigationTitle("Quiet Coach")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedScenario) { scenario in
                WatchRecordingView(scenario: scenario)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform")
                .font(.title2)
                .foregroundStyle(.orange)

            Text("Quick Practice")
                .font(.headline)
        }
    }

    // MARK: - Scenarios List

    private var scenariosList: some View {
        VStack(spacing: 12) {
            ForEach(WatchScenario.quickScenarios) { scenario in
                Button {
                    selectedScenario = scenario
                } label: {
                    HStack {
                        Image(systemName: scenario.icon)
                            .foregroundStyle(.orange)

                        Text(scenario.title)
                            .font(.footnote)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Watch Scenario Model

struct WatchScenario: Identifiable {
    let id: String
    let title: String
    let icon: String
    let duration: TimeInterval

    static let quickScenarios: [WatchScenario] = [
        WatchScenario(id: "boundary", title: "Set a Boundary", icon: "hand.raised.fill", duration: 30),
        WatchScenario(id: "no", title: "Say No", icon: "xmark.circle.fill", duration: 30),
        WatchScenario(id: "feedback", title: "Give Feedback", icon: "text.bubble.fill", duration: 30),
        WatchScenario(id: "raise", title: "Ask for a Raise", icon: "chart.line.uptrend.xyaxis", duration: 30)
    ]
}

// MARK: - Watch Recording View

struct WatchRecordingView: View {
    let scenario: WatchScenario

    @Environment(\.dismiss) private var dismiss
    @State private var isRecording = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 16) {
            // Scenario header
            VStack(spacing: 4) {
                Image(systemName: scenario.icon)
                    .font(.title3)
                    .foregroundStyle(.orange)

                Text(scenario.title)
                    .font(.footnote)
                    .lineLimit(1)
            }

            // Progress ring
            progressRing

            // Timer
            Text(formattedTime)
                .font(.system(size: 24, weight: .medium, design: .monospaced))
                .foregroundStyle(isRecording ? .primary : .secondary)

            // Record button
            recordButton
        }
        .padding()
        .navigationBarBackButtonHidden(isRecording)
        .onDisappear {
            stopRecording()
        }
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.orange.opacity(0.3), lineWidth: 8)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)
        }
        .frame(width: 80, height: 80)
    }

    // MARK: - Record Button

    private var recordButton: some View {
        Button {
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        } label: {
            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                .font(.title2)
                .foregroundStyle(isRecording ? .red : .white)
                .frame(width: 50, height: 50)
                .background(isRecording ? .white : .orange)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact, trigger: isRecording)
    }

    // MARK: - Helpers

    private var progress: Double {
        min(elapsedTime / scenario.duration, 1.0)
    }

    private var formattedTime: String {
        let remaining = max(scenario.duration - elapsedTime, 0)
        let seconds = Int(remaining)
        return String(format: "0:%02d", seconds)
    }

    private func startRecording() {
        isRecording = true
        elapsedTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsedTime += 0.1
            if elapsedTime >= scenario.duration {
                completeRecording()
            }
        }
    }

    private func stopRecording() {
        timer?.invalidate()
        timer = nil
        isRecording = false
    }

    private func completeRecording() {
        stopRecording()
        // Show completion feedback
        WKInterfaceDevice.current().play(.success)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    WatchHomeView()
}
#endif
