@echo off
setlocal enabledelayedexpansion

:: Configuration
set "GAME_NAME=ClickShot"
set "LOVE_VERSION=11.5"
set "LOVE_URL=https://github.com/love2d/love/releases/download/%LOVE_VERSION%/love-%LOVE_VERSION%-win64.zip"
set "ROOT_DIR=%~dp0"
set "BUILD_DIR=%ROOT_DIR%build"
set "DIST_DIR=%ROOT_DIR%dist\Windows"
set "LOVE_DIST_DIR=%ROOT_DIR%dist\Love2D"
set "SRC_DIR=%ROOT_DIR%src"

:: Check if source directory exists
if not exist "%SRC_DIR%" (
    echo Error: Source directory not found at "%SRC_DIR%"
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
if not exist "%DIST_DIR%" mkdir "%DIST_DIR%" 2>nul

:: Download LÖVE to build directory
echo Downloading LÖVE...
powershell -Command "Invoke-WebRequest -Uri '%LOVE_URL%' -OutFile '%BUILD_DIR%\love.zip'"
if not exist "%BUILD_DIR%\love.zip" (
    echo Error: Failed to download LÖVE
    pause
    exit /b 1
)

:: Extract LÖVE
echo Extracting LÖVE...
powershell -Command "Expand-Archive -Path '%BUILD_DIR%\love.zip' -DestinationPath '%BUILD_DIR%' -Force"
if not exist "%BUILD_DIR%\love-%LOVE_VERSION%-win64\love.exe" (
    echo Error: Failed to extract LÖVE
    pause
    exit /b 1
)

:: Create temporary directory for game files
echo Copying game files...
mkdir "%BUILD_DIR%\game" 2>nul
xcopy "%SRC_DIR%\*" "%BUILD_DIR%\game\" /E /Y /I >nul
if errorlevel 1 (
    echo Error: Failed to copy game files
    pause
    exit /b 1
)

:: Create .love file from the game directory
echo Creating .love file...
cd "%BUILD_DIR%\game"
powershell -Command "Compress-Archive -Path '*' -DestinationPath '%BUILD_DIR%\%GAME_NAME%.zip' -Force"
cd "%ROOT_DIR%"
if not exist "%BUILD_DIR%\%GAME_NAME%.zip" (
    echo Error: Failed to create zip file
    pause
    exit /b 1
)
move "%BUILD_DIR%\%GAME_NAME%.zip" "%BUILD_DIR%\%GAME_NAME%.love" >nul

:: Create executable
echo Creating executable...
copy /b "%BUILD_DIR%\love-%LOVE_VERSION%-win64\love.exe"+"%BUILD_DIR%\%GAME_NAME%.love" "%BUILD_DIR%\%GAME_NAME%.exe" >nul
if not exist "%BUILD_DIR%\%GAME_NAME%.exe" (
    echo Error: Failed to create executable
    pause
    exit /b 1
)

:: Copy final files to dist/Windows
echo Copying files to distribution directory...
copy "%BUILD_DIR%\%GAME_NAME%.exe" "%DIST_DIR%\" /Y >nul
if errorlevel 1 (
    echo Error: Failed to copy executable
    pause
    exit /b 1
)

:: Copy .love file to dist/Love2D
echo Copying .love file to Love2D distribution directory...
if not exist "%LOVE_DIST_DIR%" mkdir "%LOVE_DIST_DIR%" 2>nul
copy "%BUILD_DIR%\%GAME_NAME%.love" "%LOVE_DIST_DIR%\" /Y >nul
if errorlevel 1 (
    echo Error: Failed to copy .love file
    pause
    exit /b 1
)

:: Copy required DLLs
echo Copying DLLs...
xcopy "%BUILD_DIR%\love-%LOVE_VERSION%-win64\*.dll" "%DIST_DIR%\" /Y >nul
if errorlevel 1 (
    echo Warning: Failed to copy some DLLs
)

:: Copy license
echo Copying license...
copy "%ROOT_DIR%LICENSE.txt" "%DIST_DIR%\" /Y >nul 2>&1
if errorlevel 1 (
    echo Warning: License file not found
)

:: Clean up build directory
echo Cleaning up...
rd /s /q "%BUILD_DIR%" 2>nul

echo.
echo Success! Your game has been compiled to: "%DIST_DIR%"
echo.
pause
exit /b 0 