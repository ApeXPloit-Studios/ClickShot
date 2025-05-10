@echo off
:: Compile for Nintendo 3DS using LovePotion
set LOVE_PATH=dist\Love2D\ClickShot.love
set OUT_DIR=dist\3DSROM
set PROJECT_NAME=ClickShot

if not exist %LOVE_PATH% (
    echo ERROR: .love file not found at %LOVE_PATH%
    exit /b 1
)

echo 🔧 Compiling for 3DS...
copy %LOVE_PATH% %OUT_DIR%\boot.love >nul

:: Stub: Replace with makerom/3dstool or lovebrew if available
echo [!] 3DSX build stub complete. Requires 3ds tools for final .3dsx

pause
