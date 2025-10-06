# Local Flutter Web Deployment Script with Firebase Emulator Check
# This script checks if Firebase emulators are running and deploys the Flutter app in web mode

param(
    [switch]$SkipEmulatorCheck,
    [switch]$Help
)

if ($Help) {
    Write-Host @"
Local Flutter Web Deployment Script

Usage: .\deploy-local.ps1 [OPTIONS]

Options:
  -SkipEmulatorCheck    Skip checking if Firebase emulators are running
  -Help                 Show this help message

Description:
This script checks if Firebase emulators are running on configured ports,
then deploys the Flutter app locally in web mode for testing.

Configured emulator ports (from firebase.json):
- Auth: 9099
- Firestore: 8080  
- Functions: 5001
- UI: 4100
"@
    exit 0
}

# Color functions for better output
function Write-Success { param($Message) Write-Host $Message -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host $Message -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host $Message -ForegroundColor Red }
function Write-Info { param($Message) Write-Host $Message -ForegroundColor Cyan }

# Configuration from firebase.json
$EmulatorPorts = @{
    "Auth" = 9099
    "Firestore" = 8080
    "Functions" = 5001
    "UI" = 4100
}

# Function to check if a port is in use
function Test-Port {
    param([int]$Port)
    try {
        $connection = Test-NetConnection -ComputerName localhost -Port $Port -WarningAction SilentlyContinue
        return $connection.TcpTestSucceeded
    }
    catch {
        return $false
    }
}

# Function to check Firebase emulators
function Test-FirebaseEmulators {
    Write-Info "🔍 Checking Firebase emulators status..."
    
    $runningEmulators = @()
    $notRunningEmulators = @()
    
    foreach ($emulator in $EmulatorPorts.GetEnumerator()) {
        $name = $emulator.Key
        $port = $emulator.Value
        
        if (Test-Port -Port $port) {
            $runningEmulators += "$name (port $port)"
            Write-Success "  ✅ $name emulator running on port $port"
        }
        else {
            $notRunningEmulators += "$name (port $port)"
            Write-Warning "  ⚠️  $name emulator NOT running on port $port"
        }
    }
    
    if ($notRunningEmulators.Count -gt 0) {
        Write-Warning "`n⚠️  Some Firebase emulators are not running:"
        $notRunningEmulators | ForEach-Object { Write-Warning "  - $_" }
        Write-Info "`n💡 Would you like to start the Firebase emulators automatically?"
        
        $response = Read-Host "Start Firebase emulators? (Y/n)"
        if ($response -eq 'n' -or $response -eq 'N') {
            $continueResponse = Read-Host "Continue with Flutter deployment without emulators? (y/N)"
            if ($continueResponse -ne 'y' -and $continueResponse -ne 'Y') {
                Write-Error "❌ Deployment cancelled"
                exit 1
            }
        }
        else {
            Write-Info "🚀 Starting Firebase emulators..."
            try {
                # Start emulators in background
                Start-Process -FilePath "firebase" -ArgumentList "emulators:start" -WindowStyle Minimized
                Write-Info "⏳ Waiting for emulators to start..."
                Start-Sleep -Seconds 10
                
                # Re-check emulators
                Write-Info "🔄 Re-checking emulator status..."
                $stillNotRunning = @()
                foreach ($emulator in $EmulatorPorts.GetEnumerator()) {
                    $name = $emulator.Key
                    $port = $emulator.Value
                    
                    if (-not (Test-Port -Port $port)) {
                        $stillNotRunning += "$name (port $port)"
                    }
                    else {
                        Write-Success "  ✅ $name emulator now running on port $port"
                    }
                }
                
                if ($stillNotRunning.Count -gt 0) {
                    Write-Warning "⚠️  Some emulators still not running after start attempt:"
                    $stillNotRunning | ForEach-Object { Write-Warning "  - $_" }
                    Write-Info "💡 They may still be starting up. Check Firebase Emulator UI at http://localhost:4100"
                }
                else {
                    Write-Success "✅ All Firebase emulators started successfully!"
                }
            }
            catch {
                Write-Error "❌ Failed to start Firebase emulators: $($_.Exception.Message)"
                Write-Info "💡 Please start them manually: firebase emulators:start"
                
                $continueResponse = Read-Host "Continue with Flutter deployment anyway? (y/N)"
                if ($continueResponse -ne 'y' -and $continueResponse -ne 'Y') {
                    Write-Error "❌ Deployment cancelled"
                    exit 1
                }
            }
        }
    }
    else {
        Write-Success "`n✅ All Firebase emulators are running!"
    }
}

# Main execution
Write-Info "🚀 Starting local Flutter web deployment..."

# Change to fittrack directory
$fittrackPath = Join-Path $PSScriptRoot "fittrack"
if (-not (Test-Path $fittrackPath)) {
    Write-Error "❌ fittrack directory not found at: $fittrackPath"
    exit 1
}

Set-Location $fittrackPath
Write-Info "📁 Changed to directory: $fittrackPath"

# Check Firebase emulators unless skipped
if (-not $SkipEmulatorCheck) {
    Test-FirebaseEmulators
}
else {
    Write-Warning "⏭️  Skipping Firebase emulator check"
}

# Check if Flutter is available
Write-Info "`n🔍 Checking Flutter installation..."
try {
    $flutterVersion = flutter --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✅ Flutter is installed"
    }
    else {
        throw "Flutter command failed"
    }
}
catch {
    Write-Error "❌ Flutter is not installed or not in PATH"
    Write-Info "💡 Please install Flutter: https://docs.flutter.dev/get-started/install"
    exit 1
}

# Clean build artifacts
Write-Info "`n🧹 Cleaning previous build artifacts..."
try {
    flutter clean | Out-Null
    Write-Success "✅ Build artifacts cleaned"
}
catch {
    Write-Warning "⚠️  Could not clean build artifacts, continuing..."
}

# Get Flutter dependencies
Write-Info "`n📦 Getting Flutter dependencies..."
try {
    flutter pub get
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✅ Dependencies retrieved successfully"
    }
    else {
        throw "pub get failed"
    }
}
catch {
    Write-Error "❌ Failed to get Flutter dependencies"
    exit 1
}

# Check for web platform support
Write-Info "`n🌐 Checking web platform support..."
try {
    $devices = flutter devices --machine | ConvertFrom-Json
    $webDevice = $devices | Where-Object { $_.id -eq "chrome" -or $_.category -eq "web" }
    
    if ($webDevice) {
        Write-Success "✅ Web platform supported"
    }
    else {
        Write-Warning "⚠️  Web platform may not be available"
        Write-Info "💡 Enable web support with: flutter config --enable-web"
        
        # Try to enable web support
        flutter config --enable-web | Out-Null
        Write-Info "✅ Attempted to enable web support"
    }
}
catch {
    Write-Warning "⚠️  Could not verify web platform support, continuing..."
}

# Deploy Flutter web app
Write-Info "`n🚀 Starting Flutter web app in development mode..."
Write-Info "📱 App will be available at: http://localhost:3000"
Write-Info "🔥 Firebase Emulator UI available at: http://localhost:4100"
Write-Info "⏹️  Press Ctrl+C to stop the app"

try {
    # Use --web-port to specify port 3000 for consistency
    flutter run -d chrome --web-port 3000 --web-hostname 0.0.0.0
}
catch {
    Write-Error "❌ Failed to start Flutter web app"
    Write-Info "💡 Troubleshooting:"
    Write-Info "  - Ensure Chrome is installed"
    Write-Info "  - Try: flutter doctor"
    Write-Info "  - Check if port 3000 is available"
    exit 1
}

Write-Info "`n✅ Deployment script completed"