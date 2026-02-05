#!/bin/bash

# SayIt Packaging Script
# This script builds the application in Release mode and creates a DMG for distribution.

set -e

PROJECT_NAME="SayIt"
SCHEME_NAME="SayIt"
BUILD_DIR="./build"
RELEASE_DIR="${BUILD_DIR}/Release"
DMG_NAME="${PROJECT_NAME}_v1.0.0.dmg"

echo "🚀 Starting productization build..."

# 1. Clean previous builds first to avoid permission issues in DerivedData
echo "🧹 Removing previous build artifacts..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# 0. Deep clean extended attributes (fixes "detritus" errors)
echo "🧹 Cleaning extended attributes..."
xattr -rc . 2>/dev/null || true
dot_clean . 2>/dev/null || true

# build settings
CODE_SIGN_ENTITLEMENTS="${PROJECT_NAME}/${PROJECT_NAME}.entitlements"
CODESIGN_IDENTITY="Developer ID Application: Zhuo Niu (V7Z2QYFJWN)"

echo "🏗 Building ${PROJECT_NAME} for Release..."
# We disable code signing during xcodebuild to avoid "detritus" errors
# and handle it manually in the next step.
xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_NAME}" \
    -configuration Release \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    SYMROOT="$(pwd)/${BUILD_DIR}" \
    CODE_SIGNING_ALLOWED=NO \
    build

# 2.5 Code Sign the app bundle
if [ -n "${CODESIGN_IDENTITY}" ]; then
    echo "🧹 Final detritus cleanup on built app..."
    xattr -rc "${RELEASE_DIR}/${PROJECT_NAME}.app"
    
    echo "🔑 Signing app with identity: ${CODESIGN_IDENTITY}"
    # Use --options runtime for Hardened Runtime (required for notarization)
    codesign --force --options runtime --deep --sign "${CODESIGN_IDENTITY}" \
        --entitlements "${CODE_SIGN_ENTITLEMENTS}" \
        "${RELEASE_DIR}/${PROJECT_NAME}.app"
fi

# 3. Create Premium DMG
echo "📦 Creating Premium DMG package..."
DMG_TEMP_DIR="${BUILD_DIR}/dmg_temp"
rm -rf "${DMG_TEMP_DIR}"
mkdir -p "${DMG_TEMP_DIR}"

# Copy App to temp dir
cp -R "${RELEASE_DIR}/${PROJECT_NAME}.app" "${DMG_TEMP_DIR}/"

# Create link to Applications
ln -s /Applications "${DMG_TEMP_DIR}/Applications"

# Copy background (hidden)
mkdir -p "${DMG_TEMP_DIR}/.background"
# Ensure background exists
if [ -f "../docs/dmg/background.png" ]; then
    cp "../docs/dmg/background.png" "${DMG_TEMP_DIR}/.background/"
fi

echo "💾 Bundling..."
if [ -f "${DMG_NAME}" ]; then
    rm "${DMG_NAME}"
fi

hdiutil create -volname "${PROJECT_NAME}" \
    -srcfolder "${DMG_TEMP_DIR}" \
    -ov -format UDZO "${DMG_NAME}"

echo "✅ Success! Premium distribution package created: ${DMG_NAME}"
echo "💡 Note: To finalize DMG icon positions and background view, manual arrangement in Finder is recommended before final signing."
