// Scenario.swift
// QuietCoach
//
// The heart of what we practice. Each scenario is a specific
// conversation type with tailored coaching guidance.

import Foundation
import SwiftUI

struct Scenario: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let promptText: String
    let coachingHint: String
    let category: Category
    let isPro: Bool
    let structureCard: StructureCard
    let hapticStyle: HapticStyle

    enum Category: String, CaseIterable {
        case boundaries = "Boundaries"
        case career = "Career"
        case relationships = "Relationships"
        case difficult = "Difficult"

        var color: Color {
            switch self {
            case .boundaries: return .blue
            case .career: return .green
            case .relationships: return .pink
            case .difficult: return .orange
            }
        }
    }

    enum HapticStyle {
        case firm       // Boundaries — confident, definitive
        case soft       // Relationships — gentle, warm
        case steady     // Negotiations — measured, calm
        case standard   // Default

        @MainActor
        func trigger() {
            switch self {
            case .firm: Haptics.firmFeedback()
            case .soft: Haptics.softFeedback()
            case .steady: Haptics.steadyFeedback()
            case .standard: Haptics.buttonPress()
            }
        }
    }

    struct StructureCard: Hashable {
        let opener: String
        let context: String
        let ask: String
        let nextStep: String
    }
}

// MARK: - Scenario Library

extension Scenario {

    static let allScenarios: [Scenario] = [

        // MARK: - Free Scenarios (6)

        Scenario(
            id: "set-boundary",
            title: "Set a Boundary",
            subtitle: "Say no with clarity",
            icon: "hand.raised.fill",
            promptText: "Practice saying no to something you've been avoiding.",
            coachingHint: "Start with what you need, not with an apology.",
            category: .boundaries,
            isPro: false,
            structureCard: StructureCard(
                opener: "I need to talk about something important.",
                context: "When [specific situation happens]...",
                ask: "I need [your boundary].",
                nextStep: "Can we agree on this going forward?"
            ),
            hapticStyle: .firm
        ),

        Scenario(
            id: "ask-raise",
            title: "Ask for a Raise",
            subtitle: "Know your worth",
            icon: "chart.line.uptrend.xyaxis",
            promptText: "Practice asking for a raise or promotion.",
            coachingHint: "Lead with your contributions, not your needs.",
            category: .career,
            isPro: false,
            structureCard: StructureCard(
                opener: "I'd like to discuss my compensation.",
                context: "Over the past [time], I've [achievements].",
                ask: "I'm asking for [specific amount].",
                nextStep: "What would you need to see?"
            ),
            hapticStyle: .steady
        ),

        Scenario(
            id: "give-feedback",
            title: "Give Critical Feedback",
            subtitle: "Be honest, be kind",
            icon: "text.bubble.fill",
            promptText: "Practice delivering constructive criticism.",
            coachingHint: "Be specific about behavior, not the person.",
            category: .career,
            isPro: false,
            structureCard: StructureCard(
                opener: "I have some feedback to share.",
                context: "I noticed [specific behavior].",
                ask: "I'd like to see [specific change].",
                nextStep: "How can I support you?"
            ),
            hapticStyle: .steady
        ),

        Scenario(
            id: "have-the-talk",
            title: "Have 'The Talk'",
            subtitle: "Define the relationship",
            icon: "heart.fill",
            promptText: "Practice a conversation about where a relationship is going.",
            coachingHint: "Say what you want, not just what you're wondering.",
            category: .relationships,
            isPro: false,
            structureCard: StructureCard(
                opener: "I want to talk about where we're at.",
                context: "I've really enjoyed [what's working].",
                ask: "I'm looking for [what you want].",
                nextStep: "How do you feel about that?"
            ),
            hapticStyle: .soft
        ),

        Scenario(
            id: "say-no",
            title: "Say No",
            subtitle: "Decline without guilt",
            icon: "xmark.circle.fill",
            promptText: "Practice declining a request.",
            coachingHint: "No is a complete sentence.",
            category: .boundaries,
            isPro: false,
            structureCard: StructureCard(
                opener: "Thank you for thinking of me.",
                context: "I've thought about it, and...",
                ask: "I'm not able to do this.",
                nextStep: "Here's what I can do instead."
            ),
            hapticStyle: .firm
        ),

        Scenario(
            id: "apologize-well",
            title: "Apologize Well",
            subtitle: "Take real responsibility",
            icon: "arrow.uturn.backward.circle.fill",
            promptText: "Practice a genuine apology.",
            coachingHint: "'I'm sorry I...' not 'I'm sorry you felt...'",
            category: .relationships,
            isPro: false,
            structureCard: StructureCard(
                opener: "I owe you an apology.",
                context: "I [specific thing you did wrong].",
                ask: "I'm sorry. I won't do that again.",
                nextStep: "What can I do to make it right?"
            ),
            hapticStyle: .soft
        ),

        // MARK: - Pro Scenarios (6)

        Scenario(
            id: "negotiate-offer",
            title: "Negotiate an Offer",
            subtitle: "Get what you deserve",
            icon: "briefcase.fill",
            promptText: "Practice negotiating salary or terms.",
            coachingHint: "Silence after your number is powerful.",
            category: .career,
            isPro: true,
            structureCard: StructureCard(
                opener: "I'm excited about this opportunity.",
                context: "Based on my experience and market rate...",
                ask: "I'm looking for [specific number].",
                nextStep: "[Pause. Wait for response.]"
            ),
            hapticStyle: .steady
        ),

        Scenario(
            id: "end-relationship",
            title: "End a Relationship",
            subtitle: "Leave with grace",
            icon: "door.left.hand.open",
            promptText: "Practice ending a relationship with honesty.",
            coachingHint: "Be clear it's over. Ambiguity is cruelty.",
            category: .relationships,
            isPro: true,
            structureCard: StructureCard(
                opener: "I need to be honest about something hard.",
                context: "I've been thinking a lot...",
                ask: "I think we need to end this.",
                nextStep: "I care about you, and I know this is painful."
            ),
            hapticStyle: .soft
        ),

        Scenario(
            id: "confront-issue",
            title: "Confront an Issue",
            subtitle: "Address what's unsaid",
            icon: "exclamationmark.bubble.fill",
            promptText: "Practice bringing up a problem.",
            coachingHint: "Describe impact on you, not their intentions.",
            category: .difficult,
            isPro: true,
            structureCard: StructureCard(
                opener: "There's something I've been meaning to bring up.",
                context: "When [situation], I felt [your experience].",
                ask: "I'd like us to [specific request].",
                nextStep: "Can we talk about this?"
            ),
            hapticStyle: .firm
        ),

        Scenario(
            id: "set-expectation",
            title: "Set an Expectation",
            subtitle: "Be clear upfront",
            icon: "checklist",
            promptText: "Practice stating what you expect.",
            coachingHint: "Make it specific: 'I need X by Y.'",
            category: .boundaries,
            isPro: true,
            structureCard: StructureCard(
                opener: "I want to make sure we're aligned.",
                context: "For this to work, I need...",
                ask: "[Specific, measurable expectation].",
                nextStep: "Does that work for you?"
            ),
            hapticStyle: .firm
        ),

        Scenario(
            id: "deliver-bad-news",
            title: "Deliver Bad News",
            subtitle: "Don't bury the lede",
            icon: "exclamationmark.triangle.fill",
            promptText: "Practice delivering difficult news.",
            coachingHint: "Say the hard part first.",
            category: .difficult,
            isPro: true,
            structureCard: StructureCard(
                opener: "I have some difficult news.",
                context: "[The news, stated clearly.]",
                ask: "I know this is hard to hear.",
                nextStep: "Here's what happens next."
            ),
            hapticStyle: .steady
        ),

        Scenario(
            id: "ask-for-help",
            title: "Ask for Help",
            subtitle: "Vulnerability is strength",
            icon: "person.2.fill",
            promptText: "Practice asking for help or support.",
            coachingHint: "Be specific. Vague asks get vague responses.",
            category: .relationships,
            isPro: true,
            structureCard: StructureCard(
                opener: "I could really use your help.",
                context: "I'm dealing with [situation].",
                ask: "Would you be able to [specific ask]?",
                nextStep: "It would mean a lot to me."
            ),
            hapticStyle: .soft
        )
    ]

    // MARK: - Convenience Accessors

    static var freeScenarios: [Scenario] {
        allScenarios.filter { !$0.isPro }
    }

    static var proScenarios: [Scenario] {
        allScenarios.filter { $0.isPro }
    }

    static func scenario(for id: String) -> Scenario? {
        allScenarios.first { $0.id == id }
    }

    static func scenarios(for category: Category) -> [Scenario] {
        allScenarios.filter { $0.category == category }
    }
}
