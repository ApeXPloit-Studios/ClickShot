#!/bin/bash

# Configuration
GAME_NAME="ClickShot"
LOVE_VERSION="11.5"
LOVE_URL="https://github.com/love2d/love/releases/download/$LOVE_VERSION/love-$LOVE_VERSION-macos.zip"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist/macOS"
SRC_DIR="$ROOT_DIR/src"

# Check if source directory exists
if [ ! -d "$SRC_DIR" ]; then
    echo "Error: Source directory not found at $SRC_DIR"
    exit 1
fi

# Clean build directory if it exists
if [ -d "$BUILD_DIR" ]; then
    echo "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
fi

# Create directories
mkdir -p "$BUILD_DIR"
mkdir -p "$DIST_DIR"

# Download LÖVE
echo "Downloading LÖVE..."
curl -L "$LOVE_URL" -o "$BUILD_DIR/love.zip"
if [ ! -f "$BUILD_DIR/love.zip" ]; then
    echo "Failed to download LÖVE"
    exit 1
fi

# Extract LÖVE
echo "Extracting LÖVE..."
unzip -q "$BUILD_DIR/love.zip" -d "$BUILD_DIR"
if [ ! -d "$BUILD_DIR/love.app" ]; then
    echo "Failed to extract LÖVE"
    exit 1
fi

# Create temporary directory for game files
mkdir -p "$BUILD_DIR/game"
cp -R "$SRC_DIR/"* "$BUILD_DIR/game/"

# Create .love file from the game directory
echo "Creating .love file..."
cd "$BUILD_DIR/game"
zip -q -r "$BUILD_DIR/$GAME_NAME.zip" .
cd "$ROOT_DIR"
if [ ! -f "$BUILD_DIR/$GAME_NAME.zip" ]; then
    echo "Failed to create zip file"
    exit 1
fi
mv "$BUILD_DIR/$GAME_NAME.zip" "$BUILD_DIR/$GAME_NAME.love"

# Create application bundle
echo "Creating application bundle..."
cp -R "$BUILD_DIR/love.app" "$BUILD_DIR/$GAME_NAME.app"
cp "$BUILD_DIR/$GAME_NAME.love" "$BUILD_DIR/$GAME_NAME.app/Contents/Resources/"

# Update Info.plist
echo "Updating Info.plist..."
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.apexploit.$GAME_NAME" "$BUILD_DIR/$GAME_NAME.app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName $GAME_NAME" "$BUILD_DIR/$GAME_NAME.app/Contents/Info.plist"

# Copy final files to dist/macOS
echo "Copying files to distribution directory..."
cp -R "$BUILD_DIR/$GAME_NAME.app" "$DIST_DIR/"
if [ ! -d "$DIST_DIR/$GAME_NAME.app" ]; then
    echo "Failed to copy application bundle"
    exit 1
fi

# Copy license
if [ -f "$ROOT_DIR/LICENSE.txt" ]; then
    cp "$ROOT_DIR/LICENSE.txt" "$DIST_DIR/"
fi

# Clean up build directory
echo "Cleaning up..."
rm -rf "$BUILD_DIR"

echo ""
echo "Done! Your game is in the '$DIST_DIR' folder."
echo "" 