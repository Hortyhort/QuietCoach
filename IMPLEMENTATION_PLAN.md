# QuietCoach 11/10 Implementation Plan
## Ralph Mode: Draft → Critique → Synthesize → Build

---

## Ralph Brainstormer Output (Apple Exec Direction)

### Objective
- Refine QuietCoach into an Apple-grade, privacy-first iOS app that helps users rehearse hard conversations in under 3 minutes, with minimal UI, explainable coaching feedback, and a compelling V1 feature set.

### Draft: Executive Perspectives

#### Apple Product Exec
- Promise: "Rehearse a hard conversation and feel meaningfully more prepared in 3 minutes."
- Flow: Home -> Scenario -> Rehearse -> Review -> Try Again -> Share; one primary action per screen.
- Feedback: 3-line format only (win, change, try again rephrase); always end with a next step.
- Tone: calm, non-judgmental microcopy; coach presence line; subtle haptics and pacing.
- Cuts: no dashboards, no chat UI, no accounts; transcripts are on-device + opt-in, default off.

#### Staff iOS Engineer
- Architecture: SwiftUI + SwiftData + AVAudioEngine; on-device storage; no account layer.
- Audio pipeline: record -> analyze duration/pauses/rate/loudness variance; optional on-device transcript (opt-in, default off) with a metrics-only fallback when disabled.
- Feedback engine: deterministic, explainable heuristics weighted by scenario; no cloud dependency.
- Data model: RehearsalSession + AudioMetrics + CoachNote; share card rendered via ImageRenderer.
- Risks: mic variability and noise; include audio quality guardrails and permission gating.

#### Growth/Distribution
- Onboarding: first rehearsal in under 60 seconds; no account gate.
- Pricing: free with a small scenario set; Pro unlocks full library plus coach tone.
- Retention: gentle daily nudge plus weekly recap.
- Share loop: minimal rehearsal card, no transcript, optional watermark.
- App Store: strong privacy story; avoid health claims and over-promises.

### Judge: Rubric + Scores

**Rubric (0-100 each, no mercy):**
- Creates a "Try Again" loop
- Calm and minimal
- Privacy-first and explainable
- Buildable cleanly in V1
- Premium feel without bloat

**Scores:**
- Apple Product Exec: 94
- Staff iOS Engineer: 90
- Growth/Distribution: 86
- Winner: Apple Product Exec, with Engineer as build guardrail

### Boardroom Critique (fatal flaws only)
- Feedback feels unearned if not tied to measured signals; every line must cite what was detected.
- "Hold to talk" vs "tap to record" adds friction; pick one default interaction.
- Share card could feel awkward; keep minimal and optional.
- "3 minutes" can read as a claim; position as "start rehearsal in 3 minutes."
- Scenario weighting may feel opaque; add a subtle focus-area hint in review.

### Synthesis
- Commit to the diamond flow with a single dominant action per screen and a clear Try Again loop.
- Keep 3-line feedback format; tie each line to measurable signals and a direct next step.
- V1 features: scenario selection, record + playback, local sessions, share card.
- Add: Coach Tone (gentle/direct/executive) and 1-minute rehearsal mode for polish.
- Cut: dashboards, social, accounts.
- Privacy: on-device by default, transparent controls, no cloud dependency.
- Transcript/NLP features are on-device and opt-in, default off; when off, feedback runs in a metrics-only mode.

### Build Plan (V1)

**Primary UI flow:**
1. Home (Start Rehearsal, Continue Last, last 3 sessions with 1 metric each)
2. Scenario selection (human labels; scenario weights)
3. Rehearse (single button; live waveform; coach line)
4. Review (3 cards max: Win, Change, Try Again script; Try Again button)
5. Share (rehearsal card only; no transcript)

**Feedback output format:**
- What worked: short, earned win
- What to change: single highest-leverage fix tied to a metric
- Try this: one rephrase

**Architecture notes:**
- Scenario weighting table for feedback heuristics (pace/warmth/confidence).
- Audio metrics analyzer for duration, pauses, rate, loudness variance.
- CoachNotesEngine maps metrics to 3-line output.

**Success criteria:**
- Time to first rehearsal under 60 seconds
- Try Again rate above 35 percent
- User-reported preparedness improves after rehearsal
- App Store rating 4.8+

### Alignment With Existing Phases
- Keep: Privacy Control Center, Audio Quality Guardrails, Voice Isolation, Calm Start Breathing, Anchor Phrase Field.
- Defer: comparative feedback views (see Deferred / VNext).
- Ensure review UI stays 3-card max and Try Again is the primary action.

---

## Phase 1: P0 Features (Trust & Core Polish)

### 1.1 Privacy Control Center
**Location:** New section in SettingsView + dedicated PrivacyControlView

**Components:**
- Sessions count (from SessionRepository)
- Storage used (FileManager calculation of Recordings folder)
- Export All Data button (✅ done) → ZIP of JSON sessions + audio files
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

### 2.2 Calm Start Breathing Ritual
**Location:** New BreathingRitualView + RehearseView

**Components:**
- 8-10 second animated breathing circle
- Gentle haptic rhythm (inhale/exhale)
- Skip button for returning users
- User preference to disable in Settings

### 2.3 Anchor Phrase Field
**Location:** ReviewView + RehearsalSession model

**Components:**
- Optional text field: "One phrase I'll say next time"
- Saved to session
- Displayed as reminder in next rehearsal for same scenario

---

## Deferred / VNext

### Session Trend Notes
**Location:** ReviewView + HistoryView

**Components:**
- Lightweight trend cue based on last few sessions (e.g., "Clarity steadier")
- No numeric deltas or comparison indicators
- Optional sparkline if it doesn't add analytical weight

---

## Implementation Order

1. PrivacyControlView.swift (new file)
2. Audio quality detection in RehearsalRecorder
3. Quality banners in RehearseView
4. Voice Isolation toggle
5. BreathingRitualView.swift (new file)
6. Anchor phrase field + model update

---

## Success Criteria

- [ ] Privacy Control Center shows accurate storage metrics
- [ ] Export creates valid ZIP with all data (regression check)
- [ ] Delete Everything wipes all user data
- [ ] Audio quality warnings appear when appropriate
- [ ] Voice Isolation works on iOS 26+ with graceful fallback
- [ ] Breathing ritual is skippable and respects preferences
- [ ] Anchor phrase persists across sessions
- [ ] All features build without warnings
- [ ] Accessibility labels on all new UI elements
