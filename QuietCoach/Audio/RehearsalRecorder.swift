// RehearsalRecorder.swift
// QuietCoach
//
// The recording engine. Handles the microphone with care, provides
// real-time feedback, and gracefully handles interruptions.
//
// State machine: idle → recording ⇄ paused → finished → idle

import AVFoundation
import Combine
import OSLog

@MainActor
final class RehearsalRecorder: ObservableObject {

    // MARK: - State Machine

    enum State: Equatable {
        case idle
        case recording
        case paused
        case finished
    }

    // MARK: - Recording Warnings

    enum RecordingWarning: Equatable {
        case tooQuiet
        case tooLoud
        case noisyEnvironment

        var icon: String {
            switch self {
            case .tooQuiet: return "speaker.slash.fill"
            case .tooLoud: return "speaker.wave.3.fill"
            case .noisyEnvironment: return "waveform.badge.exclamationmark"
            }
        }

        var message: String {
            switch self {
            case .tooQuiet: return "Speak up or move closer"
            case .tooLoud: return "Too loud — move back slightly"
            case .noisyEnvironment: return "Noisy environment detected"
            }
        }

        var accessibilityLabel: String {
            switch self {
            case .tooQuiet: return "Warning: Audio too quiet. Speak up or move closer to the microphone."
            case .tooLoud: return "Warning: Audio too loud. Move back slightly from the microphone."
            case .noisyEnvironment: return "Warning: Noisy environment detected. Consider moving to a quieter location."
            }
        }
    }

    // MARK: - Published State

    @Published private(set) var state: State = .idle
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var currentLevel: Float = 0
    @Published private(set) var waveformSamples: [Float] = []
    @Published private(set) var activeWarning: RecordingWarning?

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.quietcoach", category: "Recorder")
    private let fileStore = FileStore.shared

    private var audioRecorder: AVAudioRecorder?
    private var meteringTimer: Timer?
    private var startTime: Date?
    private var accumulatedTime: TimeInterval = 0

    // Metrics collection
    private var rmsWindows: [Float] = []
    private var peakWindows: [Float] = []
    private var noiseFloor: Float = 0.01
    private var hasCalibrated = false

    // Current recording info
    private(set) var currentFileName: String?
    private(set) var currentFileURL: URL?

    // MARK: - Audio Session Setup

    /// Configure the audio session for recording
    func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP]
            )
            try session.setActive(true)
            logger.info("Audio session configured successfully")
        } catch {
            logger.error("Failed to configure audio session: \(error.localizedDescription)")
        }

        // Register for interruptions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: session
        )

        // Register for route changes (AirPods connect/disconnect)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: session
        )
    }

    // MARK: - Recording Controls

    /// Start a new recording
    func startRecording() {
        guard state == .idle else {
            logger.warning("Cannot start recording from state: \(String(describing: self.state))")
            return
        }

        resetMetrics()

        // Generate unique filename
        let fileName = fileStore.generateAudioFileName()
        let fileURL = fileStore.audioFileURL(for: fileName)
        currentFileName = fileName
        currentFileURL = fileURL

        // Configure recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder.isMeteringEnabled = true
            recorder.prepareToRecord()

            if recorder.record() {
                audioRecorder = recorder
                startTime = Date()
                state = .recording
                startMetering()
                logger.info("Recording started: \(fileName)")
            } else {
                logger.error("Failed to start recording")
                cleanupFailedRecording()
            }
        } catch {
            logger.error("Failed to create recorder: \(error.localizedDescription)")
            cleanupFailedRecording()
        }
    }

    /// Pause the current recording
    func pauseRecording() {
        guard state == .recording else {
            logger.warning("Cannot pause from state: \(String(describing: self.state))")
            return
        }

        audioRecorder?.pause()
        accumulatedTime += Date().timeIntervalSince(startTime ?? Date())
        stopMetering()
        state = .paused
        logger.info("Recording paused at \(self.accumulatedTime)s")
    }

    /// Resume a paused recording
    func resumeRecording() {
        guard state == .paused else {
            logger.warning("Cannot resume from state: \(String(describing: self.state))")
            return
        }

        if audioRecorder?.record() == true {
            startTime = Date()
            state = .recording
            startMetering()
            logger.info("Recording resumed")
        } else {
            logger.error("Failed to resume recording")
        }
    }

    /// Stop recording and return metrics
    func stopRecording() -> AudioMetrics {
        guard state == .recording || state == .paused else {
            logger.warning("Cannot stop from state: \(String(describing: self.state))")
            return .empty
        }

        // Finalize accumulated time
        if state == .recording {
            accumulatedTime += Date().timeIntervalSince(startTime ?? Date())
        }

        audioRecorder?.stop()
        stopMetering()
        state = .finished

        let metrics = AudioMetrics(
            rmsWindows: rmsWindows,
            peakWindows: peakWindows,
            duration: accumulatedTime
        )

        logger.info("Recording stopped. Duration: \(self.accumulatedTime)s, Samples: \(self.rmsWindows.count)")
        return metrics
    }

    /// Cancel recording and delete the file
    func cancelRecording() {
        audioRecorder?.stop()
        stopMetering()

        if let fileName = currentFileName {
            fileStore.deleteAudioFile(named: fileName)
            logger.info("Recording cancelled and deleted: \(fileName)")
        }

        resetMetrics()
        state = .idle
    }

    /// Reset for a new recording
    func resetForNewRecording() {
        resetMetrics()
        state = .idle
    }

    // MARK: - Metering

    private func startMetering() {
        meteringTimer = Timer.scheduledTimer(
            withTimeInterval: Constants.Limits.meteringInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateMetering()
            }
        }

        // Calibrate noise floor after initial samples
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.AudioQuality.noiseFloorCalibrationDuration) { [weak self] in
            self?.calibrateNoiseFloor()
        }
    }

    private func stopMetering() {
        meteringTimer?.invalidate()
        meteringTimer = nil
        activeWarning = nil
    }

    private func updateMetering() {
        guard let recorder = audioRecorder, state == .recording else { return }

        recorder.updateMeters()

        // Get power levels (in dB, typically -160 to 0)
        let averagePower = recorder.averagePower(forChannel: 0)
        let peakPower = recorder.peakPower(forChannel: 0)

        // Convert to linear scale (0 to 1)
        let linearPower = pow(10, averagePower / 20)
        let linearPeak = pow(10, peakPower / 20)

        // Update published properties
        currentLevel = linearPower
        rmsWindows.append(linearPower)
        peakWindows.append(linearPeak)

        // Update waveform (rolling window)
        waveformSamples.append(linearPower)
        if waveformSamples.count > Constants.Limits.waveformSampleCount {
            waveformSamples.removeFirst()
        }

        // Update current time
        currentTime = accumulatedTime + Date().timeIntervalSince(startTime ?? Date())

        // Check recording quality
        checkRecordingQuality()

        // Auto-stop at max duration
        if currentTime >= Constants.Limits.maxRecordingDuration {
            logger.info("Max recording duration reached")
            _ = stopRecording()
        }
    }

    private func calibrateNoiseFloor() {
        guard !hasCalibrated, rmsWindows.count >= 3 else { return }

        // Use the first few samples to estimate ambient noise
        let initialSamples = Array(rmsWindows.prefix(3))
        let averageNoise = initialSamples.reduce(0, +) / Float(initialSamples.count)

        // Set noise floor slightly above ambient
        noiseFloor = averageNoise + 0.005
        hasCalibrated = true

        logger.info("Noise floor calibrated: \(self.noiseFloor)")
    }

    private func checkRecordingQuality() {
        let windowSize = Constants.AudioQuality.warningCheckWindowSize
        guard rmsWindows.count >= windowSize else { return }

        let recentRMS = Array(rmsWindows.suffix(windowSize))
        let recentPeaks = Array(peakWindows.suffix(windowSize))

        let recentAverage = recentRMS.reduce(0, +) / Float(windowSize)
        let recentPeakMax = recentPeaks.max() ?? 0

        // Check for quality issues
        if recentAverage < Constants.AudioQuality.tooQuietThreshold {
            setWarning(.tooQuiet)
        } else if recentPeakMax > Constants.AudioQuality.tooLoudThreshold {
            setWarning(.tooLoud)
        } else if noiseFloor > Constants.AudioQuality.noisyEnvironmentThreshold && hasCalibrated {
            setWarning(.noisyEnvironment)
        } else {
            clearWarning()
        }
    }

    private func setWarning(_ warning: RecordingWarning) {
        guard activeWarning != warning else { return }
        activeWarning = warning
        Haptics.warning()
    }

    private func clearWarning() {
        activeWarning = nil
    }

    // MARK: - Interruption Handling

    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        Task { @MainActor in
            switch type {
            case .began:
                // Phone call, Siri, etc.
                if state == .recording {
                    pauseRecording()
                    logger.info("Recording paused due to interruption")
                }

            case .ended:
                // Interruption ended - don't auto-resume, let user decide
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        logger.info("Interruption ended, user can resume")
                    }
                }

            @unknown default:
                break
            }
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        Task { @MainActor in
            switch reason {
            case .oldDeviceUnavailable:
                // AirPods disconnected, etc.
                if state == .recording {
                    pauseRecording()
                    logger.info("Recording paused due to route change (device unavailable)")
                }

            case .newDeviceAvailable:
                logger.info("New audio device available")

            default:
                break
            }
        }
    }

    // MARK: - Helpers

    private func resetMetrics() {
        currentTime = 0
        currentLevel = 0
        waveformSamples = []
        rmsWindows = []
        peakWindows = []
        accumulatedTime = 0
        startTime = nil
        currentFileName = nil
        currentFileURL = nil
        noiseFloor = 0.01
        hasCalibrated = false
        activeWarning = nil
    }

    private func cleanupFailedRecording() {
        if let fileName = currentFileName {
            fileStore.deleteAudioFile(named: fileName)
        }
        resetMetrics()
    }

    // MARK: - Permissions

    /// Request microphone permission
    static func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// Check current permission status
    static var hasMicrophonePermission: Bool {
        AVAudioApplication.shared.recordPermission == .granted
    }

    /// Check if permission has been determined
    static var permissionDetermined: Bool {
        AVAudioApplication.shared.recordPermission != .undetermined
    }
}

// MARK: - Formatted Time

extension RehearsalRecorder {
    /// Current time formatted as "M:SS"
    var formattedCurrentTime: String {
        currentTime.qcFormattedDuration
    }

    /// Remaining time before max duration
    var remainingTime: TimeInterval {
        max(0, Constants.Limits.maxRecordingDuration - currentTime)
    }

    /// Whether recording is near max duration (last 30 seconds)
    var isNearMaxDuration: Bool {
        remainingTime < 30 && state == .recording
    }
}
