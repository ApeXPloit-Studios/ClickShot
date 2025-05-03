@echo off
setlocal enabledelayedexpansion

:: Configuration
set "GAME_NAME=ClickShot"
set "LOVE_VERSION=11.5"
set "LOVE_URL=https://github.com/love2d/love/releases/download/%LOVE_VERSION%/love-%LOVE_VERSION%-win64.zip"
set "ROOT_DIR=%~dp0"
set "BUILD_DIR=%ROOT_DIR%build"
set "DIST_DIR=%ROOT_DIR%dist\Windows"
set "LOVE2D_DIR=%ROOT_DIR%dist\Love2D"
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
if not exist "%LOVE2D_DIR%" mkdir "%LOVE2D_DIR%" 2>nul

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

:: Create regular Windows version
echo Creating Windows version...
mkdir "%BUILD_DIR%\game" 2>nul
xcopy "%SRC_DIR%\*" "%BUILD_DIR%\game\" /E /Y /I >nul
copy "%SRC_DIR%\conf.lua" "%BUILD_DIR%\game\conf.lua" /Y >nul
copy "%SRC_DIR%\settings.lua" "%BUILD_DIR%\game\settings.lua" /Y >nul
cd "%BUILD_DIR%\game"
powershell -Command "Compress-Archive -Path '*' -DestinationPath '%BUILD_DIR%\%GAME_NAME%.zip' -Force"
cd "%ROOT_DIR%"
move "%BUILD_DIR%\%GAME_NAME%.zip" "%BUILD_DIR%\%GAME_NAME%.love" >nul

:: Copy .love to dist\Love2D
echo Copying .love file to dist\Love2D...
copy "%BUILD_DIR%\%GAME_NAME%.love" "%LOVE2D_DIR%\%GAME_NAME%.love" /Y >nul

:: Create executable with icon
echo Creating executable with icon...
copy /b "%BUILD_DIR%\love-%LOVE_VERSION%-win64\love.exe"+"%BUILD_DIR%\%GAME_NAME%.love" "%BUILD_DIR%\%GAME_NAME%.exe" >nul

:: Copy icon files
echo Copying icon files...
copy "%SRC_DIR%\ClickShot-Icon.ico" "%DIST_DIR%\%GAME_NAME%.ico" /Y >nul
copy "%SRC_DIR%\ClickShot-Icon.png" "%DIST_DIR%\%GAME_NAME%.png" /Y >nul

:: Set icon for the executable using ResourceHacker
echo Setting executable icon...
powershell -Command "Invoke-WebRequest -Uri 'http://www.angusj.com/resourcehacker/resource_hacker.zip' -OutFile '%BUILD_DIR%\resource_hacker.zip'"
powershell -Command "Expand-Archive -Path '%BUILD_DIR%\resource_hacker.zip' -DestinationPath '%BUILD_DIR%\resource_hacker' -Force"
"%BUILD_DIR%\resource_hacker\ResourceHacker.exe" -open "%BUILD_DIR%\%GAME_NAME%.exe" -save "%BUILD_DIR%\%GAME_NAME%.exe" -action addoverwrite -res "%DIST_DIR%\%GAME_NAME%.ico" -mask ICONGROUP,1,0

:: Copy Windows files
echo Copying files to Windows directory...
copy "%BUILD_DIR%\%GAME_NAME%.exe" "%DIST_DIR%\" /Y >nul
xcopy "%BUILD_DIR%\love-%LOVE_VERSION%-win64\*.dll" "%DIST_DIR%\" /Y >nul

:: Copy license
echo Copying license...
copy "%ROOT_DIR%LICENSE.txt" "%DIST_DIR%\" /Y >nul 2>&1

:: Clean up build directory
echo Cleaning up...
rd /s /q "%BUILD_DIR%" 2>nul

echo.
echo Success! Your game has been compiled to:
echo - Windows version: "%DIST_DIR%"
echo - Love2D base: "%LOVE2D_DIR%\%GAME_NAME%.love"
echo.
echo Launching Windows version...
start "" "%DIST_DIR%\%GAME_NAME%.exe"
pause
exit /b 0
