@echo off
:: Compile for Nintendo Switch using LovePotion
set LOVE_PATH=dist\Love2D\ClickShot.love
set OUT_DIR=dist\SwitchROM
set PROJECT_NAME=ClickShot

if not exist %LOVE_PATH% (
    echo ERROR: .love file not found at %LOVE_PATH%
    exit /b 1
)

echo 🔧 Compiling for Switch...
copy %LOVE_PATH% %OUT_DIR%\boot.love >nul

:: Stub: Replace with real NRO builder if available
:: Example with nro2elf or lovebrew-nro-tool
echo [!] NRO build stub complete. You need lovebrew or nro2elf to make a .nro

pause
