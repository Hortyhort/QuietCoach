// SpatialHomeView.swift
// QuietCoach
//
// visionOS spatial computing experience.
// The ultimate private rehearsal space.

#if os(visionOS)
import SwiftUI
import RealityKit

struct SpatialHomeView: View {

    // MARK: - Environment

    @Environment(SessionRepository.self) private var repository
    @Environment(FeatureGates.self) private var featureGates
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    // MARK: - State

    @State private var selectedScenario: Scenario?
    @State private var isImmersed = false
    @State private var showingSettings = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                // Header
                headerSection

                // Scenario Grid
                scenarioGrid

                // Recent Sessions
                if !repository.recentSessions.isEmpty {
                    recentSessionsSection
                }
            }
            .padding(40)
            .navigationTitle("Quiet Coach")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environment(repository)
                    .environment(featureGates)
            }
            .sheet(item: $selectedScenario) { scenario in
                SpatialRehearseView(scenario: scenario)
                    .environment(repository)
            }
        }
        .ornament(attachmentAnchor: .scene(.bottom)) {
            if isImmersed {
                immersiveControls
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
                .symbolEffect(.variableColor.iterative, options: .repeating)

            Text("Practice difficult conversations in your own private space")
                .font(.title2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Scenario Grid

    private var scenarioGrid: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choose a scenario")
                .font(.title)

            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 20)
                ],
                spacing: 20
            ) {
                ForEach(availableScenarios) { scenario in
                    SpatialScenarioCard(scenario: scenario) {
                        selectedScenario = scenario
                    }
                }
            }
        }
    }

    // MARK: - Recent Sessions

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Sessions")
                .font(.title2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(repository.recentSessions.prefix(5)) { session in
                        SpatialSessionCard(session: session)
                    }
                }
            }
        }
    }

    // MARK: - Immersive Controls

    private var immersiveControls: some View {
        HStack(spacing: 20) {
            Button("Exit Space") {
                Task {
                    await dismissImmersiveSpace()
                    isImmersed = false
                }
            }
            .buttonStyle(.bordered)

            Button("Start Recording") {
                // Recording logic
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
        .glassBackgroundEffect()
    }

    // MARK: - Available Scenarios

    private var availableScenarios: [Scenario] {
        if featureGates.isPro {
            return Scenario.allScenarios
        } else {
            return Scenario.freeScenarios
        }
    }
}

// MARK: - Spatial Scenario Card

struct SpatialScenarioCard: View {
    let scenario: Scenario
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: scenario.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text(scenario.title)
                        .font(.headline)

                    Text(scenario.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 200, height: 150, alignment: .topLeading)
            .padding(20)
            .background(.regularMaterial)
            .cornerRadius(20)
            .hoverEffect(.lift)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Spatial Session Card

struct SpatialSessionCard: View {
    let session: RehearsalSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let scenario = session.scenario {
                HStack {
                    Image(systemName: scenario.icon)
                        .foregroundStyle(.orange)
                    Text(scenario.title)
                        .font(.subheadline)
                }
            }

            if let scores = session.scores {
                Text("\(scores.overall)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(scoreColor(scores.overall))
            }

            Text(session.formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 160)
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .yellow
        default: return .orange
        }
    }
}

// MARK: - Spatial Rehearse View

struct SpatialRehearseView: View {
    let scenario: Scenario

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                // Scenario info
                VStack(spacing: 16) {
                    Image(systemName: scenario.icon)
                        .font(.system(size: 64))
                        .foregroundStyle(.orange)

                    Text(scenario.title)
                        .font(.largeTitle)

                    Text(scenario.subtitle)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                // Recording area
                recordingView

                // Tips
                tipsSection
            }
            .padding(40)
            .navigationTitle("Rehearse")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var recordingView: some View {
        VStack(spacing: 20) {
            // Waveform visualization
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .frame(height: 100)
                .overlay {
                    Image(systemName: "waveform")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                }

            // Record button
            Button {
                // Start recording
            } label: {
                Circle()
                    .fill(.orange)
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "mic.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
            }
            .buttonStyle(.plain)
            .hoverEffect(.lift)
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tips")
                .font(.headline)

            ForEach(scenario.tips.prefix(3), id: \.self) { tip in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text(tip)
                        .font(.body)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview(windowStyle: .automatic) {
    SpatialHomeView()
        .environment(SessionRepository.placeholder)
        .environment(FeatureGates.shared)
}
#endif
