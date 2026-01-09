// WatchRehearseView.swift
// QuietCoachWatch
//
// Quick recording interface for Apple Watch.
// Minimal, focused, effective.

import SwiftUI
import AVFoundation

struct WatchRehearseView: View {
    
    let scenario: WatchScenario
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var isRecording = false
    @State private var isPaused = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showingResult = false
    @State private var resultScore: Int?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            if showingResult, let score = resultScore {
                resultView(score: score)
            } else {
                recordingView
            }
        }
        .navigationTitle(scenario.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Recording View
    
    private var recordingView: some View {
        VStack(spacing: 20) {
            // Prompt
            Text(scenario.prompt)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Timer
            Text(formattedTime)
                .font(.system(size: 36, weight: .medium, design: .monospaced))
                .foregroundStyle(isRecording ? .orange : .primary)
            
            // Recording indicator
            if isRecording {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    Text(isPaused ? "Paused" : "Recording")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Controls
            HStack(spacing: 20) {
                if isRecording {
                    // Pause/Resume button
                    Button {
                        togglePause()
                    } label: {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.bordered)
                    
                    // Stop button
                    Button {
                        stopRecording()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                } else {
                    // Start button
                    Button {
                        startRecording()
                    } label: {
                        Image(systemName: "mic.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }
        }
    }
    
    // MARK: - Result View
    
    private func resultView(score: Int) -> some View {
        VStack(spacing: 16) {
            // Score
            Text("\(score)")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(scoreColor(score))
            
            Text("Great practice!")
                .font(.headline)
            
            // Actions
            VStack(spacing: 8) {
                Button("Try Again") {
                    resetForNewRecording()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .yellow
        default: return .orange
        }
    }
    
    private func startRecording() {
        isRecording = true
        isPaused = false
        elapsedTime = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if !isPaused {
                elapsedTime += 0.1
            }
        }
        
        // TODO: Start actual audio recording with AVAudioRecorder
    }
    
    private func togglePause() {
        isPaused.toggle()
        // TODO: Pause/resume actual recording
    }
    
    private func stopRecording() {
        timer?.invalidate()
        timer = nil
        isRecording = false
        
        // TODO: Stop actual recording and analyze
        // For now, simulate a score
        resultScore = Int.random(in: 65...95)
        showingResult = true
    }
    
    private func resetForNewRecording() {
        showingResult = false
        resultScore = nil
        elapsedTime = 0
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WatchRehearseView(scenario: .boundary)
    }
}
