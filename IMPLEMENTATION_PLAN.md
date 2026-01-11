# QuietCoach 11/10 Implementation Plan
## Ralph Mode: Draft → Critique → Synthesize → Build

---

## Phase 1: P0 Features (Trust & Core Polish)

### 1.1 Privacy Control Center
**Location:** New section in SettingsView + dedicated PrivacyControlView

**Components:**
- Sessions count (from SessionRepository)
- Storage used (FileManager calculation of Recordings folder)
- Export All Data button → ZIP of JSON sessions + audio files
- Delete Everything button → double-confirm, wipe SwiftData + FileStore
- Spotlight indexing toggle
- HealthKit logging toggle (placeholder for future)

**Architecture:**
```
PrivacyControlView.swift (new)
├── StorageMetrics (computed from FileStore + SwiftData)
├── ExportManager (ZIP creation using ZIPFoundation-free approach)
└── PrivacySettings integration
```

### 1.2 Audio Quality Guardrails
**Location:** RehearsalRecorder + RehearseView + ReviewView

**Components:**
- Real-time quality detection during recording:
  - Too quiet (post-calibration RMS below threshold)
  - Clipping (peak > 0.95)
  - High background noise (noise floor > threshold)
- Soft dismissible banners in RehearseView
- Post-recording quality note in ReviewView

**Architecture:**
```
AudioQualityMonitor (new enum in RehearsalRecorder)
├── QualityIssue enum (tooQuiet, clipping, noisy)
├── Real-time detection in metering loop
└── activeQualityIssue published property
```

---

## Phase 2: P1 Features (Premium Feel & Retention)

### 2.1 iOS 26 Voice Isolation
**Location:** RehearsalRecorder + RehearseView

**Components:**
- Check for iOS 26 AVAudioSession.VoiceIsolation availability
- Toggle in recording toolbar/settings
- Banner suggesting AirPods for best quality
- Graceful fallback on older iOS

### 2.2 Progress Comparison Badges
**Location:** ReviewView + ScoreCard

**Components:**
- Fetch previous session for same scenario
- Calculate delta for each score
- Display "+X" or "-X" badges with color coding
- Tiny sparkline (last 5 sessions) using Swift Charts

### 2.3 Calm Start Breathing Ritual
**Location:** New BreathingRitualView + RehearseView

**Components:**
- 8-10 second animated breathing circle
- Gentle haptic rhythm (inhale/exhale)
- Skip button for returning users
- User preference to disable in Settings

### 2.4 Anchor Phrase Field
**Location:** ReviewView + RehearsalSession model

**Components:**
- Optional text field: "One phrase I'll say next time"
- Saved to session
- Displayed as reminder in next rehearsal for same scenario

---

## Implementation Order

1. PrivacyControlView.swift (new file)
2. Audio quality detection in RehearsalRecorder
3. Quality banners in RehearseView
4. Voice Isolation toggle
5. Progress badges in ReviewView
6. BreathingRitualView.swift (new file)
7. Anchor phrase field + model update

---

## Success Criteria

- [ ] Privacy Control Center shows accurate storage metrics
- [ ] Export creates valid ZIP with all data
- [ ] Delete Everything wipes all user data
- [ ] Audio quality warnings appear when appropriate
- [ ] Voice Isolation works on iOS 26+ with graceful fallback
- [ ] Progress badges show accurate deltas
- [ ] Breathing ritual is skippable and respects preferences
- [ ] Anchor phrase persists across sessions
- [ ] All features build without warnings
- [ ] Accessibility labels on all new UI elements
