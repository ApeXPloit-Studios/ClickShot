@echo off
:: Check for admin privileges and relaunch if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

setlocal enabledelayedexpansion

:: Configuration
set GAME_NAME=ClickShot
set LOVE_VERSION=11.5
set LOVE_URL=https://github.com/love2d/love/releases/download/%LOVE_VERSION%/love-%LOVE_VERSION%-win64.zip
set ROOT_DIR=%~dp0
set BUILD_DIR=%ROOT_DIR%build
set DIST_DIR=%ROOT_DIR%dist\Windows
set SRC_DIR=%ROOT_DIR%src

:: Check if source directory exists
if not exist "%SRC_DIR%" (
    echo Error: Source directory not found at %SRC_DIR%
    goto :error
)

:: Clean build directory if it exists
if exist "%BUILD_DIR%" (
    echo Cleaning build directory...
    rd /s /q "%BUILD_DIR%"
)

:: Create directories
mkdir "%BUILD_DIR%"
if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"

:: Download LÖVE to build directory
echo Downloading LÖVE...
powershell -Command "Invoke-WebRequest -Uri '%LOVE_URL%' -OutFile '%BUILD_DIR%\love.zip'"
if not exist "%BUILD_DIR%\love.zip" (
    echo Failed to download LÖVE
    goto :error
)

:: Extract LÖVE
echo Extracting LÖVE...
powershell -Command "Expand-Archive -Path '%BUILD_DIR%\love.zip' -DestinationPath '%BUILD_DIR%' -Force"
if not exist "%BUILD_DIR%\love-%LOVE_VERSION%-win64\love.exe" (
    echo Failed to extract LÖVE
    goto :error
)

:: Create temporary directory for game files
mkdir "%BUILD_DIR%\game"
xcopy "%SRC_DIR%\*" "%BUILD_DIR%\game\" /E /Y

:: Create .love file from the game directory
echo Creating .love file...
cd "%BUILD_DIR%\game"
powershell -Command "Compress-Archive -Path '*' -DestinationPath '%BUILD_DIR%\%GAME_NAME%.zip' -Force"
cd "%ROOT_DIR%"
if not exist "%BUILD_DIR%\%GAME_NAME%.zip" (
    echo Failed to create zip file
    goto :error
)
move "%BUILD_DIR%\%GAME_NAME%.zip" "%BUILD_DIR%\%GAME_NAME%.love"

:: Create executable
echo Creating executable...
copy /b "%BUILD_DIR%\love-%LOVE_VERSION%-win64\love.exe"+"%BUILD_DIR%\%GAME_NAME%.love" "%BUILD_DIR%\%GAME_NAME%.exe"
if not exist "%BUILD_DIR%\%GAME_NAME%.exe" (
    echo Failed to create executable
    goto :error
)

:: Copy final files to dist/Windows
echo Copying files to distribution directory...
copy "%BUILD_DIR%\%GAME_NAME%.exe" "%DIST_DIR%\" /Y
if errorlevel 1 (
    echo Failed to copy executable
    goto :error
)

:: Copy required DLLs
xcopy "%BUILD_DIR%\love-%LOVE_VERSION%-win64\*.dll" "%DIST_DIR%\" /Y
if errorlevel 1 (
    echo Warning: Failed to copy some DLLs
)

:: Copy license
copy "%ROOT_DIR%LICENSE.txt" "%DIST_DIR%\" /Y 2>nul
if errorlevel 1 (
    echo Warning: License file not found
)

:: Clean up build directory
echo Cleaning up...
rd /s /q "%BUILD_DIR%"

echo.
echo Done! Your game is in the '%DIST_DIR%' folder.
echo.
goto :end

:error
echo.
echo An error occurred during the process.
echo Please check the error messages above.
echo.
pause
exit /b 1

:end
pause 