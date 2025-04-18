#!/bin/bash

# Configuration
GAME_NAME="ClickShot"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$ROOT_DIR/dist/iOS"
SRC_DIR="$ROOT_DIR/src"

# Check if source directory exists
if [ ! -d "$SRC_DIR" ]; then
    echo "Error: Source directory not found at $SRC_DIR"
    exit 1
fi

# Create distribution directory if it doesn't exist
mkdir -p "$DIST_DIR"

# Create .love file from the game directory
echo "Creating .love file..."
cd "$SRC_DIR"
zip -q -r "$DIST_DIR/$GAME_NAME.zip" .
cd "$ROOT_DIR"
if [ ! -f "$DIST_DIR/$GAME_NAME.zip" ]; then
    echo "Failed to create zip file"
    exit 1
fi
mv "$DIST_DIR/$GAME_NAME.zip" "$DIST_DIR/$GAME_NAME.love"

echo ""
echo "Game packaged successfully!"
echo "The .love file is available at: $DIST_DIR/$GAME_NAME.love"
echo ""
echo "To test on iOS:"
echo "1. On iOS Simulator: Drag the .love file onto the simulator window"
echo "2. On physical device:"
echo "   - Use Safari to download the .love file"
echo "   - Or transfer via iTunes/Airdrop"
echo "" 