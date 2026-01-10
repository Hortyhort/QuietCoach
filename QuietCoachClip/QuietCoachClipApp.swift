// QuietCoachClipApp.swift
// QuietCoach App Clip
//
// Instant practice experience. No download required.
// Users can try one scenario immediately.

import SwiftUI
import AppIntents

@main
struct QuietCoachClipApp: App {

    // MARK: - State

    @State private var hasCompletedSession = false
    @State private var invocationURL: URL?

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ClipExperienceView(hasCompletedSession: $hasCompletedSession)
                .preferredColorScheme(.dark)
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    // Handle App Clip invocation URL
                    invocationURL = activity.webpageURL
                }
        }
    }
}
