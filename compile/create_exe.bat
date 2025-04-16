@echo off
setlocal enabledelayedexpansion

:: Configuration
set GAME_NAME=ClickShot
set LOVE_VERSION=11.4
set LOVE_URL=https://github.com/love2d/love/releases/download/%LOVE_VERSION%/love-%LOVE_VERSION%-win64.zip

:: Set up directories relative to script location
set SCRIPT_DIR=%~dp0
set DIST_DIR=%SCRIPT_DIR%..\dist
set BUILD_DIR=%SCRIPT_DIR%..\build
set TEMP_DIR=%BUILD_DIR%\temp

:: Create directories if they don't exist
if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

:: Download LÖVE
echo Downloading LÖVE...
powershell -Command "Invoke-WebRequest -Uri '%LOVE_URL%' -OutFile '%TEMP_DIR%\love.zip'"
if not exist "%TEMP_DIR%\love.zip" (
    echo Failed to download LÖVE
    goto :error
)

:: Extract LÖVE
echo Extracting LÖVE...
powershell -Command "Expand-Archive -Path '%TEMP_DIR%\love.zip' -DestinationPath '%TEMP_DIR%\love' -Force"
if not exist "%TEMP_DIR%\love\love.exe" (
    echo Failed to extract LÖVE
    goto :error
)

:: Create .love file (first as .zip, then rename)
echo Creating .love file...
powershell -Command "Compress-Archive -Path '%SCRIPT_DIR%..\*.lua', '%SCRIPT_DIR%..\assets' -DestinationPath '%TEMP_DIR%\%GAME_NAME%.zip' -Force"
if not exist "%TEMP_DIR%\%GAME_NAME%.zip" (
    echo Failed to create zip file
    goto :error
)
move "%TEMP_DIR%\%GAME_NAME%.zip" "%TEMP_DIR%\%GAME_NAME%.love"

:: Create executable
echo Creating executable...
copy /b "%TEMP_DIR%\love\love.exe"+"%TEMP_DIR%\%GAME_NAME%.love" "%DIST_DIR%\%GAME_NAME%.exe"
if not exist "%DIST_DIR%\%GAME_NAME%.exe" (
    echo Failed to create executable
    goto :error
)

:: Copy required DLLs
echo Copying DLLs...
xcopy "%TEMP_DIR%\love\*.dll" "%DIST_DIR%\" /Y
if errorlevel 1 (
    echo Warning: Failed to copy some DLLs
)

:: Copy license
echo Copying license...
copy "%SCRIPT_DIR%..\LICENSE.txt" "%DIST_DIR%\" /Y
if errorlevel 1 (
    echo Warning: Failed to copy license
)

:: Clean up
echo Cleaning up...
rmdir /s /q "%TEMP_DIR%"

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