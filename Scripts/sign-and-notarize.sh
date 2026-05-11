#!/bin/bash

# Code Signing & Notarization Script for macOS
# Requires: Apple Developer ID certificate in Keychain
# Usage: ./sign-and-notarize.sh <archive-path> <apple-id> <app-password>

set -euo pipefail

ARCHIVE_PATH="${1:-build/PermissionPilot.xcarchive}"
APPLE_ID="${2:?Apple ID required}"
APP_PASSWORD="${3:?App-specific password required}"
TEAM_ID="${4:?Team ID required}"

echo "🔐 Code Signing & Notarization Pipeline"
echo "========================================"

if [ ! -f "$ARCHIVE_PATH" ]; then
    echo "❌ Archive not found: $ARCHIVE_PATH"
    exit 1
fi

EXPORT_PATH="$(dirname "$ARCHIVE_PATH")/Export"
APP_PATH="$EXPORT_PATH/PermissionPilot.app"
DMG_PATH="$(dirname "$ARCHIVE_PATH")/PermissionPilot.dmg"

# Step 1: Extract app from archive
echo ""
echo "📦 Extracting app from archive..."
mkdir -p "$EXPORT_PATH"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist Configuration/ExportOptions.plist \
    -exportPath "$EXPORT_PATH" \
    -allowProvisioningUpdates

# Step 2: Verify code signature
echo ""
echo "✅ Verifying code signature..."
codesign -dvvv "$APP_PATH" || {
    echo "❌ Code signature verification failed"
    exit 1
}

# Step 3: Create zip for notarization
echo ""
echo "📝 Creating zip for notarization..."
ZIP_PATH="$(dirname "$ARCHIVE_PATH")/PermissionPilot.zip"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

# Step 4: Submit for notarization
echo ""
echo "🔍 Submitting for Apple notarization..."
NOTARIZE_OUTPUT=$(xcrun notarytool submit "$ZIP_PATH" \
    --apple-id "$APPLE_ID" \
    --password "$APP_PASSWORD" \
    --team-id "$TEAM_ID" \
    --wait 2>&1) || {
    echo "❌ Notarization submission failed"
    echo "$NOTARIZE_OUTPUT"
    exit 1
}

REQUEST_ID=$(echo "$NOTARIZE_OUTPUT" | grep -i "id:" | awk '{print $NF}')
echo "✅ Notarization submitted. Request ID: $REQUEST_ID"

# Step 5: Staple the notary ticket
echo ""
echo "📎 Stapling notary ticket to app..."
xcrun stapler staple "$APP_PATH" || {
    echo "⚠️  Stapling failed (app is still notarized, just not stapled locally)"
}

# Step 6: Create DMG
echo ""
echo "💿 Creating DMG..."
hdiutil create -volname "PermissionPilot" \
    -srcfolder "$EXPORT_PATH" \
    -ov -format UDZO "$DMG_PATH"

# Step 7: Verify final product
echo ""
echo "🔐 Final verification..."
spctl -a -v -t install "$DMG_PATH" || {
    echo "⚠️  DMG gatekeeper check failed"
}

echo ""
echo "✅ Notarization Complete!"
echo "📍 Final DMG: $DMG_PATH"
echo "📊 Notarization ID: $REQUEST_ID"
