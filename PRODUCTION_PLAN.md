# QuietCoach Production Readiness Plan

## Current Status: ~85% Production Ready

## Ralph Brainstormer Output (Release Lens)

### Objective
- Refine QuietCoach into an Apple-grade, privacy-first iOS app that helps users rehearse hard conversations in under 3 minutes, with minimal UI, explainable coaching feedback, and a compelling V1 feature set.

### Synthesis (Release Constraints)
- One primary action per screen; no dashboard energy.
- 3-line feedback only: win, change, try again rephrase.
- Always end with a Try Again next step.
- On-device by default; no accounts; transcripts/NLP are opt-in, default off, with a metrics-only fallback when disabled.
- V1 includes scenario selection, record + playback, local sessions, share card.
- Add small premium polish: Coach Tone, 1-minute rehearsal mode.
- Defer features that add analytical weight.

### Boardroom Risks (Launch Gate)
- Feedback must be earned; each line tied to measured signals.
- "3 minutes" should be framed as "start rehearsal in 3 minutes."
- Share card must be optional and minimal (no transcript).
- Default interaction must be single-tap, no choice overload.

### Launch Success Criteria
- Time to first rehearsal under 60 seconds
- Try Again rate above 35 percent
- User-reported preparedness improves after rehearsal
- App Store rating 4.8+

### Already Completed
- [x] Core recording, playback, and scoring functionality
- [x] On-device, opt-in speech analysis with filler word detection (default off; metrics-only mode when disabled)
- [x] Comprehensive error handling framework
- [x] Integration tests for core flows
- [x] Translations (English, Spanish, Japanese)
- [x] Performance monitoring instrumentation
- [x] App Store metadata and privacy policy
- [x] TestFlight deployment configuration
- [x] Accessibility audit and improvements
- [x] Export All Data functionality

---

## Phase 1: Critical Polish (Launch Blockers)
*These issues affect core value proposition and user trust*

### 1.1 Real Waveform Visualization
**Priority: HIGH | Effort: Medium**
- Replace `generatePlaceholderWaveform()` with actual audio sample analysis
- Extract waveform data during recording (already have samples in RehearsalRecorder)
- Store waveform data with session for playback visualization
- Affects: ReviewView.swift, RehearsalSession.swift

### 1.2 Share Image Generation
**Priority: HIGH | Effort: Low**
- Implement `generateShareImage()` to render ShareCardView to UIImage
- Use SwiftUI's ImageRenderer (iOS 16+)
- Affects: ReviewView.swift

### 1.3 Empty State for HomeView
**Priority: HIGH | Effort: Low**
- Add welcoming empty state when no sessions exist
- Guide new users to start their first rehearsal
- Affects: HomeView.swift

---

## Phase 2: Feature Completion (Pre-Launch Polish)
*Complete stubbed features and remove TODOs*

### 2.1 Session History View
**Priority: MEDIUM | Effort: Medium**
- Implement "See All" navigation from HomeView
- Create HistoryView with full session list
- Add filtering/sorting options
- Affects: HomeView.swift, new HistoryView.swift

### 2.2 Structure Guide Sheet
**Priority: MEDIUM | Effort: Low**
- Implement "Guide" button in RehearseView
- Show scenario-specific structure tips
- Help users organize their rehearsal
- Affects: RehearseView.swift, new StructureGuideSheet.swift

### 2.3 Onboarding Flow Consolidation
**Priority: MEDIUM | Effort: Low**
- Determine which onboarding flow to use (Standard vs Elevated)
- Complete any missing pieces in chosen flow
- Remove unused flow or feature-flag it
- Affects: OnboardingView.swift, ElevatedOnboarding.swift

---

## Deferred / VNext

### Session Comparison View
**Priority: MEDIUM | Effort: Medium**
- Side-by-side comparison of two sessions
- Visual diff of scores and improvements
- Accessible from History or Review views
- Affects: new SessionComparisonView.swift

---

## Phase 3: Content & Engagement
*Expand value for Pro users and retention*

### 3.1 Additional Pro Scenarios
**Priority: MEDIUM | Effort: Medium**
- Add 5-10 new scenarios for Pro subscribers
- Categories: Interview prep, Public speaking, Conflict resolution
- Ensure each has coaching hints and structure guides
- Affects: Scenario.swift

### 3.2 Daily Reminder Notifications
**Priority: LOW | Effort: Low**
- Optional local notifications for rehearsal reminders
- Configurable time preference
- Respect Do Not Disturb
- Affects: new NotificationManager.swift, SettingsView.swift

---

## Phase 4: Platform Expansion (Post-Launch)
*Extend reach to new surfaces*

### 4.1 watchOS Companion App
**Priority: LOW | Effort: High**
- Quick rehearsal from wrist
- View recent scores
- New target: QuietCoachWatch

### 4.2 macOS Catalyst/Native
**Priority: LOW | Effort: High**
- MacHomeView.swift exists but needs completion
- Menu bar quick access (MenuBarApp.swift exists)
- Keyboard shortcuts for recording

### 4.3 visionOS Support
**Priority: LOW | Effort: Medium**
- SpatialHomeView.swift exists but needs completion
- Immersive rehearsal environment
- 3D waveform visualization

---

## Phase 5: Advanced Features (Future)
*Differentiation and delight*

### 5.1 AI-Powered Feedback Enhancement
- Use on-device ML for tone analysis
- Detect confidence patterns over time
- Personalized coaching suggestions

### 5.2 Practice Mode Variations
- Timed challenges
- Random scenario generator
- Structured drills

### 5.3 Social Features
- Share rehearsal cards
- Community scenarios
- Coaching marketplace

---

## Implementation Order

### Week 1-2: Phase 1 (Launch Blockers)
1. Real waveform visualization
2. Share image generation
3. Empty state for HomeView

### Week 3-4: Phase 2 (Feature Completion)
4. Session History View
5. Structure Guide Sheet
6. Onboarding consolidation

### Week 5-6: Phase 3 (Content & Engagement)
7. Additional Pro scenarios
8. Daily reminder notifications

### Post-Launch: Phases 4-5
- watchOS, macOS, visionOS
- Advanced AI features
- Social features

---

## Quality Gates Before Launch

- [ ] All Phase 1 items complete
- [ ] All Phase 2 items complete (or consciously deferred)
- [ ] Zero crash reports in TestFlight beta
- [ ] App Store screenshots captured
- [ ] App icon finalized (1024x1024)
- [ ] Privacy policy URL live
- [ ] Support email configured
- [ ] TestFlight beta with 10+ external testers
- [ ] Performance: <2s cold launch, <100MB memory
- [ ] Accessibility: VoiceOver full pass
- [ ] Localization: Native speaker review

---

## Files Reference

### Phase 1 Touch Points
- `QuietCoach/UI/Screens/ReviewView.swift`
- `QuietCoach/UI/Screens/HomeView.swift`
- `QuietCoach/Data/RehearsalSession.swift`
- `QuietCoach/Audio/RehearsalRecorder.swift`

### Phase 2 New Files Needed
- `QuietCoach/UI/Screens/HistoryView.swift`
- `QuietCoach/UI/Components/StructureGuideSheet.swift`

### Phase 3 New Files Needed
- `QuietCoach/Support/NotificationManager.swift`
- `QuietCoach/Domain/AchievementManager.swift`
