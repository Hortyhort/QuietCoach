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

    // MARK: - State

    @State private var navigationPath = NavigationPath()
    @State private var showingSettings = false
    @State private var streakTracker = StreakTracker.shared
    @State private var showingStreakCelebration: StreakTracker.Milestone?

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: Constants.Layout.sectionSpacing) {
                    // Header
                    headerSection

                    // Scenarios
                    scenariosSection

                    // Recent Sessions
                    if !repository.recentSessions.isEmpty {
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
                    .accessibilityLabel("Settings")
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
                        // Record practice for streak tracking
                        let previousStreak = streakTracker.currentStreak
                        streakTracker.recordPractice()

                        // Check for new milestone
                        if let milestone = streakTracker.currentMilestone,
                           milestone.rawValue == streakTracker.currentStreak,
                           streakTracker.currentStreak > previousStreak {
                            showingStreakCelebration = milestone
                        }

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
                            navigationPath.removeLast()
                            // Small delay to allow navigation to settle
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
            // Sync streak from existing sessions
            streakTracker.syncFromSessions(repository.sessions)
        }
        .overlay {
            // Streak milestone celebration
            if let milestone = showingStreakCelebration {
                StreakCelebrationOverlay(milestone: milestone) {
                    withAnimation {
                        showingStreakCelebration = nil
                    }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Constants.App.tagline)
                .font(.qcSubheadline)
                .foregroundColor(.qcTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Streak tracking
            StreakHeaderView(tracker: streakTracker)
        }
    }

    // MARK: - Scenarios Section

    private var scenariosSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose a scenario")
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

    // MARK: - Recent Sessions Section

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent")
                    .font(.qcTitle3)
                    .foregroundColor(.qcTextPrimary)

                Spacer()

                if repository.sessionCount > 3 {
                    Button("See All") {
                        // TODO: Navigate to full history
                    }
                    .font(.qcButtonSmall)
                    .foregroundColor(.qcAccent)
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

                if let scores = session.scores {
                    Text("\(scores.overall)")
                        .font(.qcScoreSmall)
                        .foregroundColor(scoreColor(for: scores.overall))
                }

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
        .accessibilityLabel("\(session.scenario?.title ?? "Session"). \(session.formattedDate). Score: \(session.scores?.overall ?? 0)")
        .accessibilityHint("Double tap to review this session")
    }

    private func scoreColor(for score: Int) -> Color {
        switch score {
        case 85...100: return .qcMoodCelebration
        case 70..<85: return .qcMoodSuccess
        case 50..<70: return .qcMoodReady
        default: return .qcMoodEngaged
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environment(SessionRepository.placeholder)
        .environment(FeatureGates.shared)
}
