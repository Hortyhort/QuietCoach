// HomeView.swift
// QuietCoach
//
// The heart of the app. Scenario selection and session history.
// Where rehearsals begin.

import SwiftUI

struct HomeView: View {

    // MARK: - Environment

    @Environment(SessionRepository.self) private var repository
    @Environment(FeatureGates.self) private var featureGates
    @Environment(AppRouter.self) private var router

    // MARK: - State

    @State private var navigationPath = NavigationPath()
    @State private var showingSettings = false
    @State private var showingMissingSessionAlert = false
    @State private var missingSessionMessage = ""

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: Constants.Layout.sectionSpacing) {
                    // Header
                    headerSection

                    // Scenarios
                    scenariosSection

                    // First-time user guidance or recent sessions
                    if repository.recentSessions.isEmpty {
                        firstTimeGuidanceSection
                    } else {
                        recentSessionsSection
                    }
                }
                .padding(.horizontal, Constants.Layout.horizontalPadding)
                .padding(.top, 16)
            }
            .background {
                // Ambient mesh gradient background
                AmbientMeshGradient()
                    .ignoresSafeArea()
            }
            .navigationTitle(Constants.App.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.qcTextSecondary)
                    }
                    .accessibilityLabel(L10n.Common.settings)
                    .accessibilityHint("Double tap to open settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environment(repository)
                    .environment(featureGates)
            }
            .navigationDestination(for: Scenario.self) { scenario in
                RehearseView(
                    scenario: scenario,
                    onComplete: { session in
                        // Navigate to review
                        navigationPath.append(session)
                    },
                    onCancel: {
                        navigationPath.removeLast()
                    }
                )
                .environment(repository)
            }
            .navigationDestination(for: RehearsalSession.self) { session in
                ReviewView(
                    session: session,
                    onTryAgain: {
                        // Pop back and push rehearse again with same scenario
                        if let scenario = session.scenario {
                            navigationPath = NavigationPath()
                            // Small delay to allow navigation to settle
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                navigationPath.append(scenario)
                            }
                        }
                    },
                    onDone: {
                        // Return to home
                        navigationPath = NavigationPath()
                    }
                )
                .environment(repository)
            }
        }
        .preferredColorScheme(.dark)
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
        // MARK: - Keyboard Shortcuts (iPad/Mac)
        .background {
            // Hidden buttons to capture keyboard shortcuts
            keyboardShortcutButtons
        }
    }

    // MARK: - Keyboard Shortcut Buttons

    @ViewBuilder
    private var keyboardShortcutButtons: some View {
        Group {
            // Cmd+N: New practice session
            Button("") {
                startQuickPractice()
            }
            .keyboardShortcut("n", modifiers: .command)

            // Cmd+,: Settings
            Button("") {
                showingSettings = true
            }
            .keyboardShortcut(",", modifiers: .command)

            // Cmd+H: History
            Button("") {
                router.presentHistory()
            }
            .keyboardShortcut("h", modifiers: .command)

            // Cmd+1-4: Quick scenario access
            ForEach(Array(availableScenarios.prefix(4).enumerated()), id: \.element.id) { index, scenario in
                Button("") {
                    if featureGates.canAccessScenario(scenario) {
                        Haptics.selectScenario()
                        navigationPath.append(scenario)
                    }
                }
                .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
            }
        }
        .opacity(0)
        .frame(width: 0, height: 0)
    }

    // MARK: - Quick Practice

    private func startQuickPractice() {
        // Start with the first available scenario
        if let firstScenario = availableScenarios.first {
            Haptics.selectScenario()
            SoundManager.shared.play(.ready)
            navigationPath.append(firstScenario)
        }
    }

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
            routeToScenario(scenario)
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

        routeToSession(session)
        return true
    }

    private func routeToScenario(_ scenario: Scenario) {
        router.presentedSheet = nil
        navigationPath = NavigationPath()
        DispatchQueue.main.async {
            navigationPath.append(scenario)
        }
    }

    private func routeToSession(_ session: RehearsalSession) {
        router.presentedSheet = nil
        navigationPath = NavigationPath()
        DispatchQueue.main.async {
            navigationPath.append(session)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Constants.App.tagline)
                .font(.qcSubheadline)
                .foregroundColor(.qcTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Scenarios Section

    private var scenariosSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.Home.chooseScenario)
                .font(.qcTitle3)
                .foregroundColor(.qcTextPrimary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(availableScenarios) { scenario in
                    ScenarioCard(
                        scenario: scenario,
                        isLocked: !featureGates.canAccessScenario(scenario)
                    ) {
                        if featureGates.canAccessScenario(scenario) {
                            Haptics.selectScenario()
                            navigationPath.append(scenario)
                        } else {
                            // Show upgrade prompt
                            Haptics.warning()
                            showingSettings = true
                        }
                    }
                }
            }
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

    // MARK: - First Time Guidance Section

    private var firstTimeGuidanceSection: some View {
        VStack(spacing: 20) {
            // Illustration
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.qcAccent, .qcMoodReady],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .qcBreatheEffect(isActive: true)

            VStack(spacing: 8) {
                Text(L10n.Home.readyToPractice)
                    .font(.qcTitle3)
                    .foregroundColor(.qcTextPrimary)

                Text(L10n.Home.firstTimeDescription)
                    .font(.qcSubheadline)
                    .foregroundColor(.qcTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Tips
            VStack(alignment: .leading, spacing: 12) {
                tipRow(icon: "mic.fill", text: L10n.Home.tipSpeakNaturally)
                tipRow(icon: "clock.fill", text: L10n.Home.tipSweetSpot)
                tipRow(icon: "arrow.clockwise", text: L10n.Home.tipTryAgain)
            }
            .padding(16)
            .background(Color.qcSurface)
            .qcCardRadius()
        }
        .padding(.vertical, 24)
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.qcAccent)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(text)
                .font(.qcSubheadline)
                .foregroundColor(.qcTextSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tip: \(text)")
    }

    // MARK: - Recent Sessions Section

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L10n.Home.recent)
                    .font(.qcTitle3)
                    .foregroundColor(.qcTextPrimary)

                Spacer()

                if repository.sessionCount > 3 {
                    Button(L10n.Home.seeAll) {
                        router.presentHistory()
                    }
                    .font(.qcButtonSmall)
                    .foregroundColor(.qcAccent)
                    .accessibilityLabel("See all sessions")
                    .accessibilityHint("Double tap to view your complete history")
                }
            }

            VStack(spacing: 8) {
                ForEach(repository.recentSessions.prefix(3)) { session in
                    SessionRow(session: session) {
                        navigationPath.append(session)
                    }
                }
            }
        }
    }
}

// MARK: - Scenario Card

struct ScenarioCard: View {
    let scenario: Scenario
    var isLocked: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            LiquidGlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: scenario.icon)
                            .font(.system(size: 24))
                            .foregroundColor(isLocked ? .qcTextTertiary : .qcMoodReady)
                            .qcBreatheEffect(isActive: !isLocked)

                        Spacer()

                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.qcTextTertiary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(scenario.title)
                            .font(.qcBodyMedium)
                            .foregroundColor(isLocked ? .qcTextTertiary : .qcTextPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Text(scenario.subtitle)
                            .font(.qcCaption)
                            .foregroundColor(.qcTextSecondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }
            .opacity(isLocked ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .qcCardScrollTransition()
        .accessibilityLabel("\(scenario.title). \(isLocked ? "Locked. Upgrade to Pro to access." : scenario.subtitle)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: RehearsalSession
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let scenario = session.scenario {
                    Image(systemName: scenario.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.qcAccent)
                        .frame(width: 32)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.scenario?.title ?? "Unknown")
                        .font(.qcBody)
                        .foregroundColor(.qcTextPrimary)

                    Text(session.formattedDate)
                        .font(.qcCaption)
                        .foregroundColor(.qcTextTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.qcTextTertiary)
            }
            .padding(12)
            .background(Color.qcSurface)
            .qcSmallRadius()
        }
        .qcPressEffect()
        .qcScrollTransition()
        .accessibilityLabel("\(session.scenario?.title ?? "Session"). \(session.formattedDate)")
        .accessibilityHint("Double tap to review this session")
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environment(SessionRepository.placeholder)
        .environment(FeatureGates.shared)
}
