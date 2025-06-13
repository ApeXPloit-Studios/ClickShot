@echo off
setlocal enabledelayedexpansion

:: Configuration
set "GAME_NAME=ClickShot"
set "ROOT_DIR=%~dp0"
set "BUILD_DIR=%ROOT_DIR%build"
set "DIST_DIR=%ROOT_DIR%dist\Nintendo"
set "SRC_DIR=%ROOT_DIR%src"

:: Check parameters
if "%~1"=="" (
    echo Usage: compile_nintendo.bat [3ds^|switch^|wiiu]
    echo Example: compile_nintendo.bat 3ds
    exit /b 1
)

:: Set platform-specific variables
if /i "%~1"=="3ds" (
    set "PLATFORM=3DS"
    set "PLATFORM_DIR=%DIST_DIR%\3DS"
    set "LOVEPOTION_DIR=%ROOT_DIR%LOVEPotion\3DS"
    set "OUTPUT_EXT=3dsx"
) else if /i "%~1"=="switch" (
    set "PLATFORM=Switch"
    set "PLATFORM_DIR=%DIST_DIR%\Switch"
    set "LOVEPOTION_DIR=%ROOT_DIR%LOVEPotion\Switch"
    set "OUTPUT_EXT=nro"
) else if /i "%~1"=="wiiu" (
    set "PLATFORM=WiiU"
    set "PLATFORM_DIR=%DIST_DIR%\WiiU"
    set "LOVEPOTION_DIR=%ROOT_DIR%LOVEPotion\WiiU"
    set "OUTPUT_EXT=wuhb"
) else (
    echo Invalid platform. Use 3ds, switch, or wiiu.
    exit /b 1
)

:: Check if LOVEPotion directory exists
if not exist "%LOVEPOTION_DIR%" (
    echo Error: LOVEPotion directory for %PLATFORM% not found at "%LOVEPOTION_DIR%"
    echo Please download LOVEPotion for %PLATFORM% and place it in that directory.
    pause
    exit /b 1
)

:: Check if LOVEPotion executable exists
set "LOVEPOTION_EXE=%LOVEPOTION_DIR%\lovepotion.%OUTPUT_EXT%"
if not exist "%LOVEPOTION_EXE%" (
    echo Error: LOVEPotion executable not found at "%LOVEPOTION_EXE%"
    pause
    exit /b 1
)

:: Clean build directory if it exists
if exist "%BUILD_DIR%" (
    echo Cleaning build directory...
    rd /s /q "%BUILD_DIR%" 2>nul
)

:: Create directories
echo Creating directories...
mkdir "%BUILD_DIR%" 2>nul
if not exist "%PLATFORM_DIR%" mkdir "%PLATFORM_DIR%" 2>nul

:: Create .love file
echo Creating .love file...
mkdir "%BUILD_DIR%\game" 2>nul
xcopy "%SRC_DIR%\*" "%BUILD_DIR%\game\" /E /Y /I >nul
cd "%BUILD_DIR%\game"
powershell -Command "Compress-Archive -Path '*' -DestinationPath '%BUILD_DIR%\%GAME_NAME%.zip' -Force"
cd "%ROOT_DIR%"
move "%BUILD_DIR%\%GAME_NAME%.zip" "%BUILD_DIR%\%GAME_NAME%.love" >nul

:: Create fused game
echo Creating %PLATFORM% version...
copy /b "%LOVEPOTION_EXE%"+"%BUILD_DIR%\%GAME_NAME%.love" "%PLATFORM_DIR%\%GAME_NAME%.%OUTPUT_EXT%" >nul

:: Clean up build directory
echo Cleaning up...
rd /s /q "%BUILD_DIR%" 2>nul

echo.
echo Success! Your game has been compiled for %PLATFORM%:
echo - Output file: "%PLATFORM_DIR%\%GAME_NAME%.%OUTPUT_EXT%"
echo.
echo To install on your %PLATFORM%:
if /i "%PLATFORM%"=="3DS" (
    echo - Copy %GAME_NAME%.3dsx to sdmc:/3ds/ folder on your 3DS SD card
    echo - Launch through Homebrew Launcher
)
if /i "%PLATFORM%"=="Switch" (
    echo - Copy %GAME_NAME%.nro to sdmc:/switch/ folder on your Switch SD card
    echo - Launch through Homebrew Menu
)
if /i "%PLATFORM%"=="WiiU" (
    echo - Copy %GAME_NAME%.wuhb to sdmc:/wiiu/apps/ folder on your Wii U SD card
    echo - Launch through Homebrew Launcher or Home Menu
)
echo.
pause
exit /b 0 