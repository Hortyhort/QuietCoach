// MenuBarApp.swift
// QuietCoach
//
// macOS Menu Bar app for quick recording access.
// Practice without leaving your current workflow.

#if os(macOS)
import SwiftUI
import AppKit

// MARK: - Menu Bar Extra Scene

struct MenuBarScene: Scene {
    @State private var isRecording = false
    @State private var elapsedTime: TimeInterval = 0

    var body: some Scene {
        MenuBarExtra("Quiet Coach", systemImage: isRecording ? "waveform.circle.fill" : "waveform") {
            MenuBarContentView(isRecording: $isRecording, elapsedTime: $elapsedTime)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Menu Bar Content View

struct MenuBarContentView: View {
    @Binding var isRecording: Bool
    @Binding var elapsedTime: TimeInterval

    @State private var selectedScenario: MenuBarScenario = .boundary
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 16) {
            // Header
            headerView

            Divider()

            if isRecording {
                // Recording view
                recordingView
            } else {
                // Scenario selection
                scenarioSelectionView
            }

            Divider()

            // Footer
            footerView
        }
        .padding()
        .frame(width: 280)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Image(systemName: "waveform")
                .foregroundStyle(.orange)
                .imageScale(.large)

            Text("Quiet Coach")
                .font(.headline)

            Spacer()

            if isRecording {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
            }
        }
    }

    // MARK: - Recording View

    private var recordingView: some View {
        VStack(spacing: 16) {
            // Scenario info
            HStack {
                Image(systemName: selectedScenario.icon)
                    .foregroundStyle(.orange)
                Text(selectedScenario.title)
                    .font(.subheadline)
            }

            // Timer
            Text(formattedTime)
                .font(.system(size: 32, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)

            // Recording indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Text("Recording...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Stop button
            Button {
                stopRecording()
            } label: {
                Label("Stop Recording", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .keyboardShortcut(.space, modifiers: [])
        }
    }

    // MARK: - Scenario Selection

    private var scenarioSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Practice")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Scenario", selection: $selectedScenario) {
                ForEach(MenuBarScenario.allCases, id: \.self) { scenario in
                    Label(scenario.title, systemImage: scenario.icon)
                        .tag(scenario)
                }
            }
            .pickerStyle(.menu)

            Button {
                startRecording()
            } label: {
                Label("Start Recording", systemImage: "mic.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .keyboardShortcut("r", modifiers: .command)
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Button("Open App") {
                NSWorkspace.shared.open(URL(string: "quietcoach://")!)
            }
            .buttonStyle(.link)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.link)
            .foregroundStyle(.secondary)
        }
        .font(.caption)
    }

    // MARK: - Helpers

    private var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func startRecording() {
        isRecording = true
        elapsedTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsedTime += 0.1
        }
    }

    private func stopRecording() {
        timer?.invalidate()
        timer = nil
        isRecording = false
        elapsedTime = 0
    }
}

// MARK: - Menu Bar Scenario

enum MenuBarScenario: String, CaseIterable {
    case boundary = "boundary"
    case sayNo = "sayno"
    case feedback = "feedback"
    case raise = "raise"

    var title: String {
        switch self {
        case .boundary: return "Set a Boundary"
        case .sayNo: return "Say No"
        case .feedback: return "Give Feedback"
        case .raise: return "Ask for a Raise"
        }
    }

    var icon: String {
        switch self {
        case .boundary: return "hand.raised.fill"
        case .sayNo: return "xmark.circle.fill"
        case .feedback: return "text.bubble.fill"
        case .raise: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Preview

#Preview {
    MenuBarContentView(isRecording: .constant(false), elapsedTime: .constant(0))
        .frame(width: 280)
}
#endif
