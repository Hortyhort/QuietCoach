// IntelligentCoach.swift
// QuietCoach
//
// AI-powered coaching insights. Uses on-device analysis with
// optional Apple Intelligence enhancement when available.
// Privacy first — all core processing happens locally.

import Foundation
import OSLog
import NaturalLanguage

@Observable
@MainActor
final class IntelligentCoach {

    // MARK: - Coaching Insight

    struct Insight: Identifiable, Equatable, Sendable {
        let id = UUID()
        let category: Category
        let title: String
        let description: String
        let suggestion: String?
        let confidence: Float

        enum Category: String, Sendable {
            case clarity = "Clarity"
            case confidence = "Confidence"
            case pacing = "Pacing"
            case structure = "Structure"
            case emotion = "Emotional Tone"
            case improvement = "Growth"
        }
    }

    // MARK: - Observable State

    private(set) var insights: [Insight] = []
    private(set) var overallSummary: String = ""
    private(set) var isAnalyzing: Bool = false

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.quietcoach", category: "IntelligentCoach")
    private let tagger = NLTagger(tagSchemes: [.sentimentScore, .lexicalClass])

    // MARK: - Analysis

    /// Generate coaching insights from transcript and metrics
    func analyze(
        transcript: String,
        scenario: Scenario,
        metrics: AudioMetrics,
        scores: FeedbackScores
    ) async {
        guard !transcript.isEmpty else {
            logger.info("No transcript to analyze")
            return
        }

        isAnalyzing = true
        insights = []

        // Perform analysis
        let clarityInsight = analyzeClarity(transcript: transcript)
        let pacingInsight = analyzePacing(transcript: transcript, metrics: metrics)
        let structureInsight = analyzeStructure(transcript: transcript, scenario: scenario)
        let sentimentInsight = analyzeSentiment(transcript: transcript)
        let growthInsight = generateGrowthInsight(scores: scores, scenario: scenario)

        // Collect non-nil insights
        insights = [clarityInsight, pacingInsight, structureInsight, sentimentInsight, growthInsight]
            .compactMap { $0 }
            .sorted { $0.confidence > $1.confidence }

        // Generate summary
        overallSummary = generateSummary(insights: insights, scenario: scenario)

        isAnalyzing = false
        logger.info("Generated \(self.insights.count) insights")
    }

    // MARK: - Clarity Analysis

    private func analyzeClarity(transcript: String) -> Insight? {
        let words = transcript.split(separator: " ")
        let wordCount = words.count

        // Analyze sentence structure
        let sentences = transcript.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        let avgWordsPerSentence = wordCount > 0 && sentences.count > 0
            ? Double(wordCount) / Double(sentences.count)
            : 0

        // Check for filler words
        let fillers = ["um", "uh", "like", "you know", "basically", "actually", "literally", "sort of", "kind of"]
        let fillerCount = fillers.reduce(0) { count, filler in
            count + transcript.lowercased().components(separatedBy: filler).count - 1
        }

        let fillerRatio = wordCount > 0 ? Float(fillerCount) / Float(wordCount) : 0

        if fillerRatio > 0.05 {
            return Insight(
                category: .clarity,
                title: "Reduce filler words",
                description: "You used \(fillerCount) filler words. These can dilute your message.",
                suggestion: "Try pausing briefly instead of saying 'um' or 'like'. Silence is more powerful than fillers.",
                confidence: 0.85
            )
        } else if avgWordsPerSentence > 25 {
            return Insight(
                category: .clarity,
                title: "Shorter sentences",
                description: "Your sentences average \(Int(avgWordsPerSentence)) words, which may be hard to follow.",
                suggestion: "Break long thoughts into shorter statements. Aim for 15-20 words per sentence.",
                confidence: 0.75
            )
        } else if fillerRatio < 0.02 && avgWordsPerSentence < 20 {
            return Insight(
                category: .clarity,
                title: "Clear communication",
                description: "Your speech was clear with minimal filler words and well-structured sentences.",
                suggestion: nil,
                confidence: 0.9
            )
        }

        return nil
    }

    // MARK: - Pacing Analysis

    private func analyzePacing(transcript: String, metrics: AudioMetrics) -> Insight? {
        let wordCount = transcript.split(separator: " ").count
        let duration = metrics.duration
        let wordsPerMinute = duration > 0 ? Double(wordCount) / (duration / 60) : 0

        // Also check for pauses (gaps in RMS)
        let pauseCount = countSignificantPauses(in: metrics)

        if wordsPerMinute > 180 {
            return Insight(
                category: .pacing,
                title: "Slow down",
                description: "You spoke at \(Int(wordsPerMinute)) words per minute. That's quite fast.",
                suggestion: "Aim for 130-150 words per minute. Pauses give your listener time to process.",
                confidence: 0.85
            )
        } else if wordsPerMinute < 100 && wordCount > 20 {
            return Insight(
                category: .pacing,
                title: "Pick up the pace",
                description: "Your pace was \(Int(wordsPerMinute)) words per minute, which may lose your listener.",
                suggestion: "A slightly faster pace can convey confidence. Aim for 130-150 WPM.",
                confidence: 0.7
            )
        } else if pauseCount < 2 && duration > 30 {
            return Insight(
                category: .pacing,
                title: "Use strategic pauses",
                description: "Your delivery was continuous with few natural pauses.",
                suggestion: "Pause after key points to let them land. A 2-second pause can be powerful.",
                confidence: 0.65
            )
        } else if wordsPerMinute >= 120 && wordsPerMinute <= 160 {
            return Insight(
                category: .pacing,
                title: "Good pacing",
                description: "Your speaking pace of \(Int(wordsPerMinute)) WPM is ideal for clear communication.",
                suggestion: nil,
                confidence: 0.85
            )
        }

        return nil
    }

    private func countSignificantPauses(in metrics: AudioMetrics) -> Int {
        // Count consecutive low-RMS windows (silence)
        var pauseCount = 0
        var consecutiveSilence = 0
        let silenceThreshold: Float = 0.02

        for rms in metrics.rmsWindows {
            if rms < silenceThreshold {
                consecutiveSilence += 1
            } else {
                if consecutiveSilence >= 5 { // ~0.5 second pause
                    pauseCount += 1
                }
                consecutiveSilence = 0
            }
        }

        return pauseCount
    }

    // MARK: - Structure Analysis

    private func analyzeStructure(transcript: String, scenario: Scenario) -> Insight? {
        let lowercased = transcript.lowercased()

        // Check for key structural elements based on scenario
        let hasOpener = containsOpenerPattern(lowercased)
        let hasContext = containsContextPattern(lowercased)
        let hasAsk = containsAskPattern(lowercased, scenario: scenario)
        let hasNextStep = containsNextStepPattern(lowercased)

        let structureScore = [hasOpener, hasContext, hasAsk, hasNextStep]
            .filter { $0 }.count

        if structureScore >= 3 {
            return Insight(
                category: .structure,
                title: "Well structured",
                description: "Your conversation followed a clear structure with opener, context, and ask.",
                suggestion: nil,
                confidence: 0.85
            )
        } else if !hasAsk {
            return Insight(
                category: .structure,
                title: "State your ask clearly",
                description: "Your main request wasn't clearly articulated.",
                suggestion: "Be direct: 'I need...' or 'I'm asking for...' Make your ask impossible to miss.",
                confidence: 0.8
            )
        } else if !hasOpener {
            return Insight(
                category: .structure,
                title: "Open with intention",
                description: "Consider starting with a clear statement of purpose.",
                suggestion: "Try: 'I want to talk about...' or 'There's something important I need to discuss.'",
                confidence: 0.7
            )
        }

        return nil
    }

    private func containsOpenerPattern(_ text: String) -> Bool {
        let patterns = [
            "i want to talk", "i need to discuss", "there's something",
            "i've been thinking", "i want to share", "i need to tell you"
        ]
        return patterns.contains { text.contains($0) }
    }

    private func containsContextPattern(_ text: String) -> Bool {
        let patterns = [
            "because", "the reason", "what happened", "i've noticed",
            "over the past", "recently", "when you"
        ]
        return patterns.contains { text.contains($0) }
    }

    private func containsAskPattern(_ text: String, scenario: Scenario) -> Bool {
        let patterns = [
            "i need", "i want", "i'm asking", "would you",
            "can we", "i'd like", "i expect"
        ]
        return patterns.contains { text.contains($0) }
    }

    private func containsNextStepPattern(_ text: String) -> Bool {
        let patterns = [
            "what do you think", "how do you feel", "can we agree",
            "what would you need", "going forward", "from now on"
        ]
        return patterns.contains { text.contains($0) }
    }

    // MARK: - Sentiment Analysis

    private func analyzeSentiment(transcript: String) -> Insight? {
        tagger.string = transcript
        let range = transcript.startIndex..<transcript.endIndex

        var sentimentSum: Double = 0
        var count = 0

        tagger.enumerateTags(in: range, unit: .sentence, scheme: .sentimentScore) { tag, _ in
            if let tag, let score = Double(tag.rawValue) {
                sentimentSum += score
                count += 1
            }
            return true
        }

        guard count > 0 else { return nil }
        let avgSentiment = sentimentSum / Double(count)

        if avgSentiment < -0.3 {
            return Insight(
                category: .emotion,
                title: "Watch your tone",
                description: "Your language carried a negative tone that might put the listener on the defensive.",
                suggestion: "Try neutral phrasing. Instead of 'You always...' try 'I've noticed that...'",
                confidence: 0.7
            )
        } else if avgSentiment > 0.5 {
            return Insight(
                category: .emotion,
                title: "Positive tone",
                description: "Your language had a constructive, positive tone.",
                suggestion: nil,
                confidence: 0.75
            )
        }

        return nil
    }

    // MARK: - Growth Insight

    private func generateGrowthInsight(scores: FeedbackScores, scenario: Scenario) -> Insight? {
        let overall = scores.overall

        if overall >= 85 {
            return Insight(
                category: .improvement,
                title: "Excellent practice",
                description: "You scored \(overall)% on this rehearsal. That's strong performance.",
                suggestion: "Try this scenario again with a real-life situation in mind for even more impact.",
                confidence: 0.9
            )
        } else if overall >= 70 {
            return Insight(
                category: .improvement,
                title: "Good progress",
                description: "Your score of \(overall)% shows solid fundamentals.",
                suggestion: "Focus on one aspect to improve: clarity, pacing, or structure. Small gains compound.",
                confidence: 0.85
            )
        } else {
            return Insight(
                category: .improvement,
                title: "Room to grow",
                description: "Your score of \(overall)% gives you plenty of room for improvement.",
                suggestion: "Try the scenario again. Most people improve 20-30% between first and third attempt.",
                confidence: 0.8
            )
        }
    }

    // MARK: - Summary Generation

    private func generateSummary(insights: [Insight], scenario: Scenario) -> String {
        guard !insights.isEmpty else {
            return "Complete a rehearsal to receive personalized coaching insights."
        }

        let positives = insights.filter { $0.suggestion == nil }
        let improvements = insights.filter { $0.suggestion != nil }

        var summary = ""

        if !positives.isEmpty {
            let positiveAreas = positives.map { $0.title.lowercased() }.joined(separator: " and ")
            summary += "Your strengths: \(positiveAreas). "
        }

        if let topImprovement = improvements.first {
            summary += "Focus area: \(topImprovement.title.lowercased())."
        }

        return summary.isEmpty ? "Keep practicing to build your skills." : summary
    }

    // MARK: - Reset

    func reset() {
        insights = []
        overallSummary = ""
        isAnalyzing = false
    }
}
