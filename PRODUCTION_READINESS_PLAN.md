# Quiet Coach — Production Readiness Plan

**Objective**: Transform beautiful prototype into shippable, maintainable product
**Philosophy**: Ship quality, measure everything, iterate fast
**Approach**: Risk-first prioritization — fix what could sink us first

---

## The Reality Check

| What We Have | What We Need |
|--------------|--------------|
| Polished UI | Working core feature |
| Beautiful animations | Tests that prove it works |
| 7 singletons | Testable architecture |
| Hope | Data |

---

## Phase 1: Foundation (Critical Path)

### 1.1 Real Speech Analysis

**The Problem**: Core feature is placeholder. Users get random scores.

**The Solution**: On-device speech analysis using Apple frameworks. Transcription is opt-in, default off, with a metrics-only fallback when disabled.

```swift
// New: SpeechAnalysisEngine.swift
import Speech
import NaturalLanguage

actor SpeechAnalysisEngine {

    /// Analyze recorded audio and return real metrics
    func analyze(audioURL: URL) async throws -> AnalysisResult {
        // 1. Transcribe with SFSpeechRecognizer (opt-in)
        let transcription = PrivacySettings.shared.transcriptionEnabled
            ? try await transcribe(audioURL)
            : nil

        // 2. Analyze clarity (filler words, incomplete sentences)
        let clarity = transcription.map(analyzeClarity)

        // 3. Analyze pacing (words per minute, pause patterns)
        let pacing = transcription.map { analyzePacing($0, duration: audioDuration) }
            ?? analyzePacingFromAudio(audioURL)

        // 4. Analyze confidence (uptalk, hedging language)
        let confidence = transcription.map(analyzeConfidence)
            ?? analyzeConfidenceFromAudio(audioURL)

        // 5. Analyze tone (sentiment, assertiveness)
        let tone = transcription.map(analyzeTone)

        return AnalysisResult(
            clarity: clarity,
            pacing: pacing,
            confidence: confidence,
            tone: tone,
            transcription: transcription?.text
        )
    }
}
```

**Metrics We Can Actually Measure**:

| Metric | How | Apple Framework |
|--------|-----|-----------------|
| Clarity | Filler word count ("um", "uh", "like") | NLTagger |
| Clarity | Sentence completion rate | NLTokenizer |
| Pacing | Words per minute | SFSpeechRecognizer timing |
| Pacing | Pause frequency & duration | Audio silence detection |
| Confidence | Uptalk detection (rising intonation) | Audio pitch analysis |
| Confidence | Hedging phrases ("I think", "maybe") | NLTagger |
| Tone | Sentiment analysis | NLTagger.sentimentScore |
| Tone | Assertive vs passive language | Custom NLP model |

Transcript-dependent metrics only run when opt-in transcription is enabled. When disabled, fall back to audio-only metrics (pacing, pauses, loudness variance, energy).

**Deliverables**:
- [ ] SpeechAnalysisEngine with actor isolation
- [ ] Filler word detection (accuracy > 90%)
- [ ] Words-per-minute calculation
- [ ] Pause pattern analysis
- [ ] Basic sentiment scoring
- [ ] Metrics-only fallback path when transcription is disabled
- [ ] Unit tests proving accuracy

---

### 1.2 Testing Infrastructure

**The Problem**: Zero tests. Can't refactor safely. Can't verify features work.

**The Solution**: Strategic testing — high-value tests first.

```
QuietCoachTests/
├── Unit/
│   ├── SpeechAnalysisEngineTests.swift    # Core feature
│   ├── FeedbackScoringTests.swift         # Score calculation
│   ├── CoachPersonalityTests.swift        # Message generation
│   └── SessionRepositoryTests.swift       # Data layer
├── Integration/
│   ├── RecordingFlowTests.swift           # Record → Analyze → Display
│   └── SubscriptionFlowTests.swift        # Purchase → Unlock
└── UI/
    ├── OnboardingFlowTests.swift          # Critical path
    └── ReviewViewSnapshotTests.swift      # Visual regression
```

**Testing Strategy**:

| Layer | Coverage Target | Why |
|-------|-----------------|-----|
| Speech Analysis | 90% | Core value prop |
| Feedback Scoring | 90% | User-facing numbers |
| Data Layer | 80% | Data integrity |
| ViewModels | 70% | Business logic |
| Views | Snapshot only | Visual regression |

**Dependency Injection for Testability**:

```swift
// Before: Untestable singleton
class ReviewViewModel {
    func loadSession() {
        let repo = SessionRepository.shared  // Can't mock
    }
}

// After: Injectable dependency
class ReviewViewModel {
    private let repository: SessionRepositoryProtocol

    init(repository: SessionRepositoryProtocol = SessionRepository.shared) {
        self.repository = repository
    }
}

// Test
func testLoadSession() {
    let mockRepo = MockSessionRepository()
    let viewModel = ReviewViewModel(repository: mockRepo)
    // Now we can test!
}
```

**Deliverables**:
- [ ] Testing target configured
- [ ] Protocol abstractions for all singletons
- [ ] Mock implementations for testing
- [ ] 20 high-value unit tests
- [ ] 5 integration tests for critical paths
- [ ] CI runs tests on every PR

---

### 1.3 Error Handling Strategy

**The Problem**: Errors logged but invisible. Silent failures. No recovery.

**The Solution**: Unified error handling with user feedback.

```swift
// New: ErrorHandling.swift

/// App-wide error types with user-friendly messages
enum AppError: LocalizedError {
    case recordingFailed(underlying: Error)
    case analysisFailed(underlying: Error)
    case storageFull
    case microphonePermissionDenied
    case subscriptionVerificationFailed

    var errorDescription: String? {
        switch self {
        case .recordingFailed:
            return "Recording couldn't start"
        case .analysisFailed:
            return "Couldn't analyze your recording"
        case .storageFull:
            return "Not enough storage space"
        case .microphonePermissionDenied:
            return "Microphone access needed"
        case .subscriptionVerificationFailed:
            return "Couldn't verify subscription"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .recordingFailed:
            return "Try closing other apps using the microphone."
        case .storageFull:
            return "Free up space and try again."
        case .microphonePermissionDenied:
            return "Enable in Settings → Privacy → Microphone."
        // ...
        }
    }
}

/// Global error handler
@MainActor
final class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()

    @Published var currentError: AppError?
    @Published var showingError = false

    func handle(_ error: Error, context: String) {
        // Log for debugging
        Logger.app.error("[\(context)] \(error.localizedDescription)")

        // Report to crash service
        CrashReporter.shared.recordError(error, context: context)

        // Show user-friendly alert
        if let appError = error as? AppError {
            currentError = appError
            showingError = true
        }
    }
}
```

**Error UI Pattern**:

```swift
// In any view
.alert(
    errorHandler.currentError?.errorDescription ?? "Error",
    isPresented: $errorHandler.showingError
) {
    Button("OK") { }
    if errorHandler.currentError?.recoverySuggestion != nil {
        Button("Learn More") {
            // Show recovery steps
        }
    }
} message: {
    if let suggestion = errorHandler.currentError?.recoverySuggestion {
        Text(suggestion)
    }
}
```

**Deliverables**:
- [ ] AppError enum with all error cases
- [ ] ErrorHandler singleton with alert publishing
- [ ] Error alerts in all critical views
- [ ] Recovery flows for recoverable errors
- [ ] Error logging with context

---

## Phase 2: Observability

### 2.1 Analytics Foundation

**The Problem**: No data on user behavior. Can't measure success.

**The Solution**: Privacy-respecting, on-device-first analytics.

```swift
// New: Analytics.swift

/// Privacy-first analytics — no PII, aggregated metrics only
actor AnalyticsEngine {

    // MARK: - Events (no user identification)

    enum Event {
        // Funnel
        case onboardingStarted
        case onboardingCompleted(durationSeconds: Int)
        case onboardingAbandoned(atStep: String)

        // Core loop
        case scenarioSelected(id: String)
        case recordingStarted(scenarioId: String)
        case recordingCompleted(durationSeconds: Int)
        case recordingAbandoned(afterSeconds: Int)

        // Engagement
        case feedbackViewed(score: Int)
        case tryAgainTapped(previousScore: Int)
        case sessionShared

        // Retention
        case appOpened(daysSinceInstall: Int)
    }

    func track(_ event: Event) {
        // 1. Store locally (always)
        LocalAnalyticsStore.shared.record(event)

        // 2. Send to backend (if user opted in)
        if PrivacySettings.shared.analyticsEnabled {
            Task {
                try? await AnalyticsAPI.send(event.anonymized)
            }
        }
    }
}
```

**Key Metrics Dashboard**:

| Metric | Formula | Target |
|--------|---------|--------|
| Onboarding Completion | completed / started | > 70% |
| Time to First Recording | median seconds | < 90s |
| D1 Retention | users Day 1 / installs | > 40% |
| D7 Retention | users Day 7 / installs | > 20% |
| Sessions per User per Week | total sessions / WAU | > 3 |
| Try Again Rate | try again / feedback viewed | > 30% |

**Deliverables**:
- [ ] AnalyticsEngine with all events
- [ ] Local storage for offline events
- [ ] Privacy settings UI
- [ ] Dashboard endpoint (or Firebase/Amplitude integration)
- [ ] Funnel visualization

---

### 2.2 Crash Reporting

**The Problem**: No visibility into production crashes.

**The Solution**: Sentry or Firebase Crashlytics integration.

```swift
// AppDelegate or App init
import Sentry

SentrySDK.start { options in
    options.dsn = "https://your-dsn@sentry.io/project"
    options.tracesSampleRate = 0.2
    options.attachScreenshot = true
    options.enableAutoSessionTracking = true

    // Privacy: no PII
    options.beforeSend = { event in
        event.user = nil  // Strip user data
        return event
    }
}
```

**Deliverables**:
- [ ] Sentry/Crashlytics SDK integration
- [ ] Custom breadcrumbs for user flow
- [ ] Performance monitoring for recording/analysis
- [ ] Release tracking with dSYM upload

---

## Phase 3: Production Hardening

### 3.1 Localization Infrastructure

**The Problem**: English-only. Limits market.

**The Solution**: String Catalogs + Localization workflow.

```swift
// Before
Text("Everyone has conversations they dread.")

// After
Text("onboarding.welcome.title", tableName: "Localizable")

// String Catalog (Localizable.xcstrings)
{
    "onboarding.welcome.title": {
        "en": "Everyone has conversations they dread.",
        "es": "Todos tenemos conversaciones que tememos.",
        "ja": "誰もが恐れる会話があります。"
    }
}
```

**Localization Priority**:

| Language | Market Size | Priority |
|----------|-------------|----------|
| English | Base | Done |
| Spanish | 500M speakers | P1 |
| Japanese | High App Store spend | P1 |
| German | High App Store spend | P2 |
| French | 300M speakers | P2 |
| Portuguese | 250M speakers | P2 |

**Deliverables**:
- [ ] String Catalog created
- [ ] All user-facing strings extracted
- [ ] Pluralization rules implemented
- [ ] RTL layout support
- [ ] Date/number formatting localized

---

### 3.2 CI/CD Pipeline

**The Problem**: Manual builds are slow and error-prone.

**The Solution**: GitHub Actions + Fastlane.

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app

      - name: Run Tests
        run: |
          xcodebuild test \
            -scheme QuietCoach \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
            -resultBundlePath TestResults.xcresult

      - name: Upload Results
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: TestResults.xcresult

  build:
    needs: test
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Build for Release
        run: fastlane build

      - name: Upload to TestFlight
        if: github.ref == 'refs/heads/main'
        run: fastlane beta
        env:
          APP_STORE_CONNECT_API_KEY: ${{ secrets.ASC_KEY }}
```

**Deliverables**:
- [ ] GitHub Actions workflow
- [ ] Fastlane configuration
- [ ] Automatic TestFlight deployment
- [ ] Code signing with match
- [ ] Version bumping automation

---

### 3.3 Offline Resilience

**The Problem**: No handling for network failures, sync conflicts.

**The Solution**: Offline-first architecture.

```swift
// Subscription verification with offline support
actor SubscriptionManager {

    func verifySubscription() async -> SubscriptionStatus {
        // 1. Check cache first (instant UI)
        if let cached = CachedSubscription.load(),
           cached.isValid {
            return cached.status
        }

        // 2. Try network verification
        do {
            let status = try await StoreKit.verifySubscription()
            CachedSubscription.save(status, validFor: .hours(24))
            return status
        } catch {
            // 3. Graceful degradation
            if let cached = CachedSubscription.load() {
                // Use stale cache with warning
                return cached.status.withStaleWarning()
            }
            // 4. Fail open for good UX (verify later)
            return .unknown
        }
    }
}
```

**Deliverables**:
- [ ] Cached subscription status
- [ ] Retry logic with exponential backoff
- [ ] Offline indicator in UI
- [ ] Sync conflict resolution for iCloud

---

### 3.4 Audio Session Handling

**The Problem**: No handling for interruptions (calls, Siri, other apps).

**The Solution**: Proper AVAudioSession management.

```swift
// Enhanced RehearsalRecorder
final class RehearsalRecorder {

    private func setupAudioSession() throws {
        let session = AVAudioSession.sharedInstance()

        try session.setCategory(
            .playAndRecord,
            mode: .spokenAudio,
            options: [.defaultToSpeaker, .allowBluetooth]
        )

        // Handle interruptions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: session
        )

        // Handle route changes (headphones unplugged)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: session
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            // Phone call, Siri, etc.
            pauseRecording()
            delegate?.recorderWasInterrupted(self)

        case .ended:
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    resumeRecording()
                }
            }
        }
    }
}
```

**Deliverables**:
- [ ] Interruption handling (pause/resume)
- [ ] Route change handling
- [ ] Background task completion for saving
- [ ] Memory warning handling

---

## Phase 4: Architecture Improvement

### 4.1 Dependency Injection

**The Problem**: 7 singletons make testing impossible.

**The Solution**: Protocol-based DI with a simple container.

```swift
// Protocols for all services
protocol SessionRepositoryProtocol {
    func save(_ session: RehearsalSession) async throws
    func fetch(id: String) async -> RehearsalSession?
    var recentSessions: [RehearsalSession] { get }
}

protocol SpeechAnalyzerProtocol {
    func analyze(audioURL: URL) async throws -> AnalysisResult
}

protocol FeatureGatesProtocol {
    var isPro: Bool { get }
    func canAccessScenario(_ scenario: Scenario) -> Bool
}

// Simple DI Container
@MainActor
final class AppContainer {
    static let shared = AppContainer()

    // Production dependencies
    lazy var sessionRepository: SessionRepositoryProtocol = SessionRepository()
    lazy var speechAnalyzer: SpeechAnalyzerProtocol = SpeechAnalysisEngine()
    lazy var featureGates: FeatureGatesProtocol = FeatureGates()

    // For testing
    #if DEBUG
    func override<T>(keyPath: WritableKeyPath<AppContainer, T>, with mock: T) {
        self[keyPath: keyPath] = mock
    }
    #endif
}

// Usage in views
struct ReviewView: View {
    let repository: SessionRepositoryProtocol

    init(repository: SessionRepositoryProtocol = AppContainer.shared.sessionRepository) {
        self.repository = repository
    }
}
```

**Deliverables**:
- [ ] Protocols for all services
- [ ] AppContainer with lazy initialization
- [ ] Views accept injected dependencies
- [ ] Test helpers for mocking

---

## Implementation Timeline

### Sprint 1-2: Core Feature (Critical)
- [ ] SpeechAnalysisEngine implementation
- [ ] Filler word detection
- [ ] Pacing calculation
- [ ] Basic testing infrastructure
- [ ] 10 unit tests for analysis

### Sprint 3-4: Quality & Observability
- [ ] Error handling system
- [ ] Crash reporting integration
- [ ] Analytics foundation
- [ ] 20 more unit tests
- [ ] CI pipeline

### Sprint 5-6: Production Hardening
- [ ] Localization infrastructure
- [ ] Spanish + Japanese translations
- [ ] Audio session handling
- [ ] Offline resilience
- [ ] Integration tests

### Sprint 7-8: Architecture & Polish
- [ ] Dependency injection refactor
- [ ] Memory optimization
- [ ] Performance profiling
- [ ] Privacy audit
- [ ] App Store submission

---

## Success Criteria

| Metric | Current | Target | Deadline |
|--------|---------|--------|----------|
| Test Coverage | 0% | 60% | Sprint 4 |
| Crash-free Rate | Unknown | 99.5% | Sprint 6 |
| Analysis Accuracy | 0% (random) | 85% | Sprint 2 |
| Onboarding Completion | Unknown | 70% | Sprint 4 |
| D7 Retention | Unknown | 20% | Sprint 8 |

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Speech analysis accuracy too low | Fall back to simpler metrics (WPM, duration) with honest positioning |
| Apple rejects for privacy | Pre-submission privacy review, App Privacy Report |
| Localization delays launch | Launch English-only, add languages post-launch |
| CI costs too high | Use self-hosted runner or optimize build times |

---

## The Path Forward

```
Week 1-2:  Make it work (real analysis)
Week 3-4:  Make it reliable (tests, errors, crashes)
Week 5-6:  Make it ready (localization, offline, polish)
Week 7-8:  Ship it (CI/CD, App Store)
```

**The goal isn't perfection. It's shipping something real that we can measure and improve.**

---

*"First make it work, then make it right, then make it fast."*
— Kent Beck

---

**Classification**: Engineering Roadmap
**Version**: 1.0
**Owner**: Engineering Team
