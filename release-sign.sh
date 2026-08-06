#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# 1. Fetch the latest git tag version
echo "Retrieving latest git tag..."
VERSION_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -z "$VERSION_TAG" ]; then
    echo "No git tag found. Using 'v0.0.1' as fallback."
    VERSION_TAG="v0.0.1"
else
    echo "Found git tag: $VERSION_TAG"
fi

# 2. Define package name and output APK filename
PACKAGE_NAME="com.looker.droidify"
OUTPUT_APK="${PACKAGE_NAME}_${VERSION_TAG}.apk"

# 3. Build the unsigned release APK
echo "Building unsigned release APK with Gradle..."
./gradlew assembleRelease

# Find the unsigned APK in the build directory
UNSIGNED_APK="./app/build/outputs/apk/release/app-release-unsigned.apk"
if [ ! -f "$UNSIGNED_APK" ]; then
    UNSIGNED_APK=$(find ./app/build/outputs/apk/release -name "*unsigned.apk" -print -quit 2>/dev/null || echo "")
fi

if [ -z "$UNSIGNED_APK" ] || [ ! -f "$UNSIGNED_APK" ]; then
    echo "Error: Unsigned release APK could not be found."
    exit 1
fi

echo "Found unsigned APK at: $UNSIGNED_APK"

# 4. Sign the APK using the PKCS12 keystore
KEYSTORE="keystore.p12"
if [ ! -f "$KEYSTORE" ]; then
    echo "Error: Keystore file '$KEYSTORE' not found in the project root directory."
    exit 1
fi

# Check if KEY_ALIAS is set, otherwise ask for it
if [ -z "$KEY_ALIAS" ]; then
    read -p "Enter key alias: " KEY_ALIAS
fi

# Check if KEYSTORE_PASSWORD is set, otherwise prompt for it securely
if [ -z "$KEYSTORE_PASSWORD" ]; then
    read -sp "Enter keystore password: " KEYSTORE_PASSWORD
    echo "" # Add newline after secure input
fi

# Export KEYSTORE_PASSWORD so apksigner can read it securely from the environment
export KEYSTORE_PASSWORD

echo "Signing APK with keystore '$KEYSTORE' and alias '$KEY_ALIAS'..."
apksigner sign --ks "$KEYSTORE" \
               --ks-type PKCS12 \
               --ks-key-alias "$KEY_ALIAS" \
               --ks-pass env:KEYSTORE_PASSWORD \
               --out "$OUTPUT_APK" \
               "$UNSIGNED_APK"

echo "------------------------------------------------"
echo "Success! Signed APK created: $OUTPUT_APK"
echo "------------------------------------------------"
