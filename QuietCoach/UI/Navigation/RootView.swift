// RootView.swift
// QuietCoach
//
// The navigation root. Handles onboarding state and main app flow.

import SwiftUI
import SwiftData

struct RootView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var repository: SessionRepository
    @StateObject private var featureGates = FeatureGates.shared

    // MARK: - Initialization

    init() {
        // SessionRepository will be properly initialized after modelContext is available
        _repository = StateObject(wrappedValue: SessionRepository.placeholder)
    }

    // MARK: - Body

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                HomeView()
                    .environmentObject(repository)
                    .environmentObject(featureGates)
            } else {
                OnboardingView(onComplete: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        hasCompletedOnboarding = true
                    }
                })
            }
        }
        .onAppear {
            // Initialize repository with actual model context
            repository.configure(with: modelContext)
        }
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .modelContainer(for: RehearsalSession.self, inMemory: true)
}
