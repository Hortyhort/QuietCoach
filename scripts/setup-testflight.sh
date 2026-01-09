#!/bin/bash
# QuietCoach TestFlight Setup Script
# Run this script to prepare for TestFlight deployment

set -e

echo "═══════════════════════════════════════════════════════════"
echo "  QuietCoach TestFlight Setup"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check for Ruby
if ! command -v ruby &> /dev/null; then
    echo "❌ Ruby not found. Please install Ruby first:"
    echo "   brew install rbenv"
    echo "   rbenv install 3.2.0"
    exit 1
fi

echo "✓ Ruby $(ruby -v | cut -d' ' -f2) found"

# Check for Bundler
if ! command -v bundle &> /dev/null; then
    echo "Installing Bundler..."
    gem install bundler
fi

echo "✓ Bundler found"

# Install dependencies
echo ""
echo "Installing Fastlane dependencies..."
bundle install

echo ""
echo "✓ Dependencies installed"

# Check Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install Xcode from the App Store."
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -n 1)
echo "✓ $XCODE_VERSION found"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Configuration Required"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Before deploying to TestFlight, you need to:"
echo ""
echo "1. Create an App Store Connect API Key:"
echo "   → https://appstoreconnect.apple.com/access/api"
echo "   → Click 'Keys' → 'Generate API Key'"
echo "   → Download the .p8 file"
echo ""
echo "2. Create a .env file in the project root:"
echo ""
echo "   cat > .env << EOF"
echo "   APPLE_ID=your-apple-id@example.com"
echo "   TEAM_ID=XXXXXXXXXX"
echo "   APP_STORE_CONNECT_API_KEY_ID=XXXXXXXXXX"
echo "   APP_STORE_CONNECT_API_ISSUER_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
echo "   APP_STORE_CONNECT_API_KEY_CONTENT=\$(base64 -i AuthKey_XXXXX.p8)"
echo "   EOF"
echo ""
echo "3. Update fastlane/Appfile with your team ID"
echo ""
echo "4. Set up code signing (one of these methods):"
echo "   a) Manual: Configure in Xcode project settings"
echo "   b) Match: bundle exec fastlane match init"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Available Commands"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "  bundle exec fastlane test     # Run tests"
echo "  bundle exec fastlane build    # Build (no signing)"
echo "  bundle exec fastlane beta     # Deploy to TestFlight"
echo "  bundle exec fastlane release  # Deploy to App Store"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "═══════════════════════════════════════════════════════════"
