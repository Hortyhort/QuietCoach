// MacHomeView.swift
// QuietCoach
//
// macOS-specific home view using NavigationSplitView.
// A native Mac experience with sidebar navigation.

#if os(macOS)
import SwiftUI

struct MacHomeView: View {

    // MARK: - Environment

    @Environment(SessionRepository.self) private var repository
    @Environment(FeatureGates.self) private var featureGates
    @Environment(AppRouter.self) private var router

    // MARK: - State

    @State private var selectedScenario: Scenario?
    @State private var selectedSession: RehearsalSession?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showingSettings = false
    @State private var showingMissingSessionAlert = false
    @State private var missingSessionMessage = ""

    // MARK: - Body

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } content: {
            // Scenario list or session history
            contentView
                .navigationSplitViewColumnWidth(min: 300, ideal: 350, max: 450)
        } detail: {
            // Main content area
            detailView
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environment(repository)
                .environment(featureGates)
                .frame(minWidth: 400, minHeight: 500)
        }
        .onAppear {
            handlePendingRoutes()
        }
        .onChange(of: router.pendingScenarioId) { _, _ in
            handlePendingRoutes()
        }
        .onChange(of: router.pendingSessionId) { _, _ in
            handlePendingRoutes()
        }
        .alert(L10n.Routing.rehearsalUnavailableTitle, isPresented: $showingMissingSessionAlert) {
            Button(L10n.Common.ok, role: .cancel) {}
        } message: {
            Text(missingSessionMessage)
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selectedScenario) {
            Section("Practice") {
                ForEach(availableScenarios) { scenario in
                    NavigationLink(value: scenario) {
                        Label {
                            Text(scenario.title)
                        } icon: {
                            Image(systemName: scenario.icon)
                                .foregroundColor(.qcAccent)
                        }
                    }
                    .tag(scenario)
                }
            }

            Section("History") {
                ForEach(repository.recentSessions.prefix(10)) { session in
                    Button {
                        selectedSession = session
                        selectedScenario = nil
                    } label: {
                        HStack {
                            if let scenario = session.scenario {
                                Image(systemName: scenario.icon)
                                    .foregroundColor(.qcAccent)
                            }
                            VStack(alignment: .leading) {
                                Text(session.scenario?.title ?? "Session")
                                    .font(.body)
                                Text(session.formattedDate)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if let scores = session.scores {
                                Text("\(scores.overall)")
                                    .font(.headline)
                                    .foregroundColor(.qcAccent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(L10n.Common.appName)
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if let scenario = selectedScenario {
            scenarioDetailView(scenario)
        } else if let session = selectedSession {
            sessionDetailView(session)
        } else {
            ContentUnavailableView(
                L10n.Home.chooseScenarioFromSidebar,
                systemImage: "waveform",
                description: Text(L10n.Home.selectScenarioFromSidebar)
            )
        }
    }

    // MARK: - Detail View

    @ViewBuilder
    private var detailView: some View {
        if let scenario = selectedScenario {
            RehearseView(
                scenario: scenario,
                onComplete: { session in
                    selectedSession = session
                    selectedScenario = nil
                },
                onCancel: {
                    selectedScenario = nil
                }
            )
            .environment(repository)
        } else if let session = selectedSession {
            ReviewView(
                session: session,
                onTryAgain: {
                    if let scenario = session.scenario {
                        selectedSession = nil
                        selectedScenario = scenario
                    }
                },
                onDone: {
                    selectedSession = nil
                }
            )
            .environment(repository)
        } else {
            WelcomeView()
        }
    }

    // MARK: - Scenario Detail

    private func scenarioDetailView(_ scenario: Scenario) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack {
                Image(systemName: scenario.icon)
                    .font(.largeTitle)
                    .foregroundColor(.qcAccent)

                VStack(alignment: .leading) {
                    Text(scenario.title)
                        .font(.title)
                        .fontWeight(.semibold)
                    Text(scenario.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            Divider()

            // Description
            Text(L10n.Home.practiceDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            // Tips
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.Home.tipsForScenario)
                    .font(.headline)

                ForEach(scenario.tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(tip)
                            .font(.body)
                    }
                }
            }
            .padding()
            .background(Color.qcSurface)
            .cornerRadius(Constants.Layout.mediumCornerRadius)
            .padding(.horizontal)

            Spacer()

            // Start button
            HStack {
                Spacer()
                Button(action: {
                    columnVisibility = .detailOnly
                }) {
                    Label(L10n.Home.startRecording, systemImage: "mic.fill")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.qcAccent)
                .keyboardShortcut("r", modifiers: .command)
                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.qcBackground)
    }

    // MARK: - Session Detail

    private func sessionDetailView(_ session: RehearsalSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let scenario = session.scenario {
                HStack {
                    Image(systemName: scenario.icon)
                        .font(.title)
                        .foregroundColor(.qcAccent)

                    VStack(alignment: .leading) {
                        Text(scenario.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(session.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if let scores = session.scores {
                HStack(spacing: 24) {
                    ScoreItem(label: "Overall", value: scores.overall)
                    ScoreItem(label: "Clarity", value: scores.clarity)
                    ScoreItem(label: "Pacing", value: scores.pacing)
                    ScoreItem(label: "Confidence", value: scores.confidence)
                }
                .padding()
                .background(Color.qcSurface)
                .cornerRadius(Constants.Layout.mediumCornerRadius)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.qcBackground)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .keyboardShortcut(",", modifiers: .command)
        }

        ToolbarItem(placement: .navigation) {
            Button {
                columnVisibility = columnVisibility == .all ? .detailOnly : .all
            } label: {
                Image(systemName: "sidebar.left")
            }
            .keyboardShortcut("s", modifiers: [.command, .control])
        }
    }

    // MARK: - Available Scenarios

    private var availableScenarios: [Scenario] {
        if featureGates.isPro {
            return Scenario.allScenarios
        } else {
            return Scenario.freeScenarios
        }
    }

    // MARK: - Pending Routes

    private func handlePendingRoutes() {
        if handlePendingSession() {
            return
        }
        handlePendingScenario()
    }

    private func handlePendingScenario() {
        guard let scenarioId = router.consumePendingScenarioId(),
              let scenario = Scenario.scenario(for: scenarioId) else {
            return
        }

        if featureGates.canAccessScenario(scenario) {
            selectedSession = nil
            selectedScenario = scenario
        } else {
            showingSettings = true
        }
    }

    private func handlePendingSession() -> Bool {
        guard let sessionId = router.consumePendingSessionId() else {
            return false
        }

        guard let session = repository.session(with: sessionId) else {
            missingSessionMessage = L10n.Routing.rehearsalUnavailableMessage
            showingMissingSessionAlert = true
            return true
        }

        selectedScenario = nil
        selectedSession = session
        return true
    }
}

// MARK: - Welcome View

private struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform")
                .font(.system(size: 64))
                .foregroundColor(.qcAccent)

            Text(L10n.Home.welcomeToQuietCoach)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(L10n.Home.selectScenarioFromSidebar)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Divider()
                .frame(width: 200)
                .padding(.vertical)

            VStack(alignment: .leading, spacing: 12) {
                KeyboardShortcutHint(shortcut: "⌘R", description: "Start recording")
                KeyboardShortcutHint(shortcut: "Space", description: "Pause/Resume")
                KeyboardShortcutHint(shortcut: "⌘,", description: "Settings")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.qcBackground)
    }
}

// MARK: - Score Item

private struct ScoreItem: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(scoreColor)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var scoreColor: Color {
        switch value {
        case 80...: return .green
        case 60..<80: return .yellow
        default: return .orange
        }
    }
}

// MARK: - Keyboard Shortcut Hint

private struct KeyboardShortcutHint: View {
    let shortcut: String
    let description: String

    var body: some View {
        HStack {
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)

            Text(description)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    MacHomeView()
        .environment(SessionRepository.placeholder)
        .environment(FeatureGates.shared)
        .frame(width: 1000, height: 700)
}
#endif
