#!/bin/bash

set -e

# CONFIG
GAME_NAME="ClickShot"
LOVE_VERSION="11.5"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist/Linux"
SRC_DIR="$ROOT_DIR/src"
APPIMAGE_TOOL="$ROOT_DIR/appimagetool.AppImage"

mkdir -p "$BUILD_DIR" "$DIST_DIR"

# 1. Make .love file
echo "[1/4] Creating .love file..."
mkdir -p "$BUILD_DIR/game"
cp -r "$SRC_DIR"/* "$BUILD_DIR/game/"
cd "$BUILD_DIR/game"
zip -9 -r "$BUILD_DIR/$GAME_NAME.love" . > /dev/null
cd "$ROOT_DIR"

# 2. Download LÖVE AppImage if not present
LOVE_APPIMAGE="$BUILD_DIR/love.AppImage"
if [ ! -f "$LOVE_APPIMAGE" ]; then
  echo "[2/4] Downloading LÖVE AppImage..."
  curl -L "https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-x86_64.AppImage" -o "$LOVE_APPIMAGE"
  chmod +x "$LOVE_APPIMAGE"
fi

# 3. Extract AppImage
echo "[3/4] Extracting AppImage..."
"$LOVE_APPIMAGE" --appimage-extract > /dev/null
APPDIR="$BUILD_DIR/appdir"
mv squashfs-root "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
cp "$BUILD_DIR/$GAME_NAME.love" "$APPDIR/usr/bin/"

# Dynamically find the 'love' binary
echo "[3b] Searching for love binary..."
LOVE_BIN_PATH=$(find "$APPDIR" -type f -name "love" -perm -u=x | head -n 1)

if [ -z "$LOVE_BIN_PATH" ]; then
  echo "❌ Error: 'love' binary not found in AppImage."
  exit 1
fi

echo "✅ Found love binary at: $LOVE_BIN_PATH"
cp "$LOVE_BIN_PATH" "$APPDIR/usr/bin/$GAME_NAME"
chmod +x "$APPDIR/usr/bin/$GAME_NAME"

# Add AppRun
echo -e "#!/bin/bash\nexec \"\${APPDIR}/usr/bin/$GAME_NAME\" \"\${APPDIR}/usr/bin/$GAME_NAME.love\"" > "$APPDIR/AppRun"
chmod +x "$APPDIR/AppRun"

# Add .desktop entry
echo "[Desktop Entry]
Name=$GAME_NAME
Exec=$GAME_NAME
Icon=$GAME_NAME
Type=Application
Categories=Game;" > "$APPDIR/$GAME_NAME.desktop"

# Copy icon
cp "$SRC_DIR/ClickShot-Icon.png" "$APPDIR/$GAME_NAME.png"

# 4. Download AppImageTool if needed
if [ ! -f "$APPIMAGE_TOOL" ]; then
  echo "[4/4] Downloading appimagetool..."
  curl -L "https://github.com/AppImage/AppImageKit/releases/latest/download/appimagetool-x86_64.AppImage" -o "$APPIMAGE_TOOL"
  chmod +x "$APPIMAGE_TOOL"
fi

# Package AppImage
echo "📦 Packaging AppImage..."
"$APPIMAGE_TOOL" "$APPDIR" "$DIST_DIR/$GAME_NAME.AppImage"

echo "✅ Done: AppImage saved to $DIST_DIR/$GAME_NAME.AppImage"
