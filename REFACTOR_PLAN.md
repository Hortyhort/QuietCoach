# QuietCoach Refactoring Plan

## Goals
- All files under 500 lines (ideally under 300)
- Single Responsibility Principle
- Clear folder structure
- Easy to navigate and maintain
- Professional codebase standards

---

## File Analysis

### Files Over 500 Lines

| File | Lines | Issues |
|------|-------|--------|
| ElevatedDesign.swift | 680 | 6+ unrelated components mixed together |
| SpeechAnalysisEngine.swift | 643 | Analysis logic + result types + patterns combined |
| RehearsalRecorder.swift | 553 | Recording + state + interruptions mixed |
| Theme.swift | 533 | Colors + fonts + gradients + modifiers all in one |
| DependencyInjection.swift | 513 | Protocols + container + 7 mocks together |

---

## Refactoring Strategy

### 1. ElevatedDesign.swift (680 → 6 files, ~100 each)

**Current:** Monolithic design system file with animations, components, and effects.

**Split into:**
```
QuietCoach/
├── Design/
│   ├── MoodColors.swift           (~50 lines)
│   │   └── AppMood enum, Color.qcMood* extensions
│   │
│   ├── Animations/
│   │   ├── ConfidencePulse.swift  (~130 lines)
│   │   │   └── ConfidencePulseView, WaveformPulseView
│   │   │
│   │   └── TypographyEffects.swift (~110 lines)
│   │       └── TypewriterText, LiquidScoreText
│   │
│   └── Components/
│       ├── LiquidGlass.swift      (~100 lines)
│       │   └── LiquidGlassCard, BreathingModifier
│       │
│       └── InteractiveEffects.swift (~160 lines)
│           └── MagneticButton, TiltCardModifier, 
│               AuroraGlowModifier, ParticleBurstView
```

**Rationale:**
- Animations are grouped together (score reveal, text effects)
- Reusable components are separate (glass cards, buttons)
- Mood colors are foundational, in their own file

---

### 2. SpeechAnalysisEngine.swift (643 → 4 files, ~160 each)

**Current:** Actor with optional on-device transcription (opt-in, default off), 4 analysis methods, result structs, and pattern dictionaries.

**Split into:**
```
QuietCoach/
├── Audio/
│   └── Analysis/
│       ├── SpeechAnalysisEngine.swift  (~180 lines)
│       │   └── Main actor, optional transcription (opt-in, default off), analyze() orchestration
│       │
│       ├── AnalysisResults.swift       (~200 lines)
│       │   └── SpeechAnalysisResult, TranscriptionResult (optional),
│       │       ClarityAnalysis, PacingAnalysis, 
│       │       ConfidenceAnalysis, ToneAnalysis, PauseEvent
│       │
│       ├── AnalysisMethods.swift       (~150 lines)
│       │   └── Extension: analyzeClarity, analyzePacing,
│       │       analyzeConfidence, analyzeTone, tokenize helpers
│       │
│       └── SpeechPatterns.swift        (~80 lines)
│           └── Static pattern dictionaries: fillerPatterns,
│               hedgingPatterns, assertivePatterns, etc.
```

**Rationale:**
- Clean separation: engine, results, methods, data
- Result types are reusable across the app
- Patterns are pure data, easy to extend

---

### 3. RehearsalRecorder.swift (553 → 3 files, ~180 each)

**Current:** State machine, warnings, recording, metering, interruptions all mixed.

**Split into:**
```
QuietCoach/
├── Audio/
│   └── Recording/
│       ├── RehearsalRecorder.swift      (~280 lines)
│       │   └── Core recording: start, pause, resume, stop,
│       │       metering, audio session setup
│       │
│       ├── RecordingTypes.swift         (~80 lines)
│       │   └── State enum, RecordingWarning enum,
│       │       formattedTime extensions
│       │
│       └── RecordingInterruptions.swift (~120 lines)
│           └── Interruption handling, route changes,
│               RecordingInterruptionDelegate protocol
```

**Rationale:**
- Core recorder stays focused on recording
- Types/enums are extracted for clarity
- Interruption handling is its own concern

---

### 4. Theme.swift (533 → 5 files, ~100 each)

**Current:** Everything visual in one file.

**Split into:**
```
QuietCoach/
├── Support/
│   └── Theme/
│       ├── Colors.swift              (~80 lines)
│       │   └── Color.qc* extensions (background, text, accent, etc.)
│       │
│       ├── Typography.swift          (~80 lines)
│       │   └── Font.qc* extensions, variable fonts
│       │
│       ├── Formatting.swift          (~50 lines)
│       │   └── TimeInterval.qcFormattedDuration,
│       │       Date.qcShortString, etc.
│       │
│       ├── ViewModifiers.swift       (~100 lines)
│       │   └── qcCardShadow, qcCardRadius, qcGlassBackground,
│       │       qcGlow, qcShimmer, qcPressEffect
│       │
│       └── MeshGradients.swift       (~130 lines)
│           └── AudioReactiveMeshGradient, AmbientMeshGradient,
│               CelebrationMeshGradient
│
│       └── SymbolAnimations.swift    (~90 lines)
│           └── qcWaveformAnimation, qcBounceEffect,
│               qcPulseEffect, sensory feedback modifiers
```

**Rationale:**
- Colors and fonts are foundational
- Modifiers are grouped by purpose
- Mesh gradients are complex, deserve own file

---

### 5. DependencyInjection.swift (513 → 3 files)

**Current:** Protocols, container, and all mocks mixed.

**Split into:**
```
QuietCoach/
├── Support/
│   └── DI/
│       ├── ServiceProtocols.swift     (~110 lines)
│       │   └── All 7 protocol definitions
│       │
│       ├── AppContainer.swift         (~100 lines)
│       │   └── AppContainer class, environment key,
│       │       @Injected property wrapper
│       │
│       └── MockServices.swift         (~280 lines, DEBUG only)
│           └── All mock implementations:
│               MockSessionRepository, MockFeatureGates,
│               MockSpeechAnalyzer, MockAnalytics, etc.
```

**Rationale:**
- Protocols are the public API
- Container is the implementation
- Mocks are test-only, conditionally compiled

---

## New Folder Structure

```
QuietCoach/
├── App/
│   ├── QuietCoachApp.swift
│   ├── AppIntents.swift
│   └── MenuBarApp.swift
│
├── Design/                          # NEW
│   ├── MoodColors.swift
│   ├── Animations/
│   │   ├── ConfidencePulse.swift
│   │   └── TypographyEffects.swift
│   └── Components/
│       ├── LiquidGlass.swift
│       └── InteractiveEffects.swift
│
├── Domain/
│   ├── Scenario.swift
│   ├── AudioMetrics.swift
│   ├── FeedbackScores.swift
│   └── CoachNote.swift
│
├── Data/
│   ├── RehearsalSession.swift
│   ├── FileStore.swift
│   ├── SessionRepository.swift
│   └── SubscriptionManager.swift
│
├── Audio/
│   ├── Recording/                   # REORGANIZED
│   │   ├── RehearsalRecorder.swift
│   │   ├── RecordingTypes.swift
│   │   └── RecordingInterruptions.swift
│   ├── Analysis/                    # REORGANIZED
│   │   ├── SpeechAnalysisEngine.swift
│   │   ├── AnalysisResults.swift
│   │   ├── AnalysisMethods.swift
│   │   └── SpeechPatterns.swift
│   ├── AudioMetricsAnalyzer.swift
│   ├── AudioPlayerViewModel.swift
│   ├── TranscriptionEngine.swift
│   └── SoundDesign.swift
│
├── Feedback/
│   ├── FeedbackEngine.swift
│   ├── CoachNotesEngine.swift
│   ├── IntelligentCoach.swift
│   └── CoachPersonality.swift
│
├── UI/
│   ├── Navigation/
│   ├── Screens/
│   └── Components/
│
├── Support/
│   ├── Theme/                       # REORGANIZED
│   │   ├── Colors.swift
│   │   ├── Typography.swift
│   │   ├── Formatting.swift
│   │   ├── ViewModifiers.swift
│   │   ├── MeshGradients.swift
│   │   └── SymbolAnimations.swift
│   ├── DI/                          # REORGANIZED
│   │   ├── ServiceProtocols.swift
│   │   ├── AppContainer.swift
│   │   └── MockServices.swift
│   ├── Constants.swift
│   ├── Haptics.swift
│   ├── FeatureGates.swift
│   ├── Accessibility.swift
│   └── ... (other support files)
│
└── Resources/
```

---

## Implementation Order

### Phase A: Theme Refactoring (Low Risk)
1. Create `Support/Theme/` folder
2. Extract `Colors.swift` from Theme.swift
3. Extract `Typography.swift`
4. Extract `Formatting.swift`
5. Extract `ViewModifiers.swift`
6. Extract `MeshGradients.swift`
7. Extract `SymbolAnimations.swift`
8. Delete original Theme.swift
9. Update project file
10. Verify build

### Phase B: DI Refactoring (Low Risk)
1. Create `Support/DI/` folder
2. Extract `ServiceProtocols.swift`
3. Extract `AppContainer.swift`
4. Extract `MockServices.swift`
5. Delete original DependencyInjection.swift
6. Update project file
7. Verify build + tests

### Phase C: Audio Refactoring (Medium Risk)
1. Create `Audio/Recording/` and `Audio/Analysis/` folders
2. Extract `RecordingTypes.swift`
3. Extract `RecordingInterruptions.swift`
4. Trim RehearsalRecorder.swift
5. Extract `AnalysisResults.swift`
6. Extract `SpeechPatterns.swift`
7. Extract `AnalysisMethods.swift`
8. Trim SpeechAnalysisEngine.swift
9. Update project file
10. Verify build

### Phase D: Design Refactoring (Medium Risk)
1. Create `Design/` folder structure
2. Extract `MoodColors.swift`
3. Extract `ConfidencePulse.swift`
4. Extract `TypographyEffects.swift`
5. Extract `LiquidGlass.swift`
6. Extract `InteractiveEffects.swift`
7. Delete ElevatedDesign.swift
8. Update project file
9. Verify build

---

## Success Criteria

After refactoring:
- [ ] All files under 500 lines
- [ ] No file has more than 2-3 related types
- [ ] Clear import paths
- [ ] Build succeeds
- [ ] All tests pass
- [ ] Easy to find any component

---

## Estimated Result

| Before | After |
|--------|-------|
| 5 files > 500 lines | 0 files > 500 lines |
| ElevatedDesign.swift (680) | 6 files (~100 each) |
| SpeechAnalysisEngine.swift (643) | 4 files (~160 each) |
| RehearsalRecorder.swift (553) | 3 files (~180 each) |
| Theme.swift (533) | 6 files (~90 each) |
| DependencyInjection.swift (513) | 3 files (~160 each) |

Total new files: 22 (replacing 5 bloated files)
Average file size: ~120 lines
