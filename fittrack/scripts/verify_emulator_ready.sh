#!/bin/bash
set -e

echo "Verifying Android emulator is fully ready..."

# Wait for device to be online
adb wait-for-device
echo "✓ Device is online"

# Wait for boot to complete
timeout 300 bash -c '
  while [[ "$(adb shell getprop sys.boot_completed)" != "1" ]]; do
    echo "Waiting for boot completion..."
    sleep 2
  done
'
echo "✓ Boot completed"

# Wait for package manager
timeout 60 bash -c '
  while ! adb shell pm list packages >/dev/null 2>&1; do
    echo "Waiting for package manager..."
    sleep 2
  done
'
echo "✓ Package manager ready"

# Wait for system UI
timeout 60 bash -c '
  while ! adb shell dumpsys window | grep -q "mCurrentFocus"; do
    echo "Waiting for system UI..."
    sleep 2
  done
'
echo "✓ System UI ready"

# Verify screen is unlocked
adb shell input keyevent 82
sleep 1
echo "✓ Screen unlocked"

# Final connectivity test
if adb shell echo "test" | grep -q "test"; then
  echo "✓ ADB connection stable"
else
  echo "✗ ADB connection unstable"
  exit 1
fi

echo "✓✓✓ Emulator is fully ready for testing"
