@echo off
:: Compile for Wii U using LovePotion
set LOVE_PATH=dist\Love2D\ClickShot.love
set OUT_DIR=dist\WiiUROM\ClickShot
set PROJECT_NAME=ClickShot

if not exist %LOVE_PATH% (
    echo ERROR: .love file not found at %LOVE_PATH%
    exit /b 1
)

echo 🔧 Compiling for Wii U...
mkdir %OUT_DIR% >nul 2>&1
copy %LOVE_PATH% %OUT_DIR%\boot.love >nul
echo <meta><name>ClickShot</name></meta> > %OUT_DIR%\meta.xml

echo [!] Wii U structure ready. You can package it with wup installer format or loadiine.

pause
