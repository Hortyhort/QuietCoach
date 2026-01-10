# App Clip Setup Guide

This folder contains the source files for the QuietCoach App Clip.
Follow these steps to add the App Clip target to the Xcode project.

## Prerequisites

- Xcode 15.0+
- Apple Developer account with App Clip capabilities

## Setup Steps

### 1. Add App Clip Target in Xcode

1. Open `QuietCoach.xcodeproj` in Xcode
2. File → New → Target
3. Select "App Clip" under iOS
4. Configure:
   - Product Name: `QuietCoachClip`
   - Bundle Identifier: `com.quietcoach.Clip`
   - Embed in Application: QuietCoach

### 2. Configure Source Files

1. Delete the auto-generated files in the new target
2. Add the files from this folder to the QuietCoachClip target:
   - `QuietCoachClipApp.swift`
   - `ClipExperienceView.swift`
   - `Info.plist`
   - `Assets.xcassets`
   - `QuietCoachClip.entitlements`

### 3. Configure Signing & Capabilities

1. Select QuietCoachClip target
2. Signing & Capabilities tab
3. Add "Associated Domains" capability
4. Add domain: `appclips:quietcoach.app`

### 4. Configure App Clip Experience

In App Store Connect:

1. Go to your app → App Clip section
2. Add App Clip Experience
3. Configure:
   - URL: `https://quietcoach.app/practice`
   - Header Image: Upload a 3000x2000 image
   - Subtitle: "Practice difficult conversations"
   - Call to Action: "Open"

### 5. Configure Associated Domains

Add to your website (`quietcoach.app/.well-known/apple-app-site-association`):

```json
{
  "appclips": {
    "apps": ["TEAMID.com.quietcoach.Clip"]
  }
}
```

### 6. Test App Clip

1. In Xcode, edit QuietCoachClip scheme
2. Set Environment Variable: `_XCAppClipURL` = `https://quietcoach.app/practice`
3. Run on device to test invocation

## App Clip Card

The App Clip card shows when users scan the QR code or NFC tag:

- **Header**: Quiet Coach icon
- **Title**: Practice Conversations
- **Subtitle**: Rehearse difficult talks privately
- **Action**: OPEN

## Size Limit

App Clips must be under 15MB. The current implementation uses:
- SwiftUI only (no UIKit)
- No external dependencies
- Minimal assets
- System fonts only

Estimated size: ~2MB
