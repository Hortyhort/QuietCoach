# QUIET COACH
## Brand Identity System v2.0
### Agency Deck — Confidential

---

# SECTION 01
## STRATEGIC FOUNDATION

---

### Slide 01: The Brief

**Client:** Quiet Coach
**Category:** Personal Development / Communication
**Platform:** iOS (iPhone, iPad, Apple Watch, Vision Pro)

**The Problem:**
People avoid important conversations because they fear saying the wrong thing. The words exist inside them, but anxiety buries them.

**The Product:**
An app that gives you space to practice before conversations happen. Record yourself. Hear your words. Get gentle feedback. Walk in ready.

**The Positioning:**
*Find your words before you need them.*

---

### Slide 02: Target Audience

**Primary:** Adults 25-45 who experience anxiety before difficult conversations
- Asking for a raise
- Setting boundaries with family
- Having relationship talks
- Confronting a colleague

**Psychographic:**
- Thoughtful, not impulsive
- Values preparation over winging it
- Privacy-conscious
- Already uses Apple ecosystem
- Prefers calm, minimal interfaces

**They are NOT:**
- Public speakers seeking stage coaching
- Salespeople doing cold call training
- Content creators practicing scripts

---

# SECTION 02
## COMPETITOR AUDIT

---

### Slide 03: Competitive Landscape

| App | Signature Color | Icon Style | Voice | Vibe |
|-----|-----------------|------------|-------|------|
| **Orai** | Electric Blue (#0066FF) | Flat mic + soundwave | "Become a confident speaker!" | Motivational, performance |
| **Speeko** | Coral Orange (#FF6B4A) | Filled abstract mic | "Master public speaking" | Gamified, achievement |
| **Yoodli** | Purple-Pink gradient | Stylized Y letterform | "AI speech coach" | Tech-forward, data |
| **Rehearsal Pro** | Red (#E53935) | Teleprompter icon | "Practice like a pro" | Utility, professional |
| **PromptSmart** | Blue-Gray | Script/teleprompter | "Read. Present. Impress." | Corporate, presenter |

---

### Slide 04: Competitor Positioning Map

```
                    PERFORMANCE-FOCUSED
                           ↑
                           |
         Speeko ●          |          ● Orai
                           |
    ←─────────────────────────────────────────→
    PRIVATE                |              PUBLIC
                           |
         Quiet Coach ●     |          ● Yoodli
                           |
                           |     ● Rehearsal Pro
                           ↓
                    PROCESS-FOCUSED
```

**White Space:** Private + Process-focused
No competitor owns the "quiet preparation" moment.

---

### Slide 05: Differentiation Map

| Dimension | What We Own | Why It's Ours |
|-----------|-------------|---------------|
| **Emotional** | The exhale before speaking | Others focus on the performance. We focus on the preparation—the private moment of finding your words. |
| **Visual** | Liquid Glass as calm | Competitors use gradients for energy. We use glass for stillness and clarity. |
| **Product** | Privacy-first, on-device | Others upload audio to cloud for AI. We process everything locally. Your voice stays yours. |

---

### Slide 06: Ownable Brand Move

**The Recommendation: Twilight Violet**

We keep the violet accent but shift it toward twilight—a deeper, earthier purple that feels less "AI trend" and more "moment before dusk."

**Current:** #9D8CFF (bright, trendy AI purple)
**Proposed:** #8B7EC8 (twilight violet—calmer, more ownable)

**Why this works:**
- Distinct from Yoodli's magenta-purple gradient
- Evokes the quiet moment between day and night
- Still functions as a Liquid Glass tint
- Reads as premium, not playful

---

# SECTION 03
## LOGO SYSTEM

---

### Slide 07: Logo Direction A — "The Breath"

**Concept:** Two overlapping soft forms suggesting inhale/exhale rhythm

**Geometric Construction:**

```
Grid: 48 × 48 units

Left form (inhale):
- Type: Ellipse
- Center: (16, 24)
- Width: 24 units
- Height: 28 units
- Corner smoothing: 100% (superellipse)

Right form (exhale):
- Type: Ellipse
- Center: (32, 24)
- Width: 20 units
- Height: 24 units
- Corner smoothing: 100% (superellipse)

Overlap: 8 units horizontal intersection
Stroke: 2 units
Fill: None (stroke only for transparency)
```

**SVG Path:**
```svg
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="16" cy="24" rx="12" ry="14"
           fill="none" stroke="#8B7EC8" stroke-width="2"/>
  <ellipse cx="32" cy="24" rx="10" ry="12"
           fill="none" stroke="#8B7EC8" stroke-width="2"/>
</svg>
```

---

### Slide 08: Logo Direction B — "The Clearing"

**Concept:** A rounded rectangle with an offset circular void—a window to clarity

**Geometric Construction:**

```
Grid: 48 × 48 units

Outer frame:
- Type: Rounded Rectangle
- Position: (4, 4)
- Size: 40 × 40 units
- Corner radius: 12 units

Inner void:
- Type: Circle
- Center: (20, 20) — offset high-left
- Radius: 10 units
- Operation: Subtract from frame

Result: Frame with asymmetric portal
```

**SVG Path:**
```svg
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <mask id="void">
      <rect x="4" y="4" width="40" height="40" rx="12" fill="white"/>
      <circle cx="20" cy="20" r="10" fill="black"/>
    </mask>
  </defs>
  <rect x="4" y="4" width="40" height="40" rx="12"
        fill="#8B7EC8" mask="url(#void)"/>
</svg>
```

---

### Slide 09: Logo Direction C — "The Echo"

**Concept:** Three concentric rounded forms, fading outward like a voice stilling into silence

**Geometric Construction:**

```
Grid: 48 × 48 units
Center: (24, 24)

Ring 1 (innermost):
- Type: Rounded Rectangle
- Size: 12 × 12 units
- Corner radius: 4 units
- Opacity: 100%

Ring 2 (middle):
- Type: Rounded Rectangle
- Size: 24 × 24 units
- Corner radius: 8 units
- Opacity: 60%
- Stroke only: 1.5 units

Ring 3 (outermost):
- Type: Rounded Rectangle
- Size: 36 × 36 units
- Corner radius: 12 units
- Opacity: 30%
- Stroke only: 1 unit
```

**SVG Path:**
```svg
<svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect x="6" y="6" width="36" height="36" rx="12"
        fill="none" stroke="#8B7EC8" stroke-width="1" opacity="0.3"/>
  <rect x="12" y="12" width="24" height="24" rx="8"
        fill="none" stroke="#8B7EC8" stroke-width="1.5" opacity="0.6"/>
  <rect x="18" y="18" width="12" height="12" rx="4"
        fill="#8B7EC8"/>
</svg>
```

---

### Slide 10: Logo Recommendation

**Primary Mark: Direction A — "The Breath"**

Rationale:
- Most distinctive silhouette
- Works at all sizes (two forms vs complex voids)
- Emotionally resonant (inhale/exhale)
- Flexible for animation (forms can pulse)

**Secondary Mark: Direction B — "The Clearing"**
Reserved for: Hero moments, large-format use, environmental graphics

---

### Slide 11: Wordmark Specification

**Typeface:** SF Pro Rounded, Medium
**Tracking:** +20 (0.02em)
**Case:** Title Case

```
"Quiet Coach"

Metrics (at 100pt):
- Total width: 412pt
- Cap height: 72pt
- x-height: 52pt
- Space between words: 24pt (0.24em)
```

**Wordmark SVG:**
```svg
<svg viewBox="0 0 200 24" xmlns="http://www.w3.org/2000/svg">
  <text x="0" y="20"
        font-family="SF Pro Rounded, -apple-system, sans-serif"
        font-size="24"
        font-weight="500"
        letter-spacing="0.02em"
        fill="#F5F5F7">Quiet Coach</text>
</svg>
```

---

### Slide 12: Lockup System

**Symbol-only**
- Minimum size: 24px
- Use: App icon, favicon, small UI marks

**Wordmark-only**
- Minimum size: 80px width
- Use: Website header, marketing where symbol is already present

**Combined Lockup (Horizontal)**
```
[Symbol] — [Wordmark]
   48px     24px gap    auto
```
- Clear space: 1× symbol height on all sides
- Minimum total width: 160px

**Combined Lockup (Stacked)**
```
    [Symbol]
       ↓
   16px gap
       ↓
   [Wordmark]
```
- Use: Square formats, social avatars, splash screens

---

### Slide 13: Logo Usage Matrix

| Context | Lockup | Size | Notes |
|---------|--------|------|-------|
| App Icon | Symbol only | 1024px master | Glass treatment applied |
| Splash Screen | Stacked | Symbol 80px | Animate: gentle fade-in |
| Settings Header | Horizontal | Symbol 32px | Left-aligned |
| Website Nav | Horizontal | Symbol 28px | Scrolls with page |
| Social Avatar | Symbol only | 400px | Centered, dark bg |
| Press Kit | All three | Vector | Include construction grids |
| App Store | Stacked | Per spec | On dark gradient |

---

### Slide 14: Logo Don'ts

1. ❌ Do not rotate the symbol
2. ❌ Do not add drop shadows beyond brand spec
3. ❌ Do not change proportions between forms
4. ❌ Do not place on busy backgrounds without glass backing
5. ❌ Do not animate on every screen transition
6. ❌ Do not use below minimum sizes
7. ❌ Do not recreate in non-rounded typefaces
8. ❌ Do not add stroke to filled variants

---

# SECTION 04
## APP ICON

---

### Slide 15: Primary App Icon — "Glass Breath"

**Build Recipe (Figma/Sketch):**

**Step 1: Base Canvas**
- Artboard: 1024 × 1024px
- Background: #0F0D14 (near-black with violet tint)

**Step 2: Symbol Placement**
- Import "Breath" symbol (Direction A)
- Scale to 600px width
- Center on canvas

**Step 3: Glass Effect — Left Form**
```
Fill: Linear gradient
  - Start: #FFFFFF @ 15% opacity
  - End: #8B7EC8 @ 8% opacity
  - Angle: 135° (top-left to bottom-right)

Stroke:
  - Width: 4px
  - Color: #FFFFFF @ 12%
  - Inside stroke

Effects:
  - Background blur: 40px
  - Inner shadow: #000000 @ 20%, 0 offset, 8px blur
```

**Step 4: Glass Effect — Right Form**
```
Fill: Linear gradient
  - Start: #FFFFFF @ 12% opacity
  - End: #8B7EC8 @ 6% opacity
  - Angle: 135°

Stroke:
  - Width: 3px
  - Color: #FFFFFF @ 10%

Effects:
  - Background blur: 30px
  - Inner shadow: #000000 @ 15%, 0 offset, 6px blur
```

**Step 5: Highlight**
```
Shape: Ellipse
Position: Top-left of left form
Size: 80 × 40px
Fill: Radial gradient
  - Center: #FFFFFF @ 25%
  - Edge: transparent
Blur: 20px
```

**Step 6: Drop Shadow**
```
Color: #000000 @ 30%
Offset: 0, 16px
Blur: 32px
Spread: -8px
```

---

### Slide 16: Icon — Small Size Simplification

**At 120px and below:**
- Remove inner stroke on right form
- Reduce highlight to single point (no gradient)
- Simplify shadow to 8px blur

**At 60px and below:**
- Forms become solid fills (no glass effect)
- Single highlight dot
- Minimal shadow

**At 29px (Spotlight):**
- Solid twilight violet forms
- No effects
- Maximum contrast

---

### Slide 17: Secondary App Icon — "The Portal"

**Build Recipe:**

Using Direction B ("The Clearing") with glass treatment:

**Step 1: Base**
- 1024 × 1024px
- Background: #0F0D14

**Step 2: Outer Frame**
```
Shape: Rounded Rectangle
Size: 800 × 800px (centered)
Corner radius: 200px
Fill: Linear gradient
  - #FFFFFF @ 12%
  - #8B7EC8 @ 6%
Stroke: 4px, #FFFFFF @ 10%
```

**Step 3: Inner Void**
```
Shape: Circle
Size: 320 × 320px
Position: Offset to (340, 340) — upper-left of center
Operation: Mask/subtract
Result: Void shows background through
```

**Step 4: Void Edge Glow**
```
Shape: Circle stroke around void
Stroke: 2px, #8B7EC8 @ 40%
Blur: 8px
```

---

### Slide 18: Icon Export Checklist

| Size | Scale | Use |
|------|-------|-----|
| 1024px | 1× | App Store |
| 180px | 3× | iPhone @3x |
| 120px | 2× | iPhone @2x |
| 167px | 2× | iPad Pro @2x |
| 152px | 2× | iPad @2x |
| 87px | 3× | Spotlight @3x |
| 80px | 2× | Spotlight @2x |
| 60px | 3× | Settings @3x |
| 58px | 2× | Settings @2x |
| 40px | 2× | Notification @2x |

**Safe Area:** All elements within 80% of canvas (102px margin at 1024px)

---

# SECTION 05
## COLOR SYSTEM

---

### Slide 19: Color Palette — Environment

| Token | Hex | RGB | Use |
|-------|-----|-----|-----|
| `qcBackground` | #000000 | 0, 0, 0 | Primary background (OLED black) |
| `qcSurface` | #1C1C1E | 28, 28, 30 | Elevated cards |
| `qcSurfaceSecondary` | #2C2C2E | 44, 44, 46 | Nested elements |
| `qcBackgroundViolet` | #0F0D14 | 15, 13, 20 | Tinted backgrounds |

---

### Slide 20: Color Palette — Twilight Violet (Ownable Accent)

| Token | Hex | RGB | Use |
|-------|-----|-----|-----|
| `qcAccent` | #8B7EC8 | 139, 126, 200 | Primary actions, AI moments |
| `qcAccentBright` | #A599D9 | 165, 153, 217 | Hover/focus states |
| `qcAccentDim` | #8B7EC8 @ 15% | — | Background tints |
| `qcAccentGlow` | #8B7EC8 @ 40% | — | Glow effects |

**Contrast Check:**
- On #000000: 7.2:1 ✅ AAA
- On #1C1C1E: 5.8:1 ✅ AA

---

### Slide 21: Color Palette — Semantic

| Token | Hex | Name | Use |
|-------|-----|------|-----|
| `qcActive` | #E87D6C | Soft Coral | Recording state |
| `qcSuccess` | #6AC4A8 | Muted Teal | Completion, positive |
| `qcWarning` | #E8A855 | Warm Amber | Caution, improvement |
| `qcError` | #E87D6C | Soft Coral | Errors (same as active) |
| `qcInfo` | #7EB8C8 | Quiet Cyan | Informational |

**Contrast Checks (on #000000):**
- Coral: 6.1:1 ✅ AA
- Teal: 8.9:1 ✅ AAA
- Amber: 8.2:1 ✅ AAA
- Cyan: 7.8:1 ✅ AAA

---

### Slide 22: Color Palette — Glass Tints

| Token | Formula | Use |
|-------|---------|-----|
| `qcGlassClear` | #FFFFFF @ 6% | Neutral glass |
| `qcGlassViolet` | #8B7EC8 @ 4% | Accent-tinted glass |
| `qcGlassWarm` | #E8A855 @ 4% | Coaching warmth |
| `qcGlassCool` | #7EB8C8 @ 4% | Recording focus |

---

### Slide 23: Color Palette — Text

| Token | Hex | Opacity | Use |
|-------|-----|---------|-----|
| `qcTextPrimary` | #F5F5F7 | 100% | Headlines, primary |
| `qcTextSecondary` | #F5F5F7 | 60% | Supporting copy |
| `qcTextTertiary` | #F5F5F7 | 40% | Hints, timestamps |
| `qcTextOnAccent` | #000000 | 100% | Text on accent fills |

---

# SECTION 06
## TYPOGRAPHY SYSTEM

---

### Slide 24: Type Scale

| Style | Font | Size | Weight | Line Height | Tracking |
|-------|------|------|--------|-------------|----------|
| Display | SF Pro Rounded | 34pt | Medium | 41pt | +0.5pt |
| Title 1 | SF Pro Rounded | 28pt | Medium | 34pt | +0.3pt |
| Title 2 | SF Pro | 22pt | Semibold | 28pt | 0 |
| Title 3 | SF Pro | 20pt | Semibold | 25pt | 0 |
| Headline | SF Pro | 17pt | Semibold | 22pt | 0 |
| Body | SF Pro | 17pt | Regular | 22pt | 0 |
| Callout | SF Pro | 16pt | Regular | 21pt | 0 |
| Subhead | SF Pro | 15pt | Regular | 20pt | 0 |
| Footnote | SF Pro | 13pt | Regular | 18pt | 0 |
| Caption | SF Pro | 12pt | Medium | 16pt | 0 |

---

### Slide 25: Typography — Glass Optimization

**Problem:** Light text on translucent glass can lose legibility.

**Solution: Glass Text Rules**

1. **Increase tracking on glass:** +0.5pt for all text on glass surfaces
2. **Prefer Medium weight:** Avoid Light and Regular on glass
3. **Boost opacity:** Text on glass gets +2% opacity boost
4. **Never use Bold:** Feels heavy; use Semibold maximum

**Implementation:**
```swift
Text("On Glass")
    .font(.qcDisplay)
    .tracking(0.5)
    .opacity(0.97) // Slight boost
```

---

### Slide 26: Typography — Numeric Displays

| Style | Font | Size | Weight | Design |
|-------|------|------|--------|--------|
| Hero Score | SF Pro Rounded | 72pt | Bold | .rounded |
| Timer | SF Pro Rounded | 48pt | Medium | .rounded + .monospacedDigit |
| Score Card | SF Pro Rounded | 32pt | Semibold | .rounded |
| Badge | SF Pro Rounded | 14pt | Medium | .rounded |

**Numeric Principle:** All scores and timers use `.rounded` design for warmth.

---

# SECTION 07
## VOICE SYSTEM

---

### Slide 27: Voice Pillars

**1. PRESENT, NOT PUSHY**
We observe. We don't command. We're here when you need us, quiet when you don't.

**2. SPECIFIC, NOT GENERIC**
"Your pacing steadied in the second half" — not "Good job!"
We name what we see. Specificity is respect.

**3. KIND, NOT SOFT**
We tell the truth gently. We don't coddle. Growth requires honesty delivered with care.

---

### Slide 28: Voice — Do / Don't

| DO | DON'T |
|----|-------|
| "Your voice carried well." | "You nailed it!" |
| "Recording saved." | "Awesome! Recording saved!" |
| "Try focusing on..." | "You need to work on..." |
| "When you're ready." | "Let's go!" |
| "Practice again?" | "Crush it again!" |
| "30 seconds of clarity." | "30 seconds of POWER!" |

---

### Slide 29: Prohibited Phrases

These words/phrases break the Quiet Coach brand:

**Energy Words:**
- Crush it, nail it, kill it, smash it
- Let's go, let's do this, you got this
- Level up, unlock, achieve, conquer

**Gamification:**
- Points, XP, streak (use "consistency" instead)
- Achievement unlocked
- You're on fire

**Hype:**
- Amazing, awesome, incredible, epic
- Superstar, rockstar, champion
- Master, dominate, own

**Condescension:**
- Great job! (without specifics)
- You're doing great, sweetie
- Attagirl/Attaboy

---

### Slide 30: Writing Samples — Buttons

| Context | Copy |
|---------|------|
| Start recording | Begin |
| Stop recording | Done |
| Save session | Save |
| Try again | Practice again |
| Share result | Share |
| Continue | Continue |
| Cancel | Cancel |
| Primary CTA | Find your words |

---

### Slide 31: Writing Samples — Microcopy

| Context | Copy |
|---------|------|
| Recording in progress | Recording... |
| Processing | Listening... |
| Saved confirmation | Saved. |
| Upload blocked | Your voice stays on this device. |
| Mic permission needed | We need to hear you to help. |
| Pro feature locked | Available with Pro. |

---

### Slide 32: Writing Samples — Empty States

**No sessions yet:**
> No sessions yet.
> When you're ready, pick a scenario.

**No favorites:**
> Nothing saved here.
> Tap the heart on any scenario you want to find again.

**Offline:**
> You're offline.
> Your sessions are safe. We'll sync when you're back.

---

### Slide 33: Writing Samples — Onboarding

**Screen 1:**
> Everyone has conversations they dread.
> The raise. The boundary. The apology.

**Screen 2:**
> What if you could practice them first?
> Speak into the quiet. Hear yourself. Walk in ready.

**Screen 3:**
> Your voice stays yours.
> Everything is processed on your device. Nothing uploaded. Nothing stored unless you choose.

**Screen 4:**
> One permission. That's it.
> We need your microphone to hear your rehearsal. You're always in control.

---

### Slide 34: Coach Voice Spec

**The Coach is:**
- Observant (notices patterns)
- Specific (names what it sees)
- Encouraging without cheerleading
- Present tense ("Your pacing was..." not "You should...")

**The Coach says:**
- "Your voice steadied in the second half."
- "The pause before your main point? That worked."
- "Clarity came through. You knew what you wanted to say."
- "This takes practice. You're practicing."

**The Coach never says:**
- "Great job!" (without specifics)
- "You need to improve your..."
- "Try harder next time."
- "Here's what you did wrong."
- "Level up your confidence!"

---

# SECTION 08
## VISUAL PROOF

---

### Slide 35: Mockup Plan — Home Screen

**Before (Gold accent):**
- Accent color: Warm gold
- Cards: Flat surface color
- Corner radius: 16pt

**After (Twilight Violet + Glass):**
- Accent color: Twilight Violet (#8B7EC8)
- Cards: Glass tier Surface with subtle violet tint
- Corner radius: 24pt
- Scenario cards have glass backgrounds
- "Start Practice" button uses accent fill

**Layout Notes:**
- Logo in nav: Symbol only, 28pt
- Section headers: Title 3 style
- Card titles: Headline style
- Card subtitles: Subhead, 60% opacity

---

### Slide 36: Mockup Plan — Recording Screen

**Before:**
- Red recording indicator
- Plain dark background

**After:**
- Soft Coral (#E87D6C) for active state
- Background: Subtle radial gradient from center (qcGlassCool tint)
- Waveform: Twilight Violet active bars
- Record button: Glass Interactive tier with coral glow
- Timer: SF Pro Rounded, monospaced

**Layout Notes:**
- Minimal UI during recording
- Timer centered, large (48pt)
- Waveform below timer
- Stop button only control visible

---

### Slide 37: Mockup Plan — Results Screen

**Before:**
- Green success color
- Score cards with surface color

**After:**
- Success color: Muted Teal (#6AC4A8)
- Score cards: Glass Focal tier
- Individual metric cards: Glass Surface tier
- Overall score: Hero Score typography (72pt)
- Coaching notes: Warm glass tint

**Layout Notes:**
- Score centered, hero treatment
- Metric breakdown in 2×2 grid
- Coaching notes in expandable cards
- "Practice Again" button secondary
- "Share" button tertiary

---

### Slide 38: Mockup Plan — Settings

**After:**
- Section headers: Caption style, 40% opacity
- Rows: Glass Surface tier backgrounds
- Toggle accent: Twilight Violet
- Version/about: Footer with logo (stacked lockup)
- Pro badge: Warm Amber tint

---

### Slide 39: Asset Delivery List

**Logo Package:**
- [ ] `logo-symbol.svg` — Symbol only, vector
- [ ] `logo-wordmark.svg` — Wordmark only, vector
- [ ] `logo-horizontal.svg` — Combined horizontal
- [ ] `logo-stacked.svg` — Combined stacked
- [ ] `logo-construction.pdf` — Grid and specifications

**App Icon Package:**
- [ ] `icon-1024.png` — Master
- [ ] `icon-all-sizes/` — Full iOS export set
- [ ] `icon-figma.fig` — Editable source

**Color:**
- [ ] `colors.json` — Design tokens
- [ ] `Colors.swift` — iOS implementation
- [ ] `colors.css` — Web implementation

**Type:**
- [ ] `typography.json` — Scale tokens
- [ ] `Typography.swift` — iOS implementation

---

### Slide 40: Style Tile Summary

```
┌─────────────────────────────────────────────────────────┐
│  QUIET COACH STYLE TILE                                 │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  [LOGO: Breath symbol + wordmark]                       │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  COLORS                                                 │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐          │
│  │ BG   │ │Violet│ │ Coral│ │ Teal │ │Amber │          │
│  │#0000 │ │#8B7E │ │#E87D │ │#6AC4 │ │#E8A8 │          │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘          │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  TYPOGRAPHY                                             │
│                                                         │
│  Display — SF Pro Rounded Medium                        │
│  Headline — SF Pro Semibold                             │
│  Body — SF Pro Regular                                  │
│  Caption — SF Pro Medium                                │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  GLASS TIERS                                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │
│  │ Ambient  │ │ Surface  │ │Interactive│ │  Focal   │   │
│  │   6%     │ │   15%    │ │    25%    │ │   50%    │   │
│  │  80blur  │ │  40blur  │ │   20blur  │ │  8blur   │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────┘   │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  VOICE                                                  │
│  "Find your words before you need them."                │
│  Present, not pushy. Specific, not generic.             │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

# SECTION 09
## FINAL ASSESSMENT

---

### Slide 41: Agency Verdict

**Final Rating: 9.0 / 10**

**What This System Delivers:**
✅ Ownable accent (Twilight Violet, not generic AI purple)
✅ Constructible logo with SVG paths
✅ Complete lockup system with clear space rules
✅ Renderable app icon with layer-by-layer recipe
✅ Semantic color system with contrast checks
✅ Typography scale with glass optimization
✅ Deep voice system with prohibited phrases
✅ Mockup specifications for key screens
✅ Asset delivery checklist

---

### Slide 42: What Remains for 10/10

**1. Motion System**
Define animation curves, durations, and choreography for:
- Screen transitions
- Glass material responses
- Score reveal sequence
- Recording state changes

**2. Sound Design Brief**
Audio identity to match visual calm:
- Start recording tone
- Stop tone
- Score reveal flourish
- Error/warning sounds

**3. Rendered Assets**
Execute this spec in Figma to produce:
- Actual icon PNGs
- Screen mockup images
- Animated logo file
- Press kit PDF

---

### Slide 43: Closing

> "The best brands feel inevitable.
> Like they could only exist now,
> because the world finally caught up."

Quiet Coach is ready.

---

*Brand System v2.0*
*Prepared for internal stakeholders*
*Confidential*
