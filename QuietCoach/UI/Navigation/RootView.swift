// RootView.swift
// QuietCoach
//
// The navigation root. Handles onboarding state and main app flow.
// Adapts to platform with native experiences for iOS, macOS, watchOS, and visionOS.

import SwiftUI
import SwiftData

struct RootView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var repository = SessionRepository.placeholder
    private let featureGates = FeatureGates.shared

    // MARK: - Body

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainContent
            } else {
                ElevatedOnboardingView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        hasCompletedOnboarding = true
                    }
                }
            }
        }
        .onAppear {
            // Initialize repository with actual model context
            repository.configure(with: modelContext)
        }
    }

    // MARK: - Platform-Specific Main Content

    @ViewBuilder
    private var mainContent: some View {
        #if os(macOS)
        MacHomeView()
            .environment(repository)
            .environment(featureGates)
        #elseif os(visionOS)
        SpatialHomeView()
            .environment(repository)
            .environment(featureGates)
        #else
        HomeView()
            .environment(repository)
            .environment(featureGates)
        #endif
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .modelContainer(for: RehearsalSession.self, inMemory: true)
}
