@echo off
REM Local Flutter Web Deployment Script with Firebase Emulator Check
REM This script checks if Firebase emulators are running and deploys the Flutter app in web mode

setlocal enabledelayedexpansion

if "%1"=="--help" goto :help
if "%1"=="-h" goto :help
goto :main

:help
echo Local Flutter Web Deployment Script
echo.
echo Usage: deploy-local.bat [OPTIONS]
echo.
echo Options:
echo   --skip-emulator-check    Skip checking if Firebase emulators are running
echo   --help, -h              Show this help message
echo.
echo Description:
echo This script checks if Firebase emulators are running on configured ports,
echo then deploys the Flutter app locally in web mode for testing.
echo.
echo Configured emulator ports (from firebase.json):
echo - Auth: 9099
echo - Firestore: 8080  
echo - Functions: 5001
echo - UI: 4100
exit /b 0

:main
echo.
echo [INFO] Starting local Flutter web deployment...

REM Change to fittrack directory
set "FITTRACK_PATH=%~dp0fittrack"
if not exist "%FITTRACK_PATH%" (
    echo [ERROR] fittrack directory not found at: %FITTRACK_PATH%
    exit /b 1
)

cd /d "%FITTRACK_PATH%"
echo [INFO] Changed to directory: %FITTRACK_PATH%

REM Check Firebase emulators unless skipped
if "%1"=="--skip-emulator-check" (
    echo [WARNING] Skipping Firebase emulator check
    goto :flutter_setup
)

echo.
echo [INFO] Checking Firebase emulators status...

REM Check each emulator port
call :check_port "Auth" 9099
call :check_port "Firestore" 8080
call :check_port "Functions" 5001
call :check_port "UI" 4100

if !EMULATOR_ISSUES! gtr 0 (
    echo.
    echo [WARNING] Some Firebase emulators are not running
    echo [INFO] Would you like to start the Firebase emulators automatically?
    echo.
    set /p "START_EMULATORS=Start Firebase emulators? (Y/n): "
    if /i "!START_EMULATORS!"=="n" (
        set /p "CONTINUE=Continue with Flutter deployment without emulators? (y/N): "
        if /i not "!CONTINUE!"=="y" (
            echo [ERROR] Deployment cancelled
            exit /b 1
        )
    ) else (
        echo [INFO] Starting Firebase emulators...
        
        REM Check if Firebase CLI is available
        firebase --version >nul 2>&1
        if errorlevel 1 (
            echo [ERROR] Firebase CLI is not installed or not in PATH
            echo [INFO] Please install Firebase CLI: npm install -g firebase-tools
            set /p "CONTINUE=Continue with Flutter deployment without emulators? (y/N): "
            if /i not "!CONTINUE!"=="y" (
                echo [ERROR] Deployment cancelled
                exit /b 1
            )
        ) else (
            REM Start emulators in a new window
            start "Firebase Emulators" cmd /c "firebase emulators:start"
            echo [INFO] Waiting for emulators to start...
            timeout /t 15 /nobreak >nul
            
            echo [INFO] Re-checking emulator status...
            set "STILL_ISSUES=0"
            call :check_port_silent "Auth" 9099
            call :check_port_silent "Firestore" 8080
            call :check_port_silent "Functions" 5001
            call :check_port_silent "UI" 4100
            
            if !STILL_ISSUES! gtr 0 (
                echo [WARNING] Some emulators may still be starting up
                echo [INFO] Check Firebase Emulator UI at http://localhost:4100
            ) else (
                echo [SUCCESS] All Firebase emulators started successfully!
            )
        )
    )
) else (
    echo.
    echo [SUCCESS] All Firebase emulators are running!
)

:flutter_setup
REM Check if Flutter is available
echo.
echo [INFO] Checking Flutter installation...
flutter --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter is not installed or not in PATH
    echo [INFO] Please install Flutter: https://docs.flutter.dev/get-started/install
    exit /b 1
)
echo [SUCCESS] Flutter is installed

REM Clean build artifacts
echo.
echo [INFO] Cleaning previous build artifacts...
flutter clean >nul 2>&1
echo [SUCCESS] Build artifacts cleaned

REM Get Flutter dependencies
echo.
echo [INFO] Getting Flutter dependencies...
flutter pub get
if errorlevel 1 (
    echo [ERROR] Failed to get Flutter dependencies
    exit /b 1
)
echo [SUCCESS] Dependencies retrieved successfully

REM Enable web support
echo.
echo [INFO] Ensuring web platform support...
flutter config --enable-web >nul 2>&1
echo [SUCCESS] Web platform configured

REM Deploy Flutter web app
echo.
echo [INFO] Starting Flutter web app in development mode...
echo [INFO] App will be available at: http://localhost:3000
echo [INFO] Firebase Emulator UI available at: http://localhost:4100
echo [INFO] Press Ctrl+C to stop the app
echo.

flutter run -d chrome --web-port 3000 --web-hostname 0.0.0.0
if errorlevel 1 (
    echo [ERROR] Failed to start Flutter web app
    echo [INFO] Troubleshooting:
    echo [INFO]   - Ensure Chrome is installed
    echo [INFO]   - Try: flutter doctor
    echo [INFO]   - Check if port 3000 is available
    exit /b 1
)

echo.
echo [SUCCESS] Deployment script completed
exit /b 0

REM Function to check if a port is in use
:check_port
set "SERVICE_NAME=%~1"
set "PORT=%~2"
set "EMULATOR_ISSUES=0"

netstat -an | findstr ":%PORT% " >nul 2>&1
if errorlevel 1 (
    echo [WARNING] %SERVICE_NAME% emulator NOT running on port %PORT%
    set /a EMULATOR_ISSUES+=1
) else (
    echo [SUCCESS] %SERVICE_NAME% emulator running on port %PORT%
)
exit /b 0

REM Function to check if a port is in use (silent version for re-checking)
:check_port_silent
set "SERVICE_NAME=%~1"
set "PORT=%~2"

netstat -an | findstr ":%PORT% " >nul 2>&1
if errorlevel 1 (
    set /a STILL_ISSUES+=1
) else (
    echo [SUCCESS] %SERVICE_NAME% emulator now running on port %PORT%
)
exit /b 0