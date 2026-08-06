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
OUTPUT_APK="${PACKAGE_NAME}_${VERSION_TAG}-unsigned.apk"

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

# 4. Copy and rename the unsigned APK to the project root
echo "Copying unsigned APK to project root..."
cp "$UNSIGNED_APK" "$OUTPUT_APK"

echo "------------------------------------------------"
echo "Success! Unsigned APK copied to: $OUTPUT_APK"
echo "------------------------------------------------"
