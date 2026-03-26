#!/bin/bash
# Run all E2E integration test suites independently and collect results.
# Each suite runs regardless of whether previous suites failed.
#
# Usage: run_integration_tests.sh [analytics_timeout] [workout_timeout] [complete_timeout] [cascade_timeout]
# Defaults: 2400 1200 1200 1200

ANALYTICS_TIMEOUT="${1:-2400}"
WORKOUT_TIMEOUT="${2:-1200}"
COMPLETE_TIMEOUT="${3:-1200}"
CASCADE_TIMEOUT="${4:-1200}"

FITTRACK_DIR="${GITHUB_WORKSPACE}/fittrack"
OUTPUT_LOG="/tmp/integration_test_output.log"
FAILED=0

echo "" > "$OUTPUT_LOG"

run_suite() {
  local name="$1"
  local secs="$2"
  local target="$3"
  local log="/tmp/suite_${name}.log"

  echo "=== Running ${name} (timeout ${secs}s) ==="
  (
    cd "$FITTRACK_DIR" || exit 1
    timeout "$secs" flutter drive \
      --driver=test_driver/integration_test.dart \
      --target="$target" \
      --device-id=emulator-5554
  ) > "$log" 2>&1
  local rc=$?

  cat "$log" 2>/dev/null || true
  cat "$log" >> "$OUTPUT_LOG" 2>/dev/null || true
  echo "--- ${name} exit: ${rc} ---"

  [ $rc -ne 0 ] && FAILED=$((FAILED + 1))
}

echo "Running integration tests on Android with flutter drive..."

run_suite "analytics"         "$ANALYTICS_TIMEOUT" "integration_test/analytics_integration_test.dart"
run_suite "workout_creation"  "$WORKOUT_TIMEOUT"   "integration_test/workout_creation_integration_test.dart"
run_suite "complete_workflow" "$COMPLETE_TIMEOUT"  "integration_test/enhanced_complete_workflow_test.dart"
run_suite "cascade_delete"    "$CASCADE_TIMEOUT"   "integration_test/firestore_cascade_delete_integration_test.dart"

cp "$OUTPUT_LOG" /tmp/last_test_output.log
echo "=== Combined result: ${FAILED} suite(s) failed ==="

if [ $FAILED -ne 0 ]; then
  echo "One or more test suites FAILED"
  exit 1
fi

echo "All test suites PASSED"
