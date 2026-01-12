// AudioPlayerViewModel.swift
// QuietCoach
//
// Playback controller for reviewing recordings.
// Simple, focused, handles edge cases gracefully.

import AVFoundation
import OSLog

@Observable
@MainActor
final class AudioPlayerViewModel {

    // MARK: - State

    enum State: Equatable, Sendable {
        case idle
        case loading
        case ready
        case playing
        case paused
        case error(String)

        var isPlayable: Bool {
            switch self {
            case .ready, .paused: return true
            default: return false
            }
        }
    }

    // MARK: - Observable State

    private(set) var state: State = .idle
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var progress: Double = 0

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.quietcoach", category: "Player")
    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    private var loadedURL: URL?
    private let delegateHandler = AudioPlayerDelegateHandler()

    // MARK: - Initialization

    init() {}

    // MARK: - Loading

    /// Load audio from a URL
    func load(url: URL) {
        stopProgressTimer()
        audioPlayer?.stop()
        audioPlayer = nil
        currentTime = 0
        duration = 0
        progress = 0

        state = .loading
        loadedURL = url

        do {
            // Configure audio session for playback
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            // Create player
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.delegate = delegateHandler

            audioPlayer = player
            duration = player.duration
            currentTime = 0
            progress = 0
            state = .ready

            // Set up delegate callback
            delegateHandler.onFinish = { [weak self] in
                Task { @MainActor in
                    self?.handlePlaybackFinished()
                }
            }

            logger.info("Audio loaded: \(url.lastPathComponent), duration: \(player.duration)s")
        } catch {
            logger.error("Failed to load audio: \(error.localizedDescription)")
            state = .error("Unable to load audio")
        }
    }

    /// Load audio from a session
    func load(session: RehearsalSession) {
        let url = FileStore.shared.audioFileURL(for: session.audioFileName)

        guard FileStore.shared.audioFileExists(named: session.audioFileName) else {
            logger.error("Audio file not found: \(session.audioFileName)")
            state = .error("Recording not found")
            return
        }

        load(url: url)
    }

    // MARK: - Playback Controls

    /// Start or resume playback
    func play() {
        guard let player = audioPlayer, state.isPlayable else {
            logger.warning("Cannot play in state: \(String(describing: self.state))")
            return
        }

        if player.play() {
            state = .playing
            startProgressTimer()
            logger.info("Playback started")
        } else {
            logger.error("Failed to start playback")
            state = .error("Playback failed")
        }
    }

    /// Pause playback
    func pause() {
        guard state == .playing else { return }

        audioPlayer?.pause()
        stopProgressTimer()
        state = .paused
        logger.info("Playback paused at \(self.currentTime)s")
    }

    /// Stop playback and reset to beginning
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        stopProgressTimer()

        currentTime = 0
        progress = 0
        state = .ready
        logger.info("Playback stopped")
    }

    /// Toggle between play and pause
    func togglePlayPause() {
        switch state {
        case .playing:
            pause()
        case .ready, .paused:
            play()
        default:
            break
        }
    }

    /// Seek to a specific progress (0-1)
    func seekToProgress(_ newProgress: Double) {
        guard let player = audioPlayer else { return }

        let clampedProgress = max(0, min(1, newProgress))
        let newTime = clampedProgress * duration

        player.currentTime = newTime
        currentTime = newTime
        progress = clampedProgress

        logger.info("Seeked to \(newTime)s (\(Int(clampedProgress * 100))%)")
    }

    /// Seek forward by seconds
    func seekForward(seconds: TimeInterval = 10) {
        guard duration > 0 else {
            currentTime = 0
            progress = 0
            return
        }
        let newTime = min(duration, currentTime + seconds)
        seekToProgress(newTime / duration)
    }

    /// Seek backward by seconds
    func seekBackward(seconds: TimeInterval = 10) {
        guard duration > 0 else {
            currentTime = 0
            progress = 0
            return
        }
        let newTime = max(0, currentTime - seconds)
        seekToProgress(newTime / duration)
    }

    // MARK: - Progress Tracking

    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateProgress()
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func updateProgress() {
        guard let player = audioPlayer else { return }

        currentTime = player.currentTime
        progress = duration > 0 ? currentTime / duration : 0

        // Check if playback finished
        if !player.isPlaying && state == .playing {
            handlePlaybackFinished()
        }
    }

    private func handlePlaybackFinished() {
        stopProgressTimer()
        currentTime = 0
        progress = 0
        state = .ready
        logger.info("Playback finished")
    }

    // MARK: - Cleanup

    func cleanup() {
        audioPlayer?.stop()
        stopProgressTimer()
        audioPlayer = nil
        loadedURL = nil
        state = .idle
    }

    // MARK: - Formatted Properties

    /// Current time formatted as "M:SS"
    var formattedCurrentTime: String {
        currentTime.qcFormattedDuration
    }

    /// Duration formatted as "M:SS"
    var formattedDuration: String {
        duration.qcFormattedDuration
    }

    /// Remaining time formatted as "M:SS"
    var formattedRemainingTime: String {
        (duration - currentTime).qcFormattedDuration
    }
}

// MARK: - Delegate Handler

/// Separate class to handle AVAudioPlayerDelegate
private final class AudioPlayerDelegateHandler: NSObject, AVAudioPlayerDelegate, Sendable {
    nonisolated(unsafe) var onFinish: (@Sendable () -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish?()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        // Error handling is done through state
    }
}
