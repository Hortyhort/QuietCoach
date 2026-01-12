// ScoringProfile.swift
// QuietCoach
//
// Centralized tuning for scoring heuristics and thresholds.
// Keeps "magic numbers" out of analysis code and enables safe iteration.

import Foundation

struct ScoringProfile: Sendable, Equatable {

    struct AudioThresholds: Sendable, Equatable {
        var noiseFloor: Float
        var pauseMinConsecutiveWindows: Int
        var spikeStdDevMultiplier: Float
        var pacingTooSlowSegmentsPerMinute: Float
        var pacingTooFastSegmentsPerMinute: Float
        var pacingOptimalRange: ClosedRange<Float>
        var spikesPerMinuteMax: Float
        var volumeStabilityMinimum: Float
        var averageLevelMinimum: Float
        var averageLevelStrong: Float
        var silenceRatioMax: Float
        var idealPauseIntervalSeconds: TimeInterval
        var pauseToleranceFactor: Float
    }

    struct NlpThresholds: Sendable, Equatable {
        var clarityBaseScore: Int
        var fillerPenaltyPerWord: Int
        var fillerPenaltyMax: Int
        var repeatedPenaltyPerWord: Int
        var repeatedPenaltyMax: Int
        var incompletePenaltyPerSentence: Int
        var incompletePenaltyMax: Int
        var lowConfidencePenaltyPerSegment: Int
        var lowConfidencePenaltyMax: Int
        var lowConfidenceSegmentThreshold: Float
        var averageWordLengthBonusThreshold: Double
        var averageWordLengthBonus: Int

        var pacingBaseScore: Int
        var pacingSlowWordsPerMinute: Double
        var pacingFastWordsPerMinute: Double
        var pacingOptimalRange: ClosedRange<Double>
        var pacingOptimalBonus: Int
        var pacingPenaltyDivisor: Double
        var noPausePenaltyDuration: TimeInterval
        var noPausePenalty: Int
        var longPausePenaltyThreshold: Int
        var longPausePenaltyPerPause: Int
        var mediumPauseBonus: Int

        var confidenceBaseScore: Int
        var hedgingPenaltyPerPhrase: Int
        var hedgingPenaltyMax: Int
        var weakOpenerPenaltyPerPhrase: Int
        var weakOpenerPenaltyMax: Int
        var apologeticPenaltyPerPhrase: Int
        var apologeticPenaltyMax: Int
        var assertiveBonusPerPhrase: Int
        var assertiveBonusMax: Int
        var questionRatioThreshold: Double
        var questionRatioPenalty: Int
        var insightFillerWordCountThreshold: Int
        var insightHedgingPhraseCountThreshold: Int

        var toneBaseScore: Int
        var sentimentMultiplier: Double
        var emotionBalanceThreshold: Int
        var emotionBalanceBonus: Int
        var formalityBonusRange: ClosedRange<Int>
        var formalityBonus: Int
        var formalityPenaltyThreshold: Int
        var formalityPenalty: Int
        var contractionBonusRange: ClosedRange<Int>
        var contractionBonus: Int

        var pauseThresholdSeconds: TimeInterval
        var shortPauseUpperBound: TimeInterval
        var mediumPauseUpperBound: TimeInterval
    }

    struct ScoreTuning: Sendable, Equatable {
        var baseScore: Int

        var clarityPausePenalty: Int
        var claritySilenceRatioThreshold: Float
        var claritySilencePenaltyMultiplier: Float
        var clarityDurationBonusShort: TimeInterval
        var clarityDurationBonusLong: TimeInterval
        var clarityDurationBonusValue: Int
        var clarityGoodPauseBonus: Int

        var pacingSlowPenaltyMultiplier: Float
        var pacingFastPenaltyMultiplier: Float
        var pacingOptimalBonus: Int
        var pacingShortRecordingThreshold: TimeInterval
        var pacingShortRecordingPenalty: Int
        var pacingSustainedDeliveryThreshold: TimeInterval
        var pacingSustainedDeliveryBonus: Int

        var toneStabilityMultiplier: Float
        var toneSpikePenaltyMultiplier: Float
        var toneInconsistentPenalty: Int
        var toneStabilityBonusThreshold: Float

        var confidenceLowVolumePenalty: Int
        var confidenceHighVolumeBonus: Int
        var confidenceStabilityMultiplier: Float
        var confidenceSilenceRatioPenalty: Int
        var confidenceShortRecordingThreshold: TimeInterval
        var confidenceShortRecordingPenalty: Int
        var confidenceEffectiveDurationRatio: Float
        var confidenceEffectiveDurationBonus: Int
    }

    struct ScoreWeights: Sendable, Equatable {
        var clarity: Double
        var pacing: Double
        var tone: Double
        var confidence: Double
    }

    var audio: AudioThresholds
    var nlp: NlpThresholds
    var tuning: ScoreTuning
    var weights: ScoreWeights

    static let `default` = ScoringProfile(
        audio: AudioThresholds(
            noiseFloor: 0.01,
            pauseMinConsecutiveWindows: 3,
            spikeStdDevMultiplier: 2.0,
            pacingTooSlowSegmentsPerMinute: 10,
            pacingTooFastSegmentsPerMinute: 40,
            pacingOptimalRange: 15...30,
            spikesPerMinuteMax: 5,
            volumeStabilityMinimum: 0.5,
            averageLevelMinimum: 0.1,
            averageLevelStrong: 0.3,
            silenceRatioMax: 0.5,
            idealPauseIntervalSeconds: 20,
            pauseToleranceFactor: 0.5
        ),
        nlp: NlpThresholds(
            clarityBaseScore: 85,
            fillerPenaltyPerWord: 3,
            fillerPenaltyMax: 30,
            repeatedPenaltyPerWord: 5,
            repeatedPenaltyMax: 15,
            incompletePenaltyPerSentence: 5,
            incompletePenaltyMax: 15,
            lowConfidencePenaltyPerSegment: 2,
            lowConfidencePenaltyMax: 10,
            lowConfidenceSegmentThreshold: 0.5,
            averageWordLengthBonusThreshold: 5.0,
            averageWordLengthBonus: 5,
            pacingBaseScore: 80,
            pacingSlowWordsPerMinute: 100,
            pacingFastWordsPerMinute: 180,
            pacingOptimalRange: 120...160,
            pacingOptimalBonus: 10,
            pacingPenaltyDivisor: 5,
            noPausePenaltyDuration: 30,
            noPausePenalty: 10,
            longPausePenaltyThreshold: 3,
            longPausePenaltyPerPause: 3,
            mediumPauseBonus: 5,
            confidenceBaseScore: 80,
            hedgingPenaltyPerPhrase: 4,
            hedgingPenaltyMax: 24,
            weakOpenerPenaltyPerPhrase: 5,
            weakOpenerPenaltyMax: 15,
            apologeticPenaltyPerPhrase: 5,
            apologeticPenaltyMax: 15,
            assertiveBonusPerPhrase: 3,
            assertiveBonusMax: 15,
            questionRatioThreshold: 0.1,
            questionRatioPenalty: 5,
            insightFillerWordCountThreshold: 3,
            insightHedgingPhraseCountThreshold: 2,
            toneBaseScore: 75,
            sentimentMultiplier: 15,
            emotionBalanceThreshold: 2,
            emotionBalanceBonus: 5,
            formalityBonusRange: 1...3,
            formalityBonus: 5,
            formalityPenaltyThreshold: 5,
            formalityPenalty: 5,
            contractionBonusRange: 1...5,
            contractionBonus: 5,
            pauseThresholdSeconds: 0.3,
            shortPauseUpperBound: 1.0,
            mediumPauseUpperBound: 2.0
        ),
        tuning: ScoreTuning(
            baseScore: 75,
            clarityPausePenalty: 5,
            claritySilenceRatioThreshold: 0.4,
            claritySilencePenaltyMultiplier: 50,
            clarityDurationBonusShort: 30,
            clarityDurationBonusLong: 60,
            clarityDurationBonusValue: 5,
            clarityGoodPauseBonus: 5,
            pacingSlowPenaltyMultiplier: 3,
            pacingFastPenaltyMultiplier: 2,
            pacingOptimalBonus: 10,
            pacingShortRecordingThreshold: 15,
            pacingShortRecordingPenalty: 15,
            pacingSustainedDeliveryThreshold: 30,
            pacingSustainedDeliveryBonus: 5,
            toneStabilityMultiplier: 20,
            toneSpikePenaltyMultiplier: 3,
            toneInconsistentPenalty: 10,
            toneStabilityBonusThreshold: 0.7,
            confidenceLowVolumePenalty: 15,
            confidenceHighVolumeBonus: 10,
            confidenceStabilityMultiplier: 15,
            confidenceSilenceRatioPenalty: 10,
            confidenceShortRecordingThreshold: 10,
            confidenceShortRecordingPenalty: 10,
            confidenceEffectiveDurationRatio: 0.7,
            confidenceEffectiveDurationBonus: 5
        ),
        weights: ScoreWeights(
            clarity: 1.0,
            pacing: 1.0,
            tone: 1.0,
            confidence: 1.0
        )
    )

    static func forScenario(
        _ scenario: Scenario,
        baseline: BaselineMetrics?,
        coachTone: CoachTone = .default
    ) -> ScoringProfile {
        var profile = ScoringProfile.default

        profile.weights = weights(for: scenario.category)
        profile.weights = profile.weights.applying(tone: coachTone)

        if let baseline {
            profile = profile.applyingBaseline(baseline)
        }

        return profile
    }

    private static func weights(for category: Scenario.Category) -> ScoreWeights {
        switch category {
        case .boundaries:
            return ScoreWeights(clarity: 1.1, pacing: 0.95, tone: 0.95, confidence: 1.1)
        case .career:
            return ScoreWeights(clarity: 1.1, pacing: 1.05, tone: 0.9, confidence: 1.05)
        case .relationships:
            return ScoreWeights(clarity: 1.0, pacing: 0.95, tone: 1.1, confidence: 0.95)
        case .difficult:
            return ScoreWeights(clarity: 1.05, pacing: 0.95, tone: 1.05, confidence: 1.0)
        }
    }

    private func applyingBaseline(_ baseline: BaselineMetrics) -> ScoringProfile {
        var profile = self

        if let baselineSegments = baseline.segmentsPerMinute {
            let currentMidpoint = (profile.audio.pacingOptimalRange.lowerBound + profile.audio.pacingOptimalRange.upperBound) / 2
            let delta = baselineSegments - currentMidpoint
            let adjustment = delta * 0.25

            profile.audio.pacingOptimalRange = (profile.audio.pacingOptimalRange.lowerBound + adjustment)...(profile.audio.pacingOptimalRange.upperBound + adjustment)
            profile.audio.pacingTooSlowSegmentsPerMinute = max(6, profile.audio.pacingTooSlowSegmentsPerMinute + adjustment)
            profile.audio.pacingTooFastSegmentsPerMinute = min(60, profile.audio.pacingTooFastSegmentsPerMinute + adjustment)
        }

        if let baselineAverageLevel = baseline.averageLevel {
            let target = min(profile.audio.averageLevelMinimum, baselineAverageLevel * 0.6)
            profile.audio.averageLevelMinimum = max(0.05, target)
        }

        if let baselineSilence = baseline.silenceRatio {
            let adjusted = min(0.7, max(profile.audio.silenceRatioMax, baselineSilence + 0.1))
            profile.audio.silenceRatioMax = adjusted
        }

        return profile
    }
}

struct BaselineMetrics: Sendable, Equatable {
    var segmentsPerMinute: Float?
    var averageLevel: Float?
    var silenceRatio: Float?
    var volumeStability: Float?
    var wordsPerMinute: Double?
}

private extension ScoringProfile.ScoreWeights {
    func applying(tone coachTone: CoachTone) -> ScoringProfile.ScoreWeights {
        let bias = coachTone.weightBias
        return ScoringProfile.ScoreWeights(
            clarity: clarity * bias.clarity,
            pacing: pacing * bias.pacing,
            tone: self.tone * bias.tone,
            confidence: confidence * bias.confidence
        )
    }
}
