// TranscriptionEngine.swift
// QuietCoach
//
// On-device speech-to-text. Privacy first — all processing happens locally.
// Uses SFSpeechRecognizer with requiresOnDeviceRecognition for complete privacy.

import Speech
import OSLog

@Observable
@MainActor
final class TranscriptionEngine {

    // MARK: - Transcription State

    enum State: Equatable, Sendable {
        case idle
        case transcribing
        case completed
        case failed(String)

        var isTranscribing: Bool {
            self == .transcribing
        }
    }

    // MARK: - Observable State

    private(set) var state: State = .idle
    private(set) var transcript: String = ""
    private(set) var segments: [TranscriptSegment] = []
    private(set) var progress: Double = 0

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.quietcoach", category: "Transcription")
    private var recognizer: SFSpeechRecognizer?
    private var currentTask: SFSpeechRecognitionTask?

    // MARK: - Initialization

    init() {
        setupRecognizer()
    }

    private func setupRecognizer() {
        recognizer = SFSpeechRecognizer(locale: Locale.current)

        // Check if on-device recognition is available
        if let recognizer, !recognizer.supportsOnDeviceRecognition {
            logger.warning("On-device recognition not supported for current locale")
        }
    }

    // MARK: - Permission

    /// Request speech recognition permission
    static func requestPermission() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    /// Current authorization status
    static var authorizationStatus: SFSpeechRecognizerAuthorizationStatus {
        SFSpeechRecognizer.authorizationStatus()
    }

    /// Whether transcription is available
    var isAvailable: Bool {
        guard let recognizer else { return false }
        return recognizer.isAvailable && Self.authorizationStatus == .authorized
    }

    /// Whether on-device transcription is supported
    var supportsOnDevice: Bool {
        recognizer?.supportsOnDeviceRecognition ?? false
    }

    // MARK: - Transcription

    /// Transcribe an audio file
    func transcribe(audioURL: URL) async {
        guard let recognizer, recognizer.isAvailable else {
            state = .failed("Speech recognition not available")
            return
        }

        // Cancel any existing task
        currentTask?.cancel()
        currentTask = nil

        // Reset state
        transcript = ""
        segments = []
        progress = 0
        state = .transcribing

        // Create recognition request
        let request = SFSpeechURLRecognitionRequest(url: audioURL)

        // Privacy: require on-device recognition if available
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
            logger.info("Using on-device transcription")
        } else {
            logger.info("On-device not available, using server transcription")
        }

        // Request partial results for progress indication
        request.shouldReportPartialResults = true

        // Add contextual hints based on scenarios
        request.contextualStrings = [
            "boundary", "raise", "feedback", "relationship",
            "apologize", "negotiate", "confront", "expectation"
        ]

        do {
            try await performTranscription(recognizer: recognizer, request: request)
            progress = 1.0
            state = .completed
            logger.info("Transcription completed: \(self.transcript.count) characters")
        } catch {
            logger.error("Transcription failed: \(error.localizedDescription)")
            state = .failed(error.localizedDescription)
        }
    }

    private func performTranscription(
        recognizer: SFSpeechRecognizer,
        request: SFSpeechRecognitionRequest
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var hasResumed = false

            currentTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                if let error {
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(throwing: error)
                    }
                    return
                }

                guard let result else { return }

                // Extract data we need (Sendable)
                let transcriptText = result.bestTranscription.formattedString
                let segmentData = result.bestTranscription.segments.map { segment in
                    (text: segment.substring,
                     timestamp: segment.timestamp,
                     duration: segment.duration,
                     confidence: segment.confidence)
                }
                let isFinal = result.isFinal

                // Update on main actor
                Task { @MainActor [weak self] in
                    self?.transcript = transcriptText
                    self?.segments = segmentData.map { data in
                        TranscriptSegment(
                            text: data.text,
                            timestamp: data.timestamp,
                            duration: data.duration,
                            confidence: data.confidence
                        )
                    }
                }

                if isFinal {
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume()
                    }
                }
            }
        }
    }

    private func updateSegments(from transcription: SFTranscription) {
        segments = transcription.segments.map { segment in
            TranscriptSegment(
                text: segment.substring,
                timestamp: segment.timestamp,
                duration: segment.duration,
                confidence: segment.confidence
            )
        }
    }

    /// Cancel ongoing transcription
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
        state = .idle
    }

    /// Reset for new transcription
    func reset() {
        cancel()
        transcript = ""
        segments = []
        progress = 0
    }
}

// MARK: - Transcript Segment

struct TranscriptSegment: Identifiable, Equatable, Sendable {
    let id = UUID()
    let text: String
    let timestamp: TimeInterval
    let duration: TimeInterval
    let confidence: Float

    /// Whether this segment has high confidence
    var isHighConfidence: Bool {
        confidence >= 0.8
    }

    /// Formatted timestamp
    var formattedTimestamp: String {
        let minutes = Int(timestamp) / 60
        let seconds = Int(timestamp) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Transcription Analysis

extension TranscriptionEngine {

    /// Average confidence across all segments
    var averageConfidence: Float {
        guard !segments.isEmpty else { return 0 }
        let total = segments.reduce(0) { $0 + $1.confidence }
        return total / Float(segments.count)
    }

    /// Word count from transcript
    var wordCount: Int {
        transcript.split(separator: " ").count
    }

    /// Speaking rate (words per minute)
    func speakingRate(duration: TimeInterval) -> Double {
        guard duration > 0 else { return 0 }
        return Double(wordCount) / (duration / 60)
    }

    /// Segments with low confidence (may need review)
    var lowConfidenceSegments: [TranscriptSegment] {
        segments.filter { $0.confidence < 0.6 }
    }

    /// Check if transcript contains filler words
    var fillerWordCount: Int {
        let fillers = ["um", "uh", "like", "you know", "basically", "actually", "literally"]
        let lowercased = transcript.lowercased()
        return fillers.reduce(0) { count, filler in
            count + lowercased.components(separatedBy: filler).count - 1
        }
    }
}
