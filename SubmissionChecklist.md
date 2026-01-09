# App Store Submission Checklist

Step-by-step guide to submitting Quiet Coach to the App Store.

---

## Pre-Submission

### Code Preparation

- [ ] Remove all `#if DEBUG` code blocks or ensure they're inactive in Release
- [ ] Remove any TODO comments referencing incomplete features
- [ ] Verify no placeholder text in UI
- [ ] Test on physical device (not just simulator)
- [ ] Test with airplane mode (app should work offline)
- [ ] Test microphone permission flow (grant and deny)
- [ ] Verify haptics work on physical device

### Build Configuration

- [ ] Set version number in project: `MARKETING_VERSION = 1.0.0`
- [ ] Set build number in project: `CURRENT_PROJECT_VERSION = 1`
- [ ] Verify Bundle ID: `com.quietcoach.app`
- [ ] Verify deployment target: iOS 17.0+
- [ ] Archive in Release configuration

### Assets

- [ ] App icon added (1024×1024 PNG)
- [ ] All screenshot sizes ready
- [ ] App preview video ready (optional)

---

## App Store Connect Setup

### 1. Create App Record

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in:
   - Platform: iOS
   - Name: `Quiet Coach`
   - Primary Language: English (U.S.)
   - Bundle ID: `com.quietcoach.app`
   - SKU: `QUIETCOACH001`
   - User Access: Full Access

### 2. App Information

Navigate to **App Store** → **App Information**

- [ ] Name: `Quiet Coach`
- [ ] Subtitle: `Rehearse Hard Conversations`
- [ ] Category: Productivity
- [ ] Secondary Category: Health & Fitness
- [ ] Content Rights: Does not contain third-party content
- [ ] Age Rating: Complete questionnaire (all "No")

### 3. Pricing and Availability

Navigate to **App Store** → **Pricing and Availability**

- [ ] Price: Free
- [ ] Availability: All territories
- [ ] Pre-Order: No

### 4. App Privacy

Navigate to **App Store** → **App Privacy**

- [ ] Start questionnaire
- [ ] Data Collection: **No, we do not collect data**
- [ ] Complete and publish

### 5. In-App Purchases (If Ready)

Navigate to **Features** → **In-App Purchases**

Create subscription group:
- [ ] Reference Name: `Quiet Coach Pro`
- [ ] Subscription Group ID: `quietcoach_pro`

Create subscriptions:
- [ ] Monthly: $19.99/month
- [ ] Yearly: $99.99/year

---

## Version Submission

### 1. Upload Build

**Option A: Xcode**
1. Product → Archive
2. Distribute App → App Store Connect → Upload
3. Wait for processing (10-30 minutes)

**Option B: Transporter**
1. Export .ipa from Xcode
2. Open Transporter app
3. Drag .ipa and upload

### 2. Select Build

1. Go to **App Store** → **iOS App** → **Build**
2. Click **+** and select uploaded build
3. Wait for build to process (may take 1-24 hours)

### 3. Version Information

Fill in all fields:

**Screenshots:**
- [ ] 6.7" Display (iPhone 15 Pro Max) — 6 screenshots
- [ ] 6.5" Display (iPhone 11 Pro Max) — 6 screenshots
- [ ] 5.5" Display (iPhone 8 Plus) — 6 screenshots
- [ ] 12.9" iPad Pro — 6 screenshots

**App Preview (Optional):**
- [ ] 15-30 second video showing core flow

**Description:**
- [ ] Promotional Text (copy from AppStoreMetadata.md)
- [ ] Description (copy from AppStoreMetadata.md)
- [ ] Keywords (copy from AppStoreMetadata.md)
- [ ] What's New (copy from AppStoreMetadata.md)

**URLs:**
- [ ] Support URL: `https://quietcoach.app/support`
- [ ] Marketing URL: `https://quietcoach.app`

**Contact:**
- [ ] First Name
- [ ] Last Name
- [ ] Email
- [ ] Phone

### 4. App Review Information

**Contact Information:**
- [ ] First Name
- [ ] Last Name
- [ ] Phone
- [ ] Email

**Demo Account:** Not required (no login)

**Notes:**
```
Quiet Coach is a rehearsal app for practicing difficult conversations.

TO TEST THE APP:
1. Launch the app
2. Complete the brief onboarding (allow microphone access)
3. Select any scenario from the home screen
4. Tap the record button and speak for 10+ seconds
5. Tap stop to see your feedback scores
6. View coaching notes and try again

MICROPHONE ACCESS:
The app requires microphone access to record rehearsals. All audio is processed entirely on-device and is never uploaded.

NO ACCOUNT REQUIRED:
The app works fully offline without any account creation.
```

### 5. Export Compliance

- [ ] Does your app use encryption? **No**
  - The app does not use custom encryption
  - HTTPS is exempt from export compliance

### 6. Content Rights

- [ ] Does your app contain third-party content? **No**

### 7. Advertising Identifier

- [ ] Does this app use the IDFA? **No**

---

## Final Review

### Before Submitting

- [ ] All metadata complete
- [ ] Screenshots uploaded for all device sizes
- [ ] Build selected and processed
- [ ] App Privacy published
- [ ] Review Notes complete
- [ ] Test URL links (support, marketing, privacy)

### Submit for Review

1. Click **Submit for Review**
2. Confirm all declarations
3. Submit

---

## Post-Submission

### Timeline

- **Processing:** 24-48 hours (usually faster)
- **Review:** 24-48 hours (can be longer)
- **Total:** 1-7 days typical

### If Rejected

1. Read rejection reason carefully
2. Fix issues in code if needed
3. Upload new build
4. Reply to App Review in Resolution Center
5. Resubmit

### Common Rejection Reasons

| Reason | Solution |
|--------|----------|
| Crashes | Test more thoroughly, fix crashes |
| Incomplete metadata | Fill all required fields |
| Placeholder content | Remove placeholder text |
| Privacy issues | Update privacy policy |
| Guideline 4.2 (minimum functionality) | Add more features or justify value |

### After Approval

- [ ] Set release date (manual or automatic)
- [ ] Release to App Store
- [ ] Monitor crash reports
- [ ] Respond to reviews

---

## Quick Reference

### Version Numbers

| Version | Build | Notes |
|---------|-------|-------|
| 1.0.0 | 1 | Initial release |
| 1.0.1 | 2 | Bug fixes |
| 1.1.0 | 3 | New features |

### Important URLs

| Purpose | URL |
|---------|-----|
| App Store Connect | appstoreconnect.apple.com |
| Privacy Policy | quietcoach.app/privacy |
| Support | quietcoach.app/support |
| Marketing | quietcoach.app |

### Key Dates

| Milestone | Date |
|-----------|------|
| Development Complete | ___ |
| Build Uploaded | ___ |
| Submitted for Review | ___ |
| Approved | ___ |
| Released | ___ |

---

*Good luck with the submission!*
