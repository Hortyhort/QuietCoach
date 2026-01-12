// Localization.swift
// QuietCoach
//
// Type-safe localization infrastructure.
// All user-facing strings should be defined here for easy translation.

import Foundation
import SwiftUI

// MARK: - Localized Strings

/// Type-safe access to all localized strings
enum L10n {

    // MARK: - Common

    enum Common {
        static let appName = NSLocalizedString("common.app_name", value: "QuietCoach", comment: "App name")
        static let ok = NSLocalizedString("common.ok", value: "OK", comment: "OK button")
        static let cancel = NSLocalizedString("common.cancel", value: "Cancel", comment: "Cancel button")
        static let done = NSLocalizedString("common.done", value: "Done", comment: "Done button")
        static let next = NSLocalizedString("common.next", value: "Next", comment: "Next button")
        static let back = NSLocalizedString("common.back", value: "Back", comment: "Back button")
        static let tryAgain = NSLocalizedString("common.try_again", value: "Try Again", comment: "Try again button")
        static let close = NSLocalizedString("common.close", value: "Close", comment: "Close button")
        static let save = NSLocalizedString("common.save", value: "Save", comment: "Save button")
        static let delete = NSLocalizedString("common.delete", value: "Delete", comment: "Delete button")
        static let share = NSLocalizedString("common.share", value: "Share", comment: "Share button")
        static let settings = NSLocalizedString("common.settings", value: "Settings", comment: "Settings button")
    }

    // MARK: - Onboarding

    enum Onboarding {
        static let welcomeTitle = NSLocalizedString("onboarding.welcome_title", value: "Practice Speaking", comment: "Onboarding welcome title")
        static let welcomeSubtitle = NSLocalizedString("onboarding.welcome_subtitle", value: "Build confidence for conversations that matter", comment: "Onboarding welcome subtitle")
        static let getStarted = NSLocalizedString("onboarding.get_started", value: "Get Started", comment: "Get started button")
        static let skipIntro = NSLocalizedString("onboarding.skip_intro", value: "Skip Intro", comment: "Skip intro button")

        static let permissionTitle = NSLocalizedString("onboarding.permission_title", value: "Microphone Access", comment: "Permission screen title")
        static let permissionDescription = NSLocalizedString("onboarding.permission_description", value: "QuietCoach needs microphone access to record your practice sessions. All audio stays on your device.", comment: "Permission description")
        static let grantAccess = NSLocalizedString("onboarding.grant_access", value: "Grant Access", comment: "Grant access button")

        // Elevated onboarding flow
        static let everyoneHasConversations = NSLocalizedString("onboarding.everyone_has_conversations", value: "Everyone has conversations", comment: "Elevated onboarding title part 1")
        static let theyDread = NSLocalizedString("onboarding.they_dread", value: "they dread.", comment: "Elevated onboarding title part 2")
        static let continueButton = NSLocalizedString("onboarding.continue", value: "Continue", comment: "Continue button")
        static let whatIfYouCould = NSLocalizedString("onboarding.what_if_you_could", value: "What if you could", comment: "Elevated onboarding question part 1")
        static let practiceThemFirst = NSLocalizedString("onboarding.practice_them_first", value: "practice them first?", comment: "Elevated onboarding question part 2")
        static let showMe = NSLocalizedString("onboarding.show_me", value: "Show me", comment: "Show me button")
        static let pickOneThats = NSLocalizedString("onboarding.pick_one_thats", value: "Pick one that's been", comment: "Scenario selection part 1")
        static let onYourMind = NSLocalizedString("onboarding.on_your_mind", value: "on your mind", comment: "Scenario selection part 2")
        static let letsPractice = NSLocalizedString("onboarding.lets_practice", value: "Let's practice", comment: "Let's practice button")
        static let takeThirtySeconds = NSLocalizedString("onboarding.take_thirty_seconds", value: "Take 30 seconds.", comment: "Recording instruction part 1")
        static let sayWhatYouNeed = NSLocalizedString("onboarding.say_what_you_need", value: "Say what you need to say.", comment: "Recording instruction part 2")
        static let tapToFinish = NSLocalizedString("onboarding.tap_to_finish", value: "Tap to finish", comment: "Tap to finish recording")
        static let seeYouDidIt = NSLocalizedString("onboarding.see_you_did_it", value: "See? You did it.", comment: "Success message part 1")
        static let thatsTheWholeApp = NSLocalizedString("onboarding.thats_the_whole_app", value: "That's the whole app.", comment: "Success message part 2")

        // Simple onboarding
        static let practiceWordsTitle = NSLocalizedString("onboarding.practice_words_title", value: "Practice the words\nbefore they count.", comment: "Simple onboarding title")
        static let practiceWordsSubtitle = NSLocalizedString("onboarding.practice_words_subtitle", value: "Quiet Coach helps you rehearse hard conversations—privately, with instant feedback.", comment: "Simple onboarding subtitle")
        static let voiceStaysYours = NSLocalizedString("onboarding.voice_stays_yours", value: "Your voice stays yours.", comment: "Privacy screen title")
        static let voiceStaysYoursDescription = NSLocalizedString("onboarding.voice_stays_yours_description", value: "Audio is processed on your device. Optional iCloud sync and analytics are off by default.", comment: "Privacy screen description")
        static let onePermission = NSLocalizedString("onboarding.one_permission", value: "One permission.\nThat's it.", comment: "Permission screen title")
        static let onePermissionDescription = NSLocalizedString("onboarding.one_permission_description", value: "Quiet Coach needs microphone access to hear your rehearsal. You're always in control.", comment: "Permission screen description")
    }

    // MARK: - Home

    enum Home {
        static let title = NSLocalizedString("home.title", value: "Practice", comment: "Home screen title")
        static let recentSessions = NSLocalizedString("home.recent_sessions", value: "Recent Sessions", comment: "Recent sessions section title")
        static let noSessions = NSLocalizedString("home.no_sessions", value: "No sessions yet", comment: "Empty state for no sessions")
        static let startPractice = NSLocalizedString("home.start_practice", value: "Start Practice", comment: "Start practice button")

        static let scenariosTitle = NSLocalizedString("home.scenarios_title", value: "Choose a Scenario", comment: "Scenarios section title")
        static let proLabel = NSLocalizedString("home.pro_label", value: "PRO", comment: "Pro feature label")
        static let chooseScenario = NSLocalizedString("home.choose_scenario", value: "Choose a scenario", comment: "Choose scenario prompt")
        static let recent = NSLocalizedString("home.recent", value: "Recent", comment: "Recent section header")
        static let seeAll = NSLocalizedString("home.see_all", value: "See All", comment: "See all button")
        static let readyToPractice = NSLocalizedString("home.ready_to_practice", value: "Ready to practice?", comment: "First-time guidance title")
        static let firstTimeDescription = NSLocalizedString("home.first_time_description", value: "Choose a scenario above and rehearse what you want to say. We'll give you instant feedback on your delivery.", comment: "First-time guidance description")
        static let tipSpeakNaturally = NSLocalizedString("home.tip_speak_naturally", value: "Speak naturally, like you're in the real conversation", comment: "First-time guidance tip")
        static let tipSweetSpot = NSLocalizedString("home.tip_sweet_spot", value: "30-60 seconds is the sweet spot", comment: "First-time guidance tip")
        static let tipTryAgain = NSLocalizedString("home.tip_try_again", value: "Try again to refine one line", comment: "First-time guidance tip")

        // Mac/Spatial
        static let welcomeToQuietCoach = NSLocalizedString("home.welcome", value: "Welcome to Quiet Coach", comment: "Welcome message")
        static let selectScenarioFromSidebar = NSLocalizedString("home.select_scenario_sidebar", value: "Select a scenario from the sidebar to begin practicing difficult conversations.", comment: "Sidebar instruction")
        static let chooseScenarioFromSidebar = NSLocalizedString("home.choose_scenario_sidebar", value: "Choose a scenario from the sidebar to start practicing", comment: "Sidebar empty state")
        static let practiceDescription = NSLocalizedString("home.practice_description", value: "Practice expressing yourself in this scenario. Record your voice and get feedback on clarity, pacing, and confidence.", comment: "Practice description")
        static let tipsForScenario = NSLocalizedString("home.tips_for_scenario", value: "Tips for this scenario:", comment: "Tips section header")
        static let startRecording = NSLocalizedString("home.start_recording", value: "Start Recording", comment: "Start recording button")
        static let practiceInPrivateSpace = NSLocalizedString("home.practice_private_space", value: "Practice difficult conversations in your own private space", comment: "Spatial description")
        static let exitSpace = NSLocalizedString("home.exit_space", value: "Exit Space", comment: "Exit spatial space button")
        static let tips = NSLocalizedString("home.tips", value: "Tips", comment: "Tips label")
    }

    // MARK: - Recording

    enum Recording {
        static let tapToStart = NSLocalizedString("recording.tap_to_start", value: "Tap to Start", comment: "Tap to start recording instruction")
        static let recording = NSLocalizedString("recording.recording", value: "Recording", comment: "Recording status")
        static let tapToStop = NSLocalizedString("recording.tap_to_stop", value: "Tap to Stop", comment: "Tap to stop recording instruction")
        static let analyzing = NSLocalizedString("recording.analyzing", value: "Analyzing...", comment: "Analyzing status")

        static func duration(_ seconds: Int) -> String {
            let format = NSLocalizedString("recording.duration", value: "%d seconds", comment: "Recording duration in seconds")
            return String(format: format, seconds)
        }

        // Rehearsal
        static let cancelRehearsal = NSLocalizedString("recording.cancel_rehearsal", value: "Cancel Rehearsal", comment: "Cancel rehearsal button")
        static let keepRecording = NSLocalizedString("recording.keep_recording", value: "Keep Recording", comment: "Keep recording button")
        static let recordingWillBeDeleted = NSLocalizedString("recording.will_be_deleted", value: "Your recording will be deleted.", comment: "Recording deletion warning")
        static let rehearse = NSLocalizedString("recording.rehearse", value: "Rehearse", comment: "Rehearse navigation title")

        // States
        static let idle = NSLocalizedString("recording.idle", value: "Idle", comment: "Idle state")
        static let paused = NSLocalizedString("recording.paused", value: "Paused", comment: "Paused state")
        static let finished = NSLocalizedString("recording.finished", value: "Finished", comment: "Finished state")
    }

    // MARK: - History

    enum History {
        static let title = NSLocalizedString("history.title", value: "History", comment: "History screen title")
        static let searchPrompt = NSLocalizedString("history.search_prompt", value: "Search scenarios", comment: "History search prompt")
        static let sortBy = NSLocalizedString("history.sort_by", value: "Sort by", comment: "History sort label")
    }

    // MARK: - Feedback

    enum Feedback {
        static let title = NSLocalizedString("feedback.title", value: "Your Feedback", comment: "Feedback screen title")
        static let overallScore = NSLocalizedString("feedback.overall_score", value: "Overall Score", comment: "Overall score label")

        static let clarity = NSLocalizedString("feedback.clarity", value: "Clarity", comment: "Clarity score label")
        static let pacing = NSLocalizedString("feedback.pacing", value: "Pacing", comment: "Pacing score label")
        static let tone = NSLocalizedString("feedback.tone", value: "Tone", comment: "Tone score label")
        static let confidence = NSLocalizedString("feedback.confidence", value: "Confidence", comment: "Confidence score label")

        static let insights = NSLocalizedString("feedback.insights", value: "Insights", comment: "Insights section title")
        static let tryAgain = NSLocalizedString("feedback.try_again", value: "Practice Again", comment: "Practice again button")
        static let shareResult = NSLocalizedString("feedback.share_result", value: "Share Result", comment: "Share result button")

        // Score tiers
        static let tierExcellent = NSLocalizedString("feedback.tier.excellent", value: "Excellent", comment: "Excellent score tier")
        static let tierGood = NSLocalizedString("feedback.tier.good", value: "Good", comment: "Good score tier")
        static let tierDeveloping = NSLocalizedString("feedback.tier.developing", value: "Developing", comment: "Developing score tier")
        static let tierNeedsWork = NSLocalizedString("feedback.tier.needs_work", value: "Needs Work", comment: "Needs work score tier")

        // Review
        static let review = NSLocalizedString("feedback.review", value: "Review", comment: "Review navigation title")
        static let yourScores = NSLocalizedString("feedback.your_scores", value: "Your Scores", comment: "Your scores section title")
        static let coachingNotes = NSLocalizedString("feedback.coaching_notes", value: "Coaching Notes", comment: "Coaching notes section title")
        static let howScoresWork = NSLocalizedString("feedback.how_scores_work", value: "How Scores Work", comment: "How scores work navigation title")
        static let shareYourProgress = NSLocalizedString("feedback.share_progress", value: "Share your progress", comment: "Share progress prompt")

        // Coach
        static let tryAgainFocus = NSLocalizedString("feedback.try_again_focus", value: "Try Again Focus", comment: "Try again focus card header")
        static let structureGuide = NSLocalizedString("feedback.structure_guide", value: "Structure Guide", comment: "Structure guide section header")
        static let practiced = NSLocalizedString("feedback.practiced", value: "Practiced", comment: "Practiced label on share card")
        static let audioOnlyNote = NSLocalizedString("feedback.audio_only_note", value: "Audio-only feedback. Turn on on-device transcription (opt-in) for richer coaching.", comment: "Audio-only feedback note in review")
        static let audioOnlyInsight = NSLocalizedString("feedback.audio_only_insight", value: "Audio-only analysis. On-device transcription is opt-in for richer feedback.", comment: "Insight shown when transcription is unavailable")
        static let anchorPhraseTitle = NSLocalizedString("feedback.anchor_phrase_title", value: "Anchor Phrase", comment: "Anchor phrase section title")
        static let anchorPhraseSubtitle = NSLocalizedString("feedback.anchor_phrase_subtitle", value: "One phrase you'll say next time", comment: "Anchor phrase section subtitle")
        static let anchorPhrasePlaceholder = NSLocalizedString("feedback.anchor_phrase_placeholder", value: "e.g., \"I need to share something important...\"", comment: "Anchor phrase placeholder")
    }

    // MARK: - Scores Explanation

    enum ScoreExplanation {
        static let clarityDescription = NSLocalizedString("score.clarity.description", value: "Based on pause patterns and silence. Clear speakers pause intentionally.", comment: "Clarity score explanation")
        static let pacingDescription = NSLocalizedString("score.pacing.description", value: "Based on rhythm—phrases per minute. Too fast or slow affects your score.", comment: "Pacing score explanation")
        static let toneDescription = NSLocalizedString("score.tone.description", value: "Based on volume stability. Consistent volume sounds calm and controlled.", comment: "Tone score explanation")
        static let confidenceDescription = NSLocalizedString("score.confidence.description", value: "Based on volume level and consistency. Steady delivery sounds assured.", comment: "Confidence score explanation")
    }

    // MARK: - Settings

    enum Settings {
        static let title = NSLocalizedString("settings.title", value: "Settings", comment: "Settings screen title")
        static let account = NSLocalizedString("settings.account", value: "Account", comment: "Account section")
        static let subscription = NSLocalizedString("settings.subscription", value: "Subscription", comment: "Subscription setting")
        static let restorePurchases = NSLocalizedString("settings.restore_purchases", value: "Restore Purchases", comment: "Restore purchases button")

        static let preferences = NSLocalizedString("settings.preferences", value: "Preferences", comment: "Preferences section")
        static let hapticFeedback = NSLocalizedString("settings.haptic_feedback", value: "Haptic Feedback", comment: "Haptic feedback toggle")
        static let soundEffects = NSLocalizedString("settings.sound_effects", value: "Sound Effects", comment: "Sound effects toggle")

        static let about = NSLocalizedString("settings.about", value: "About", comment: "About section")
        static let version = NSLocalizedString("settings.version", value: "Version", comment: "Version label")
        static let privacyPolicy = NSLocalizedString("settings.privacy_policy", value: "Privacy Policy", comment: "Privacy policy link")
        static let termsOfService = NSLocalizedString("settings.terms_of_service", value: "Terms of Service", comment: "Terms of service link")
        static let sendFeedback = NSLocalizedString("settings.send_feedback", value: "Send Feedback", comment: "Send feedback button")

        // Sections
        static let sharing = NSLocalizedString("settings.sharing", value: "Sharing", comment: "Sharing section")
        static let showWatermark = NSLocalizedString("settings.show_watermark", value: "Show watermark on share cards", comment: "Show watermark toggle")
        static let data = NSLocalizedString("settings.data", value: "Data", comment: "Data section")
        static let sessions = NSLocalizedString("settings.sessions", value: "Sessions", comment: "Sessions label")
        static let storageUsed = NSLocalizedString("settings.storage_used", value: "Storage used", comment: "Storage used label")
        static let deleteAllData = NSLocalizedString("settings.delete_all_data", value: "Delete All Data", comment: "Delete all data button")
        static let deleteAll = NSLocalizedString("settings.delete_all", value: "Delete All", comment: "Delete all confirmation button")
        static let deleteConfirmation = NSLocalizedString("settings.delete_confirmation", value: "This will delete all your rehearsal sessions and audio files. This cannot be undone.", comment: "Delete confirmation message")
        static let support = NSLocalizedString("settings.support", value: "Support", comment: "Support section")
        static let privacyFooter = NSLocalizedString("settings.privacy_footer", value: "Audio is processed on your device. Optional iCloud sync and analytics are off by default.", comment: "Privacy footer message")
        static let transcriptionOptInDescription = NSLocalizedString("settings.transcription_opt_in_description", value: "On-device, opt-in (off by default) for richer coaching", comment: "Transcription description")
        static let transcriptionOffFooter = NSLocalizedString("settings.transcription_off_footer", value: "When transcription is off, coaching uses audio-only metrics and no transcript is saved.", comment: "Transcription off footer")

        // Pro
        static let quietCoachPro = NSLocalizedString("settings.quiet_coach_pro", value: "Quiet Coach Pro", comment: "Quiet Coach Pro label")
        static let active = NSLocalizedString("settings.active", value: "Active", comment: "Active status label")
        static let upgradeToPro = NSLocalizedString("settings.upgrade_to_pro", value: "Upgrade to Pro", comment: "Upgrade to Pro button")
    }

    // MARK: - Subscription

    enum Subscription {
        static let upgradeTitle = NSLocalizedString("subscription.upgrade_title", value: "Upgrade to Pro", comment: "Upgrade screen title")
        static let features = NSLocalizedString("subscription.features", value: "Pro Features", comment: "Pro features section")
        static let subscribe = NSLocalizedString("subscription.subscribe", value: "Subscribe", comment: "Subscribe button")
        static let restoring = NSLocalizedString("subscription.restoring", value: "Restoring...", comment: "Restoring status")

        static func pricePerMonth(_ price: String) -> String {
            let format = NSLocalizedString("subscription.price_per_month", value: "%@ / month", comment: "Price per month")
            return String(format: format, price)
        }

        // Pro upgrade
        static let quietCoachPro = NSLocalizedString("subscription.quiet_coach_pro", value: "Quiet Coach Pro", comment: "Quiet Coach Pro title")
        static let unlockPotential = NSLocalizedString("subscription.unlock_potential", value: "Unlock your full potential", comment: "Unlock potential subtitle")
        static let unableToLoad = NSLocalizedString("subscription.unable_to_load", value: "Unable to load subscription options", comment: "Unable to load error")
        static let loading = NSLocalizedString("subscription.loading", value: "Loading...", comment: "Loading status")
        static let savePercent = NSLocalizedString("subscription.save_percent", value: "Save 58%", comment: "Save percentage badge")
    }

    // MARK: - Routing

    enum Routing {
        static let rehearsalUnavailableTitle = NSLocalizedString("routing.rehearsal_unavailable_title", value: "Rehearsal Unavailable", comment: "Alert title when session is missing")
        static let rehearsalUnavailableMessage = NSLocalizedString("routing.rehearsal_unavailable_message", value: "This rehearsal is no longer available on this device.", comment: "Alert message when session is missing")
    }

    // MARK: - Playback

    enum Playback {
        static let unavailableTitle = NSLocalizedString("playback.unavailable_title", value: "Playback unavailable", comment: "Playback error title")
        static let tryReloading = NSLocalizedString("playback.try_reloading", value: "Try Reloading", comment: "Try reloading button")
    }

    // MARK: - Errors

    enum Errors {
        static let microphoneAccessDenied = NSLocalizedString("error.microphone_denied", value: "Microphone access is required to record your practice sessions.", comment: "Microphone access denied error")
        static let recordingFailed = NSLocalizedString("error.recording_failed", value: "Recording failed. Please try again.", comment: "Recording failed error")
        static let analysisFailed = NSLocalizedString("error.analysis_failed", value: "Could not analyze your recording. Audio-only feedback will be provided.", comment: "Analysis failed error")
        static let saveFailed = NSLocalizedString("error.save_failed", value: "Could not save your session. Please try again.", comment: "Save failed error")
        static let networkError = NSLocalizedString("error.network", value: "Please check your internet connection and try again.", comment: "Network error")
    }

    // MARK: - Accessibility

    enum Accessibility {
        static let recordButton = NSLocalizedString("accessibility.record_button", value: "Record", comment: "Record button accessibility label")
        static let stopButton = NSLocalizedString("accessibility.stop_button", value: "Stop Recording", comment: "Stop button accessibility label")
        static let playButton = NSLocalizedString("accessibility.play_button", value: "Play Recording", comment: "Play button accessibility label")
        static let pauseButton = NSLocalizedString("accessibility.pause_button", value: "Pause", comment: "Pause button accessibility label")

        static func scoreValue(_ type: String, _ value: Int) -> String {
            let format = NSLocalizedString("accessibility.score_value", value: "%@ score: %d out of 100", comment: "Score value announcement")
            return String(format: format, type, value)
        }
    }

    // MARK: - Privacy

    enum Privacy {
        static let title = NSLocalizedString("privacy.title", value: "Privacy Settings", comment: "Privacy settings title")
        static let analytics = NSLocalizedString("privacy.analytics", value: "Analytics", comment: "Analytics toggle label")
        static let analyticsDescription = NSLocalizedString("privacy.analytics_description", value: "Help improve QuietCoach by sharing anonymous usage data", comment: "Analytics description")
        static let crashReporting = NSLocalizedString("privacy.crash_reporting", value: "Crash Reporting", comment: "Crash reporting toggle label")
        static let crashReportingDescription = NSLocalizedString("privacy.crash_reporting_description", value: "Automatically send crash reports to help fix bugs", comment: "Crash reporting description")
        static let performance = NSLocalizedString("privacy.performance", value: "Performance Monitoring", comment: "Performance monitoring toggle label")
        static let performanceDescription = NSLocalizedString("privacy.performance_description", value: "Share anonymous performance data to improve app speed", comment: "Performance monitoring description")
        static let enableAll = NSLocalizedString("privacy.enable_all", value: "Enable All", comment: "Enable all button")
        static let disableAll = NSLocalizedString("privacy.disable_all", value: "Disable All", comment: "Disable all button")
        static let policyTitle = NSLocalizedString("privacy.policy_title", value: "Privacy Policy", comment: "Privacy policy title")
        static let consentTitle = NSLocalizedString("privacy.consent_title", value: "Your Privacy Matters", comment: "Privacy consent title")
        static let consentDescription = NSLocalizedString("privacy.consent_description", value: "QuietCoach respects your privacy. All audio recordings stay on your device. Choose what data to share:", comment: "Privacy consent description")
        static let continueButton = NSLocalizedString("privacy.continue", value: "Continue", comment: "Continue button")
    }

    // MARK: - Network

    enum Network {
        static let offline = NSLocalizedString("network.offline", value: "You're Offline", comment: "Offline status")
        static let offlineDescription = NSLocalizedString("network.offline_description", value: "Some features may be limited", comment: "Offline description")
        static let reconnecting = NSLocalizedString("network.reconnecting", value: "Reconnecting...", comment: "Reconnecting status")
        static let connected = NSLocalizedString("network.connected", value: "Connected", comment: "Connected status")
    }

    // MARK: - Subscription Status

    enum SubscriptionStatus {
        static let active = NSLocalizedString("subscription.status.active", value: "Pro Active", comment: "Active subscription status")
        static let expired = NSLocalizedString("subscription.status.expired", value: "Subscription Expired", comment: "Expired subscription status")
        static let unknown = NSLocalizedString("subscription.status.unknown", value: "Verifying...", comment: "Unknown subscription status")
        static let offlineWarning = NSLocalizedString("subscription.offline_warning", value: "Subscription status may be outdated", comment: "Offline subscription warning")
        static let verifyLater = NSLocalizedString("subscription.verify_later", value: "We'll verify your subscription when you're back online", comment: "Verify later message")
    }
}

// MARK: - String Formatting Helpers

extension L10n {
    /// Format a score for display
    static func formatScore(_ score: Int) -> String {
        "\(score)"
    }

    /// Format duration for display
    static func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60

        if minutes > 0 {
            let format = NSLocalizedString("duration.minutes_seconds", value: "%d:%02d", comment: "Duration format")
            return String(format: format, minutes, secs)
        } else {
            return Recording.duration(Int(seconds))
        }
    }
}

// MARK: - SwiftUI Text Extensions

extension Text {
    /// Create localized text from L10n string
    init(localized string: String) {
        self.init(verbatim: string)
    }
}
