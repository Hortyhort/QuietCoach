# QuietCoach CI/CD Documentation

## Overview

QuietCoach uses GitHub Actions for continuous integration and Fastlane for build automation and deployment.

## Pipeline Structure

```
Push/PR to main
       │
       ▼
┌──────────────┐     ┌──────────────┐
│   Build &    │     │    Lint      │
│    Test      │     │  (parallel)  │
└──────┬───────┘     └──────────────┘
       │
       ▼ (main only)
┌──────────────┐
│   Release    │
│    Build     │
└──────┬───────┘
       │
       ▼ (if secrets configured)
┌──────────────┐
│  Deploy to   │
│  TestFlight  │
└──────────────┘
```

## Local Development

### Prerequisites

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Ruby (via rbenv recommended)
brew install rbenv
rbenv install 3.2.0
rbenv global 3.2.0

# Install Bundler
gem install bundler
```

### Setup

```bash
# Install dependencies
bundle install

# Run tests locally
bundle exec fastlane test

# Build the app
bundle exec fastlane build
```

## Fastlane Lanes

| Lane | Description |
|------|-------------|
| `test` | Run all unit tests with code coverage |
| `coverage` | Run tests and generate coverage report |
| `build` | Build the app (no signing) |
| `archive` | Build and archive for distribution |
| `beta` | Deploy to TestFlight |
| `release` | Deploy to App Store |
| `bump` | Increment build number |
| `version` | Increment version number |
| `certificates` | Sync code signing certificates |

### Examples

```bash
# Run tests
bundle exec fastlane test

# Deploy to TestFlight
bundle exec fastlane beta

# Bump patch version (1.0.0 -> 1.0.1)
bundle exec fastlane version type:patch

# Bump minor version (1.0.0 -> 1.1.0)
bundle exec fastlane version type:minor

# Bump major version (1.0.0 -> 2.0.0)
bundle exec fastlane version type:major
```

## GitHub Actions

### Workflow Triggers

- **Push to main**: Runs tests, builds, and deploys to TestFlight
- **Pull Request**: Runs tests and linting only

### Required Secrets

To enable TestFlight deployment, configure these secrets in GitHub:

| Secret | Description |
|--------|-------------|
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API Key ID |
| `APP_STORE_CONNECT_API_ISSUER_ID` | App Store Connect Issuer ID |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | API Key content (base64 encoded) |
| `MATCH_PASSWORD` | Password for match certificates repo |
| `MATCH_GIT_URL` | Git URL for match certificates repo |

### Setting Up App Store Connect API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com/access/api)
2. Click "Keys" → "Generate API Key"
3. Download the `.p8` file
4. Note the Key ID and Issuer ID
5. Base64 encode the key: `base64 -i AuthKey_XXXXXX.p8`
6. Add to GitHub Secrets

### Setting Up Match (Code Signing)

1. Create a private git repository for certificates
2. Run `bundle exec fastlane match init`
3. Configure `fastlane/Matchfile`:
   ```ruby
   git_url("git@github.com:your-org/certificates.git")
   storage_mode("git")
   type("appstore")
   app_identifier(["com.quietcoach.app"])
   ```
4. Generate certificates: `bundle exec fastlane match appstore`

## Environment Configuration

Create a `.env` file for local development (not committed):

```bash
# .env
APPLE_ID=your-apple-id@example.com
TEAM_ID=XXXXXXXXXX
APP_STORE_CONNECT_API_KEY_ID=XXXXXXXXXX
APP_STORE_CONNECT_API_ISSUER_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

## Troubleshooting

### Tests Fail on CI

1. Check simulator availability: `xcrun simctl list devices`
2. Ensure Xcode version matches CI
3. Check test logs in GitHub Actions artifacts

### Code Signing Issues

1. Verify certificates in Keychain Access
2. Run `bundle exec fastlane match nuke development` to reset
3. Re-run `bundle exec fastlane certificates`

### Build Failures

1. Clean build folder: `rm -rf ~/Library/Developer/Xcode/DerivedData`
2. Check for SwiftUI preview crashes
3. Verify all assets are included

## Version Management

Build numbers are auto-incremented on TestFlight deployment.

Version numbers follow semantic versioning:
- **Major** (X.0.0): Breaking changes
- **Minor** (0.X.0): New features
- **Patch** (0.0.X): Bug fixes

## Support

For CI/CD issues, check:
- GitHub Actions logs
- Fastlane output (`fastlane/logs/`)
- Test results (`fastlane/test_output/`)
