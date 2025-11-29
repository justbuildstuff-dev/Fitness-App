# Flaky Android Emulator CI Fix - Technical Design

**Version:** 1.0
**Date:** 2025-11-26
**Status:** Ready for Implementation
**GitHub Issue:** [#29](https://github.com/justbuildstuff-dev/Fitness-App/issues/29)
**Notion PRD:** [Fix Flaky CI/CD Integration Tests on Android Emulator](https://www.notion.so/Fix-Flaky-CI-CD-Integration-Tests-on-Android-Emulator-298879be578981068afdee212b59a4bb)
**Priority:** Medium (High Impact on Developer Experience)
**Type:** Infrastructure / CI/CD Reliability

---

## Problem Statement

Integration tests running on Android emulator in GitHub Actions CI fail intermittently despite:
- Unit tests passing (code correctness verified)
- Widget tests passing (UI correctness verified)
- Performance tests passing
- Code changes being unrelated to integration test failures
- No integration test code being modified

**Impact:**
- Slows down PR merges - requires manual overrides or retries
- Reduces confidence in CI reliability
- May mask real integration test failures
- Blocked critical fixes like #27 (app startup hang)

**Example:** PR #28 changed only ThemeProvider (synchronous fix), yet integration tests failed while all other tests passed.

---

## Current Implementation Analysis

### CI Configuration

**File:** `.github/workflows/fittrack_test_suite.yml` (Lines 113-310)

**Current Setup:**
```yaml
integration-tests:
  runs-on: ubuntu-latest
  timeout-minutes: 60
  steps:
    - name: Set up Android emulator
      uses: reactivecircus/android-emulator-runner@v2
      with:
        api-level: 29
        target: google_apis
        arch: x86_64
        profile: pixel_2
        ram-size: 1536M
        heap-size: 256M
        disk-size: 2048M

    - name: Run integration tests
      timeout-minutes: 15
      run: |
        flutter test integration_test/analytics_integration_test.dart
        flutter test integration_test/workout_creation_integration_test.dart
        flutter test integration_test/enhanced_complete_workflow_test.dart
```

**Test Files:**
- `fittrack/integration_test/analytics_integration_test.dart`
- `fittrack/integration_test/workout_creation_integration_test.dart`
- `fittrack/integration_test/enhanced_complete_workflow_test.dart`

---

## Root Cause Analysis

Android emulator in GitHub Actions suffers from known infrastructure issues:

### 1. Emulator Startup Flakiness
- Emulator may not fully initialize before tests run
- System services (SurfaceFlinger, PackageManager) may not be ready
- ADB connection may be unstable

### 2. Resource Constraints
- GitHub Actions runners have limited resources:
  - CPU: Shared 2-core
  - RAM: 7GB total, 1.5GB allocated to emulator
  - Disk: 14GB available, 2GB allocated to emulator
- Emulator startup and test execution compete for resources

### 3. Network Timing Issues
- Firebase emulator connection failures
- Localhost communication delays between app and emulators
- TCP socket timeout issues

### 4. Test Timeout Issues
- Current timeout: 900s (15 minutes) per test
- Some tests fail due to slow emulator startup, not test failure
- No distinction between infrastructure timeout vs test failure

---

## Proposed Solution

Implement a **two-tier approach**: short-term stability improvements + long-term infrastructure migration.

### Architecture Overview

**Short-Term (Immediate - 1-2 weeks):**
- Add automatic retry logic for flaky tests
- Improve emulator health checks before test execution
- Increase timeouts appropriately
- Make integration tests advisory (non-blocking)
- Add clear failure classification (infrastructure vs code)

**Long-Term (3-6 months):**
- Migrate to Firebase Test Lab or similar device farm
- Optimize emulator configuration
- Add test stability metrics and monitoring
- Consider alternative testing strategies

---

## Detailed Design

### Short-Term Solution

#### 1. Automatic Retry Logic

**File:** `.github/workflows/fittrack_test_suite.yml`

**Current:**
```yaml
- name: Run integration tests
  run: flutter test integration_test/analytics_integration_test.dart
```

**Proposed:**
```yaml
- name: Run integration tests with retry
  uses: nick-fields/retry@v2
  with:
    timeout_minutes: 15
    max_attempts: 2
    retry_wait_seconds: 30
    command: |
      cd fittrack
      flutter test integration_test/analytics_integration_test.dart
      flutter test integration_test/workout_creation_integration_test.dart
      flutter test integration_test/enhanced_complete_workflow_test.dart
    on_retry_command: |
      echo "::warning::Integration test failed, retrying once..."
```

**Rationale:** Single retry catches transient infrastructure failures without hiding persistent bugs.

#### 2. Enhanced Health Checks

**Add pre-test verification script:**

**File:** `fittrack/scripts/verify_emulator_ready.sh` (NEW)

```bash
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
```

**Workflow Integration:**
```yaml
- name: Verify emulator ready
  run: |
    chmod +x fittrack/scripts/verify_emulator_ready.sh
    ./fittrack/scripts/verify_emulator_ready.sh
```

#### 3. Increased Timeouts with Better Reporting

```yaml
- name: Run integration tests
  timeout-minutes: 20  # Increased from 15
  id: integration_tests
  continue-on-error: true  # Don't fail workflow immediately
  run: |
    cd fittrack
    flutter test integration_test/ --timeout=10m
```

#### 4. Make Integration Tests Advisory

```yaml
- name: Check integration test results
  if: steps.integration_tests.outcome == 'failure'
  run: |
    if [[ "${{ steps.unit_tests.outcome }}" == "success" ]] && \
       [[ "${{ steps.widget_tests.outcome }}" == "success" ]]; then
      echo "::warning::Integration tests failed, but unit and widget tests passed."
      echo "::warning::This may be due to CI infrastructure. Review logs carefully."
      echo "::warning::PR can proceed if code review confirms changes are safe."
      exit 0  # Don't block PR
    else
      echo "::error::Multiple test suites failing - likely a code issue"
      exit 1  # Block PR
    fi
```

#### 5. Clear Failure Classification

**Add failure analysis step:**

```yaml
- name: Analyze integration test failure
  if: steps.integration_tests.outcome == 'failure'
  run: |
    echo "Analyzing failure type..."

    # Check for known infrastructure failures
    if grep -q "Failed to install" test-results.log; then
      echo "::warning::INFRASTRUCTURE FAILURE: APK installation issue"
    elif grep -q "Timed out" test-results.log; then
      echo "::warning::INFRASTRUCTURE FAILURE: Timeout (likely emulator slowness)"
    elif grep -q "Connection refused" test-results.log; then
      echo "::warning::INFRASTRUCTURE FAILURE: Network/emulator connection issue"
    else
      echo "::error::TEST FAILURE: Appears to be code-related, review carefully"
    fi
```

---

### Long-Term Solution

#### Option A: Firebase Test Lab (Recommended)

**Advantages:**
- Real devices (not emulators)
- Reliable infrastructure
- Parallel execution across multiple devices
- Built-in screenshots and video recordings
- Better debugging tools

**Implementation:**
```yaml
- name: Run tests on Firebase Test Lab
  uses: google-github-actions/setup-gcloud@v1
  with:
    service_account_key: ${{ secrets.FIREBASE_SA_KEY }}

- name: Execute tests
  run: |
    gcloud firebase test android run \
      --type instrumentation \
      --app fittrack/build/app/outputs/apk/debug/app-debug.apk \
      --test fittrack/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
      --device model=Pixel2,version=29,locale=en,orientation=portrait \
      --timeout 15m
```

**Cost:** ~$5-15/month for typical usage

#### Option B: Optimized Emulator Configuration

**Increase resources:**
```yaml
- name: Set up emulator
  uses: reactivecircus/android-emulator-runner@v2
  with:
    api-level: 29
    target: google_apis
    arch: x86_64
    profile: pixel_2
    ram-size: 2048M      # Increased from 1536M
    heap-size: 512M      # Increased from 256M
    disk-size: 4096M     # Increased from 2048M
    cores: 2             # Explicit core allocation
    emulator-options: -no-window -gpu swiftshader_indirect -noaudio -no-boot-anim
```

#### Option C: Separate CI Platform

**Use dedicated CI for integration tests:**
- CircleCI (better Android emulator support)
- Bitrise (specialized for mobile)
- Self-hosted runner with hardware acceleration

---

## Implementation Tasks

### Phase 1: Immediate Stability (Week 1)

#### Task #1: Add Retry Logic to Integration Tests
**Estimated:** 2 hours

**Changes:**
- Modify `.github/workflows/fittrack_test_suite.yml`
- Add `nick-fields/retry@v2` action
- Configure 2 attempts with 30s wait
- Add warning messages for retries

**Testing:**
- Trigger CI on test PR
- Verify retry happens on simulated failure
- Confirm retry logs are clear

#### Task #2: Create Emulator Health Check Script
**Estimated:** 3 hours

**Changes:**
- Create `fittrack/scripts/verify_emulator_ready.sh`
- Implement boot completion check
- Implement package manager check
- Implement system UI check
- Add ADB stability verification

**Testing:**
- Run script locally against emulator
- Verify all checks pass
- Test timeout handling

#### Task #3: Integrate Health Check into Workflow
**Estimated:** 1 hour

**Changes:**
- Add health check step before test execution
- Make executable with chmod
- Add proper error handling

**Testing:**
- Verify health check runs in CI
- Confirm tests only start after checks pass

#### Task #4: Make Integration Tests Advisory
**Estimated:** 2 hours

**Changes:**
- Add `continue-on-error: true` to integration test step
- Add conditional check step
- Distinguish infrastructure failures from code failures
- Update PR merge requirements

**Testing:**
- Simulate failing integration tests
- Verify unit/widget test passing allows PR
- Confirm warnings are clear

### Phase 2: Enhanced Monitoring (Week 2)

#### Task #5: Add Failure Classification Logic
**Estimated:** 2 hours

**Changes:**
- Add failure analysis script
- Pattern match known infrastructure failures
- Generate appropriate warnings/errors
- Log failure types for metrics

**Testing:**
- Test against historical failure logs
- Verify classification accuracy

#### Task #6: Increase Timeouts and Resources
**Estimated:** 1 hour

**Changes:**
- Increase job timeout to 20 minutes
- Increase test timeout to 10 minutes
- Adjust emulator RAM/disk if needed

**Testing:**
- Monitor test execution times
- Ensure no premature timeouts

### Phase 3: Documentation (Week 2)

#### Task #7: Document CI Behavior and Workarounds
**Estimated:** 2 hours

**Changes:**
- Update project README with CI notes
- Document how to interpret integration test failures
- Add troubleshooting guide
- Document manual override process

**Deliverables:**
- `Docs/Process/CI_Integration_Tests_Guide.md`

---

## Testing Strategy

### Unit Tests
- Test health check script logic (mock adb commands)
- Test failure classification patterns
- **Coverage Target:** Not applicable (infrastructure scripts)

### Integration Tests
- Run full CI workflow on test PR
- Simulate various failure scenarios
- Verify retry logic works correctly
- Confirm advisory mode allows PR when appropriate

### Manual Verification
- Monitor CI behavior over 1 week
- Track retry success rate
- Verify no real test failures are masked
- Collect metrics on failure types

---

## Success Metrics

**Short-Term Goals:**
- ✅ Integration tests automatically retry once if they fail
- ✅ Emulator health check verifies readiness before tests
- ✅ Integration test failures don't block PR when unit/widget tests pass
- ✅ CI clearly indicates infrastructure failures vs code failures
- ✅ Reduced manual PR overrides (target: 80% reduction)

**Long-Term Goals:**
- ✅ Test flakiness rate below 5% (95% success on unchanged code)
- ✅ Integration tests run on reliable infrastructure
- ✅ Metrics dashboard tracks test stability over time
- ✅ Average PR merge time reduced by 50%

**Monitoring:**
- Track integration test pass rate weekly
- Log failure classification breakdown
- Monitor PR merge times
- Survey developer sentiment on CI reliability

---

## Risks & Mitigation

### Risk 1: Retry Logic Masks Real Bugs
**Likelihood:** Medium
**Impact:** High
**Mitigation:**
- Only retry once
- Log all retries as warnings
- Weekly review of retry patterns
- If test fails twice, it's a real failure

### Risk 2: Health Checks Add Significant Time
**Likelihood:** Low
**Impact:** Medium
**Mitigation:**
- Health checks timeout after 5 minutes total
- Most checks complete in 30-60 seconds
- Time added is less than time lost to false failures

### Risk 3: Advisory Mode Allows Broken Code
**Likelihood:** Low
**Impact:** High
**Mitigation:**
- Only advisory when unit + widget tests pass
- Manual code review still required
- Post-merge device testing catches issues
- QA testing validates before production

### Risk 4: Long-Term Solution Delayed
**Likelihood:** Medium
**Impact:** Medium
**Mitigation:**
- Short-term solution provides immediate relief
- Track metrics to justify long-term investment
- Evaluate options quarterly

---

## Rollback Plan

If short-term changes cause issues:

1. **Remove retry logic:**
   ```yaml
   # Revert to direct test execution
   - name: Run integration tests
     run: flutter test integration_test/
   ```

2. **Disable advisory mode:**
   ```yaml
   # Remove continue-on-error
   - name: Run integration tests
     continue-on-error: false
   ```

3. **Keep health checks** - These are low-risk and improve reliability

**Rollback Time:** < 1 hour (simple workflow edit)

---

## Future Enhancements

**Considered for Future Iterations:**

1. **Test Sharding** - Split integration tests across parallel jobs
2. **Snapshot Testing** - Pre-warmed emulator snapshots for faster startup
3. **Local Integration Test Script** - Developers can run same tests locally
4. **Metrics Dashboard** - Visual tracking of CI stability over time
5. **Automatic Issue Creation** - Bot creates issues for persistent failures

---

## Related Issues

- **#27** - Critical bug fix blocked by flaky CI
- **#28** - PR merged despite integration test failure (workaround used)
- **#123** - False pass integration tests (separate but related CI issue)

---

## References

- **Notion PRD:** https://www.notion.so/Fix-Flaky-CI-CD-Integration-Tests-on-Android-Emulator-298879be578981068afdee212b59a4bb
- **GitHub Issue:** https://github.com/justbuildstuff-dev/Fitness-App/issues/29
- **Workflow File:** `.github/workflows/fittrack_test_suite.yml`
- **Similar Fix Example:** Login_Data_Loading_Fix_Technical_Design.md (infrastructure/timing fix)

---

**Document Status:** ✅ Ready for implementation
**Next Step:** Create task issues and bug branch
**Estimated Total Effort:** 13 hours (2 weeks part-time)
