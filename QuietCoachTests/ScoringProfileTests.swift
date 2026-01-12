// ScoringProfileTests.swift
// QuietCoachTests
//
// Guardrails for scoring profile tuning values.

import XCTest
@testable import QuietCoach

final class ScoringProfileTests: XCTestCase {

    func testDefaultProfileTuningIsReasonable() {
        let profile = ScoringProfile.default

        XCTAssertGreaterThan(profile.audio.minimumDurationMinutes, 0)
        XCTAssertLessThanOrEqual(profile.audio.minimumDurationMinutes, 1.0)

        XCTAssertGreaterThan(profile.tuning.audioBlendBonus, 0)
        XCTAssertLessThanOrEqual(profile.tuning.audioBlendBonus, 20)
    }
}
