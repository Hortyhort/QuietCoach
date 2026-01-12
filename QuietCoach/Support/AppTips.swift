// AppTips.swift
// QuietCoach
//
// TipKit integration for contextual feature discovery.
// Tips appear at the right moment, not as interruptions.

import TipKit

// MARK: - Recording Tips

/// Tip for long-press recording start
struct CountdownRecordingTip: Tip {
    var title: Text {
        Text("Tap and hold for countdown")
    }

    var message: Text? {
        Text("Long press the record button to start with a 3-second countdown, giving you time to prepare.")
    }

    var image: Image? {
        Image(systemName: "hand.tap.fill")
    }

    var options: [TipOption] {
        MaxDisplayCount(3)
    }
}

/// Tip about audio quality
struct AudioQualityTip: Tip {
    var title: Text {
        Text("Best recording quality")
    }

    var message: Text? {
        Text("Hold your device 6-8 inches from your face in a quiet room for the clearest audio.")
    }

    var image: Image? {
        Image(systemName: "waveform.badge.mic")
    }

    var options: [TipOption] {
        MaxDisplayCount(2)
    }
}

// MARK: - Pro Feature Tips

/// Tip about Pro scenarios
struct ProScenariosTip: Tip {
    var title: Text {
        Text("More scenarios available")
    }

    var message: Text? {
        Text("Pro members get 6 additional scenarios for negotiations, difficult conversations, and more.")
    }

    var image: Image? {
        Image(systemName: "star.fill")
    }

    var rules: [Rule] {
        #Rule(Self.$sessionsCompleted) { $0 >= 3 }
    }

    @Parameter
    static var sessionsCompleted: Int = 0

    var options: [TipOption] {
        MaxDisplayCount(2)
    }
}

// MARK: - Transcription Tip

/// Tip about transcript feature
struct TranscriptionTip: Tip {
    var title: Text {
        Text("Get a transcript")
    }

    var message: Text? {
        Text("Enable transcription in Settings to see a written version of your rehearsal. All processing happens on your device.")
    }

    var image: Image? {
        Image(systemName: "text.quote")
    }

    var options: [TipOption] {
        MaxDisplayCount(2)
    }
}

// MARK: - Playback Tip

/// Tip for audio playback
struct PlaybackTip: Tip {
    var title: Text {
        Text("Listen to yourself")
    }

    var message: Text? {
        Text("Tap play to hear your rehearsal. Listening back helps you notice patterns.")
    }

    var image: Image? {
        Image(systemName: "play.circle.fill")
    }

    var options: [TipOption] {
        MaxDisplayCount(2)
    }
}

// MARK: - Structure Card Tip

/// Tip about using the structure card
struct StructureCardTip: Tip {
    var title: Text {
        Text("Use the structure")
    }

    var message: Text? {
        Text("Swipe up to see a conversation structure. It gives you a framework without scripting every word.")
    }

    var image: Image? {
        Image(systemName: "list.bullet.rectangle")
    }

    var options: [TipOption] {
        MaxDisplayCount(2)
    }
}

// MARK: - Share Tip

/// Tip about sharing progress
struct ShareProgressTip: Tip {
    var title: Text {
        Text("Share a rehearsal card")
    }

    var message: Text? {
        Text("Share a rehearsal card if you want encouragement or support.")
    }

    var image: Image? {
        Image(systemName: "square.and.arrow.up")
    }

    var rules: [Rule] {
        #Rule(Self.$highScore) { $0 >= 80 }
    }

    @Parameter
    static var highScore: Int = 0

    var options: [TipOption] {
        MaxDisplayCount(2)
    }
}

// MARK: - Siri Integration Tip

/// Tip about Siri shortcuts
struct SiriIntegrationTip: Tip {
    var title: Text {
        Text("Practice with Siri")
    }

    var message: Text? {
        Text("Say \"Hey Siri, practice a conversation with Quiet Coach\" to start quickly.")
    }

    var image: Image? {
        Image(systemName: "mic.circle.fill")
    }

    var rules: [Rule] {
        #Rule(Self.$sessionsCompleted) { $0 >= 5 }
    }

    @Parameter
    static var sessionsCompleted: Int = 0

    var options: [TipOption] {
        MaxDisplayCount(1)
    }
}

// MARK: - Try Again Tip

/// Tip about the Try Again feature
struct TryAgainTip: Tip {
    var title: Text {
        Text("Practice makes progress")
    }

    var message: Text? {
        Text("Tap 'Try Again' to rehearse the same scenario. Each attempt builds muscle memory.")
    }

    var image: Image? {
        Image(systemName: "arrow.counterclockwise")
    }

    var options: [TipOption] {
        MaxDisplayCount(2)
    }
}

// MARK: - First Practice Tip

/// Encouragement tip for first-time users
struct FirstPracticeTip: Tip {
    var title: Text {
        Text("You've got this")
    }

    var message: Text? {
        Text("Your first rehearsal doesn't need to be perfect. Just speak naturally and see what happens.")
    }

    var image: Image? {
        Image(systemName: "heart.fill")
    }

    var options: [TipOption] {
        MaxDisplayCount(1)
    }
}

// MARK: - Score Improvement Tip

/// Tip about improving scores
struct ScoreImprovementTip: Tip {
    var title: Text {
        Text("Focus on one thing")
    }

    var message: Text? {
        Text("Pick one coaching note to work on. Small improvements compound over time.")
    }

    var image: Image? {
        Image(systemName: "scope")
    }

    var rules: [Rule] {
        #Rule(Self.$practiceCount) { $0 >= 2 }
    }

    @Parameter
    static var practiceCount: Int = 0

    var options: [TipOption] {
        MaxDisplayCount(2)
    }
}

// MARK: - Tip Configuration

/// Configure TipKit for the app
@MainActor
enum AppTipsConfiguration {

    /// Configure tips on app launch
    static func configure() {
        try? Tips.configure([
            .displayFrequency(.daily),
            .datastoreLocation(.applicationDefault)
        ])
    }

    /// Reset all tips (for testing)
    static func resetAll() {
        try? Tips.resetDatastore()
    }

    /// Update session count for tip rules
    static func recordSessionCompleted() {
        ProScenariosTip.sessionsCompleted += 1
        SiriIntegrationTip.sessionsCompleted += 1
        ScoreImprovementTip.practiceCount += 1
    }

    /// Update high score for tip rules
    static func recordHighScore(_ score: Int) {
        if score > ShareProgressTip.highScore {
            ShareProgressTip.highScore = score
        }
    }

    /// Record that user was active today (for future personalization)
    static func recordDayActive() {}
}
