# Create a shell script named compile_linux.sh that builds an AppImage into dist/Linux
linux_script_content = """#!/bin/bash

# Configuration
GAME_NAME="ClickShot"
LOVE_VERSION="11.5"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist/Linux"
SRC_DIR="$ROOT_DIR/src"

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$DIST_DIR"

# Create .love file
echo "Creating .love file..."
cp -r "$SRC_DIR" "$BUILD_DIR/game"
cd "$BUILD_DIR/game"
zip -9 -r "$BUILD_DIR/$GAME_NAME.love" . > /dev/null
cd "$ROOT_DIR"

# Download LÖVE AppImage if not cached
APPIMAGE_URL="https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-x86_64.AppImage"
APPIMAGE_PATH="$BUILD_DIR/love.AppImage"

if [ ! -f "$APPIMAGE_PATH" ]; then
  echo "Downloading LÖVE AppImage..."
  curl -L "$APPIMAGE_URL" -o "$APPIMAGE_PATH"
  chmod +x "$APPIMAGE_PATH"
fi

# Extract AppImage
echo "Extracting AppImage..."
"$APPIMAGE_PATH" --appimage-extract > /dev/null
mv squashfs-root "$BUILD_DIR/appdir"

# Copy game.love
cp "$BUILD_DIR/$GAME_NAME.love" "$BUILD_DIR/appdir/usr/bin/"

# Rename LÖVE binary to run the game directly
mv "$BUILD_DIR/appdir/usr/bin/love" "$BUILD_DIR/appdir/usr/bin/$GAME_NAME"
chmod +x "$BUILD_DIR/appdir/usr/bin/$GAME_NAME"

# Create AppRun launcher
echo -e "#!/bin/bash\nexec \"\${APPDIR}/usr/bin/$GAME_NAME\" \"\${APPDIR}/usr/bin/$GAME_NAME.love\"" > "$BUILD_DIR/appdir/AppRun"
chmod +x "$BUILD_DIR/appdir/AppRun"

# Add icon and desktop file
cp "$SRC_DIR/ClickShot-Icon.png" "$BUILD_DIR/appdir/$GAME_NAME.png"
echo "[Desktop Entry]
Name=$GAME_NAME
Exec=$GAME_NAME
Icon=$GAME_NAME
Type=Application
Categories=Game;" > "$BUILD_DIR/appdir/$GAME_NAME.desktop"

# Package AppImage
echo "Packaging AppImage..."
ARCH=x86_64 ./appimagetool.AppImage "$BUILD_DIR/appdir" "$DIST_DIR/$GAME_NAME.AppImage"

echo "Linux AppImage is ready at $DIST_DIR/$GAME_NAME.AppImage"
"""

# Save this script
linux_script_path = "/mnt/data/clickshot_project/compile_linux.sh"
with open(linux_script_path, "w") as f:
    f.write(linux_script_content)

linux_script_path
