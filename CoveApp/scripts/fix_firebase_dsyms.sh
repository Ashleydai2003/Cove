#!/bin/bash

# Fix Firebase dSYM missing issue for Swift Package Manager
# This script copies dSYM files from build products to the archive

set -e

echo "🔧 Fixing Firebase dSYM files..."

# Get the build products directory
BUILD_PRODUCTS_DIR="${BUILT_PRODUCTS_DIR}"
ARCHIVE_PATH="${ARCHIVE_PATH}"

if [ -z "$BUILD_PRODUCTS_DIR" ]; then
    echo "❌ BUILD_PRODUCTS_DIR not set"
    exit 1
fi

if [ -z "$ARCHIVE_PATH" ]; then
    echo "❌ ARCHIVE_PATH not set"
    exit 1
fi

echo "📁 Build products directory: $BUILD_PRODUCTS_DIR"
echo "📦 Archive path: $ARCHIVE_PATH"

# Create dSYMs directory in archive if it doesn't exist
DSYMS_DIR="$ARCHIVE_PATH/dSYMs"
mkdir -p "$DSYMS_DIR"

# Copy Firebase dSYM files from build products to archive
FIREBASE_FRAMEWORKS=(
    "FirebaseAnalytics.framework"
    "GoogleAppMeasurement.framework"
    "GoogleAppMeasurementIdentitySupport.framework"
)

for framework in "${FIREBASE_FRAMEWORKS[@]}"; do
    # Look for dSYM in build products
    DSYM_SOURCE="$BUILD_PRODUCTS_DIR/$framework.dSYM"
    
    if [ -d "$DSYM_SOURCE" ]; then
        echo "✅ Found dSYM for $framework"
        cp -R "$DSYM_SOURCE" "$DSYMS_DIR/"
        echo "📋 Copied $framework.dSYM to archive"
    else
        echo "⚠️  dSYM not found for $framework at $DSYM_SOURCE"
        
        # Try to find it in derived data
        DERIVED_DATA=$(xcodebuild -project Cove.xcodeproj -showBuildSettings | grep OBJROOT | awk '{print $3}')
        if [ -n "$DERIVED_DATA" ]; then
            DSYM_SOURCE="$DERIVED_DATA/Build/Products/Release-iphoneos/$framework.dSYM"
            if [ -d "$DSYM_SOURCE" ]; then
                echo "✅ Found dSYM for $framework in derived data"
                cp -R "$DSYM_SOURCE" "$DSYMS_DIR/"
                echo "📋 Copied $framework.dSYM to archive"
            else
                echo "❌ dSYM not found for $framework in derived data either"
            fi
        fi
    fi
done

echo "✅ Firebase dSYM fix completed" 