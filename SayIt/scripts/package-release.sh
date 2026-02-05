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

# 1. Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# 2. Build for Release
echo "🏗 Building ${PROJECT_NAME} for Release..."
xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_NAME}" \
    -configuration Release \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    SYMROOT="$(pwd)/${BUILD_DIR}" \
    build

# 3. Create DMG
echo "📦 Creating DMG package..."
if [ -f "${DMG_NAME}" ]; then
    rm "${DMG_NAME}"
fi

hdiutil create -volname "${PROJECT_NAME}" \
    -srcfolder "${RELEASE_DIR}/${PROJECT_NAME}.app" \
    -ov -format UDZO "${DMG_NAME}"

echo "✅ Success! Distribution package created: ${DMG_NAME}"
