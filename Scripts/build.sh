#!/bin/bash

# PermissionPilot Build Script
# Usage: ./build.sh [debug|release]

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"
CONFIGURATION="${1:-debug}"

echo "🏗️  Building PermissionPilot ($CONFIGURATION)..."

# Create build directory
mkdir -p "$BUILD_DIR"

# Clean previous builds
if [ "$CONFIGURATION" = "release" ]; then
    echo "🧹 Cleaning previous builds..."
    rm -rf "$BUILD_DIR"/*
fi

# Build with Xcode
DERIVED_DATA="$BUILD_DIR/DerivedData"
ARCHIVE_PATH="$BUILD_DIR/PermissionPilot.xcarchive"

echo "📦 Building archive..."
xcodebuild \
    -project "$PROJECT_ROOT/Xcode/PermissionPilot.xcodeproj" \
    -scheme PermissionPilot \
    -configuration "$([ "$CONFIGURATION" = "release" ] && echo "Release" || echo "Debug")" \
    -derivedDataPath "$DERIVED_DATA" \
    -archivePath "$ARCHIVE_PATH" \
    archive

echo "✅ Build completed successfully!"
echo "📍 Archive path: $ARCHIVE_PATH"

# Code signing (for release)
if [ "$CONFIGURATION" = "release" ]; then
    echo ""
    echo "⚠️  For release distribution, you must:"
    echo "  1. Sign with your Apple Developer ID: ./sign-and-notarize.sh"
    echo "  2. Create a DMG: ./create-dmg.sh"
fi
