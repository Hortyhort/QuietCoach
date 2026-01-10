// SpeechPatterns.swift
// QuietCoach
//
// Pattern dictionaries for speech analysis detection.

import Foundation

// MARK: - Speech Patterns

enum SpeechPatterns {

    // MARK: - Filler Words

    static let fillerPatterns = [
        "um", "uh", "uhh", "umm", "er", "ah", "ahh",
        "like", "you know", "basically", "actually",
        "literally", "honestly", "right", "so yeah",
        "i mean", "kind of", "sort of"
    ]

    // MARK: - Hedging Language

    static let hedgingPatterns = [
        "i think", "i guess", "i feel like", "maybe",
        "probably", "might", "could be", "sort of",
        "kind of", "in a way", "it seems", "perhaps",
        "i'm not sure", "i don't know"
    ]

    // MARK: - Question Words

    static let questionWords = [
        "what", "why", "how", "when", "where", "who", "which"
    ]

    // MARK: - Weak Openers

    static let weakOpeners = [
        "i just", "i'm just", "sorry", "i was just",
        "i don't know if", "this might be", "i'm not sure"
    ]

    // MARK: - Apologetic Language

    static let apologeticPatterns = [
        "sorry", "apologize", "my fault", "excuse me",
        "forgive me", "i'm sorry"
    ]

    // MARK: - Assertive Language

    static let assertivePatterns = [
        "i need", "i want", "i will", "i expect",
        "i require", "i believe", "i'm confident",
        "it's important", "this matters"
    ]

    // MARK: - Incomplete Endings

    static let incompleteEndings = [
        "...", "um", "uh", "so", "and", "but", "or"
    ]

    // MARK: - Positive Words

    static let positiveWords = [
        "good", "great", "excellent", "happy", "pleased",
        "confident", "strong", "clear", "effective", "success"
    ]

    // MARK: - Negative Words

    static let negativeWords = [
        "bad", "terrible", "worried", "anxious", "nervous",
        "weak", "unclear", "difficult", "problem", "fail"
    ]

    // MARK: - Contraction Patterns

    static let contractionPatterns = [
        "don't", "can't", "won't", "wouldn't", "couldn't",
        "shouldn't", "isn't", "aren't", "wasn't", "weren't",
        "i'm", "you're", "we're", "they're", "it's"
    ]

    // MARK: - Formal Phrases

    static let formalPatterns = [
        "therefore", "however", "furthermore", "consequently",
        "nevertheless", "regarding", "pertaining to"
    ]
}

// MARK: - String Extension

extension String {
    func matchesPattern(_ pattern: String) -> Bool {
        self.lowercased() == pattern.lowercased()
    }
}
