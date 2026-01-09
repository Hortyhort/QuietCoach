# Quiet Coach App Icon Design Specification

## Design Concept

A minimal, confident icon that conveys calm communication practice.

### Visual Elements

**Background:**
- Color: Deep charcoal `#1C1C1E` (matches app background)
- Solid fill, no gradients

**Foreground:**
- Abstract waveform forming a subtle "Q" shape
- The waveform should suggest voice/audio without being literal
- Gradient from white `#FFFFFF` to light gray `#E5E5EA`
- Clean, geometric lines

**Style Guidelines:**
- Minimal and geometric
- No text or letters
- No complex illustrations
- Works well at small sizes (home screen)
- Recognizable at a glance

### Visual Reference

```
┌─────────────────────────┐
│                         │
│      ╭─╮  ╭─╮  ╭─╮      │
│     ╱   ╲╱   ╲╱   ╲     │
│    │         ╰─────╮    │
│    │               │    │
│     ╲             ╱     │
│      ╰───────────╯      │
│                         │
└─────────────────────────┘

(Waveform bars curve to suggest "Q" letterform)
```

## Required Sizes

### iOS App Icon (Single Asset)
Since iOS 17+, only one 1024x1024 image is needed. The system automatically generates all other sizes.

| Size | Usage |
|------|-------|
| 1024x1024 | App Store, universal |

### Export Settings
- Format: PNG
- Color Space: sRGB
- No transparency (solid background)
- No rounded corners (system applies them)

## File Location

Place the 1024x1024 PNG at:
```
QuietCoach/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```

And update Contents.json:
```json
{
  "images" : [
    {
      "filename" : "AppIcon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

## Brand Colors Reference

| Color | Hex | Usage |
|-------|-----|-------|
| Background | `#1C1C1E` | Icon background |
| Accent Gold | `#FAD178` | App accent (not in icon) |
| Text Primary | `#FFFFFF` | Waveform highlight |
| Text Secondary | `#E5E5EA` | Waveform gradient |

---

# App Store Screenshots Specification

## Device Frames

- **Device:** iPhone 15 Pro
- **Color:** Black Titanium
- **Mode:** Dark mode always

## Screenshot Dimensions

| Device | Size |
|--------|------|
| iPhone 6.7" | 1290 x 2796 px |
| iPhone 6.5" | 1284 x 2778 px |
| iPhone 5.5" | 1242 x 2208 px |
| iPad 12.9" | 2048 x 2732 px |

## Screenshot Sequence

### Screenshot 1: Hero - Recording
**Scene:** RehearseView with active waveform
**Text Overlay:** "Practice the hard conversations."
**Details:**
- Timer showing ~00:45
- Waveform animating (capture mid-animation)
- Scenario title visible at top
- Recording state (stop button visible)

### Screenshot 2: Review Scores
**Scene:** ReviewView with scores visible
**Text Overlay:** "Instant feedback."
**Details:**
- All four scores visible (Clarity, Pacing, Tone, Confidence)
- Overall score badge prominent
- Scenario icon at top

### Screenshot 3: Coaching Notes
**Scene:** ReviewView scrolled to coach notes
**Text Overlay:** "Actionable coaching."
**Details:**
- 2-3 coach notes visible
- Try Again Focus card visible
- Clear, readable text

### Screenshot 4: Share Card
**Scene:** ShareCardSheet with preview
**Text Overlay:** "Share your progress."
**Details:**
- Share card preview centered
- Share button visible
- Clean background

### Screenshot 5: Scenarios
**Scene:** HomeView with scenario grid
**Text Overlay:** "6 scenarios. Countless rehearsals."
**Details:**
- All 6 free scenario cards visible
- Clear iconography
- Settings gear visible

### Screenshot 6: Privacy
**Scene:** SettingsView with privacy section
**Text Overlay:** "Your voice never leaves your device."
**Details:**
- Privacy text section visible
- Lock icon or similar privacy indicator
- Clean list UI

## Text Overlay Style

- **Font:** SF Pro Display Bold
- **Size:** 72pt
- **Color:** White `#FFFFFF`
- **Position:** Top third of screen
- **Shadow:** Subtle black drop shadow for legibility

## Capture Tips

1. Use Xcode Simulator at 1x scale
2. Use `xcrun simctl io booted screenshot` for clean captures
3. Add text overlays in Figma or similar
4. Maintain consistent spacing and alignment

---

# Launch Screen

The launch screen uses a solid color background configured in Info.plist.

**Color:** Pure black `#000000`
**Asset Name:** `LaunchBackground`

This creates a seamless transition into the dark-themed app.
