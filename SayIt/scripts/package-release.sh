#!/usr/bin/env bash

# SayIt Packaging Script
# This script builds the application in Release mode and creates a DMG for distribution.

set -euo pipefail

PROJECT_NAME="SayIt"
SCHEME_NAME="SayIt"
BUILD_DIR="./build"
RELEASE_DIR="${BUILD_DIR}/Release"
APP_PATH="${RELEASE_DIR}/${PROJECT_NAME}.app"
MARKETING_VERSION="${MARKETING_VERSION:-$(xcodebuild -project "${PROJECT_NAME}.xcodeproj" -scheme "${SCHEME_NAME}" -showBuildSettings 2>/dev/null | awk -F' = ' '/MARKETING_VERSION/ {print $2; exit}')}"
if [ -z "${MARKETING_VERSION}" ]; then
    echo "❌ Could not determine MARKETING_VERSION. Set MARKETING_VERSION or DMG_NAME manually." >&2
    exit 1
fi
DMG_NAME="${DMG_NAME:-${PROJECT_NAME}_v${MARKETING_VERSION}.dmg}"
APP_ZIP_FOR_NOTARY="${BUILD_DIR}/${PROJECT_NAME}-for-notary.zip"
NOTARY_KEY_FILE="/tmp/${PROJECT_NAME}-app-store-connect-key.p8"
KEEP_STAGING="${KEEP_STAGING:-0}"
STAGING_DIR="$(mktemp -d "/tmp/${PROJECT_NAME}-pkg.XXXXXX")"
STAGED_APP_PATH="${STAGING_DIR}/${PROJECT_NAME}.app"

cleanup() {
    rm -f "${NOTARY_KEY_FILE}" 2>/dev/null || true
    if [ "${KEEP_STAGING}" != "1" ]; then
        rm -rf "${STAGING_DIR}" 2>/dev/null || true
    fi
}

trap cleanup EXIT

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
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-Developer ID Application: Zhuo Niu (V7Z2QYFJWN)}"
ENABLE_NOTARIZATION="${ENABLE_NOTARIZATION:-1}"

has_notary_credentials() {
    local has_key="0"
    if [ -n "${APP_STORE_CONNECT_API_KEY_P8:-}" ]; then
        has_key="1"
    fi
    if [ -n "${APP_STORE_CONNECT_API_KEY_P8_FILE:-}" ] && [ -f "${APP_STORE_CONNECT_API_KEY_P8_FILE}" ]; then
        has_key="1"
    fi

    [ "${has_key}" = "1" ] && \
    [ -n "${APP_STORE_CONNECT_KEY_ID:-}" ]
}

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

if [ ! -d "${APP_PATH}" ]; then
    echo "❌ Build succeeded but app bundle not found: ${APP_PATH}" >&2
    exit 1
fi

echo "📂 Preparing clean staging app bundle in ${STAGING_DIR}..."
cp -R "${APP_PATH}" "${STAGED_APP_PATH}"

# 2.5 Code Sign the app bundle
if [ -n "${CODESIGN_IDENTITY}" ]; then
    echo "🧹 Final detritus cleanup on built app..."
    xattr -cr "${STAGED_APP_PATH}" || true
    xattr -d com.apple.FinderInfo "${STAGED_APP_PATH}" 2>/dev/null || true
    xattr -d com.apple.fileprovider.fpfs#P "${STAGED_APP_PATH}" 2>/dev/null || true

    echo "🔑 Signing app with identity: ${CODESIGN_IDENTITY}"
    # Use --options runtime for Hardened Runtime (required for notarization)
    codesign --force --timestamp --options runtime --deep --sign "${CODESIGN_IDENTITY}" \
        --entitlements "${CODE_SIGN_ENTITLEMENTS}" \
        "${STAGED_APP_PATH}"

    # Some filesystem metadata can be reattached by Finder/FileProvider after signing.
    # Remove only disallowed attrs before strict verification.
    xattr -d com.apple.FinderInfo "${STAGED_APP_PATH}" 2>/dev/null || true
    xattr -d com.apple.fileprovider.fpfs#P "${STAGED_APP_PATH}" 2>/dev/null || true

    echo "🔍 Verifying signature integrity..."
    codesign --verify --deep --strict --verbose=2 "${STAGED_APP_PATH}"
fi

if [ "${ENABLE_NOTARIZATION}" = "1" ] && has_notary_credentials; then
    echo "📝 Preparing App Store Connect API key..."
    if [ -n "${APP_STORE_CONNECT_API_KEY_P8_FILE:-}" ] && [ -f "${APP_STORE_CONNECT_API_KEY_P8_FILE}" ]; then
        cp "${APP_STORE_CONNECT_API_KEY_P8_FILE}" "${NOTARY_KEY_FILE}"
    else
        printf '%s' "${APP_STORE_CONNECT_API_KEY_P8}" | sed 's/\\n/\n/g' > "${NOTARY_KEY_FILE}"
    fi

    echo "📦 Creating app zip for notarization..."
    /usr/bin/ditto --norsrc -c -k --keepParent "${STAGED_APP_PATH}" "${APP_ZIP_FOR_NOTARY}"

    NOTARY_AUTH_ARGS=(--key "${NOTARY_KEY_FILE}" --key-id "${APP_STORE_CONNECT_KEY_ID}")
    if [ -n "${APP_STORE_CONNECT_ISSUER_ID:-}" ]; then
        NOTARY_AUTH_ARGS+=(--issuer "${APP_STORE_CONNECT_ISSUER_ID}")
    fi

    echo "☁️ Submitting app zip for notarization..."
    xcrun notarytool submit "${APP_ZIP_FOR_NOTARY}" \
        "${NOTARY_AUTH_ARGS[@]}" \
        --wait

    echo "📎 Stapling notarization ticket to app..."
    xcrun stapler staple "${STAGED_APP_PATH}"
    xcrun stapler validate "${STAGED_APP_PATH}"
else
    echo "⚠️ Skipping app notarization. Set APP_STORE_CONNECT_API_KEY_P8 or APP_STORE_CONNECT_API_KEY_P8_FILE, plus APP_STORE_CONNECT_KEY_ID. APP_STORE_CONNECT_ISSUER_ID is optional (omit for Individual API Key)."
fi

# 3. Create Premium DMG
echo "📦 Creating Premium DMG package..."
DMG_TEMP_DIR="${STAGING_DIR}/dmg_temp"
rm -rf "${DMG_TEMP_DIR}"
mkdir -p "${DMG_TEMP_DIR}"

# Copy app to temp dir (already signed; stapled if notarization was enabled)
cp -R "${STAGED_APP_PATH}" "${DMG_TEMP_DIR}/"

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

if [ "${ENABLE_NOTARIZATION}" = "1" ] && has_notary_credentials; then
    echo "☁️ Submitting DMG for notarization..."
    xcrun notarytool submit "${DMG_NAME}" \
        "${NOTARY_AUTH_ARGS[@]}" \
        --wait

    echo "📎 Stapling notarization ticket to DMG..."
    xcrun stapler staple "${DMG_NAME}"
    xcrun stapler validate "${DMG_NAME}"
fi

echo "🔍 Final Gatekeeper checks..."
spctl -a -vv -t exec "${STAGED_APP_PATH}" || true
spctl -a -vv -t open "${DMG_NAME}" || true

echo "✅ Success! Premium distribution package created: ${DMG_NAME}"
echo "💡 Note: To finalize DMG icon positions and background view, manual arrangement in Finder is recommended before final signing."
