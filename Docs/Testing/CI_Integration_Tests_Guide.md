# CI Integration Tests Guide

## Overview

This guide explains how to interpret CI integration test results, understand test failures, and work around known infrastructure issues.

**Last Updated:** 2025-12-30
**Related Issues:** [#29 - Flaky Android Emulator CI](https://github.com/justbuildstuff-dev/Fitness-App/issues/29)

---

## CI Test Jobs Overview

The FitTrack CI pipeline runs multiple test suites in parallel:

| Job Name | Test Type | Speed | Reliability | Blocks PR? |
|----------|-----------|-------|-------------|------------|
| Unit Tests (Business Logic) | Unit | Fast (2-3 min) | ✅ Reliable | Yes |
| Widget Tests (UI Components) | Widget | Fast (2-3 min) | ✅ Reliable | Yes |
| Integration Tests (Firebase Emulators) | Integration | Medium (3-5 min) | ✅ Reliable | Yes |
| E2E Tests (Android Emulator) | E2E | Slow (20-60 min) | ⚠️  Flaky | Advisory* |
| Performance Tests (Edge Cases) | Performance | Fast (1-2 min) | ✅ Reliable | Yes |

**Advisory Mode:** E2E tests on Android emulator are currently advisory (non-blocking) when unit and widget tests pass. See [Advisory Mode](#advisory-mode) section below.

---

## Advisory Mode

### What is Advisory Mode?

**Advisory mode** means integration tests can fail WITHOUT blocking PR merge, but ONLY under specific conditions:

**Conditions for Advisory Mode:**
1. ✅ Unit tests passed
2. ✅ Widget tests passed
3. ❌ E2E tests (Android emulator) failed

**When this happens:**
- PR is NOT automatically blocked
- CI shows ⚠️  warning instead of ❌ failure
- Manual code review is still required
- Developer should review test logs to confirm it's infrastructure-related

### Why Advisory Mode?

Android emulator integration tests in GitHub Actions suffer from known infrastructure flakiness:
- Emulator startup timing issues
- Resource constraints on CI runners
- Network connectivity issues between emulator and Firebase emulators
- Slow APK installation on emulator

When unit and widget tests pass, it indicates the code is correct - the E2E failure is likely infrastructure-related, not a code bug.

### When is it NOT Advisory?

Integration tests are **BLOCKING** (not advisory) when:
- Unit tests failed + E2E tests failed (likely code issue)
- Widget tests failed + E2E tests failed (likely code issue)
- Integration tests (Firebase Emulators) failed (always blocking)

---

## Test Failure Types

### 1. Infrastructure Failures (Non-Blocking with Advisory Mode)

**Characteristics:**
- E2E tests fail on Android emulator
- Unit and widget tests pass
- Error messages contain infrastructure keywords

**Common Error Patterns:**
```
Failed to install APK
Emulator boot timeout
Connection refused (10.0.2.2:8080)
ADB connection lost
Gradle download timeout
NDK download timeout
```

**What to do:**
1. ✅ Review test logs to confirm it's infrastructure-related
2. ✅ Check if error matches known patterns above
3. ✅ Wait for automatic retry (tests retry once automatically)
4. ✅ If retry passes, PR can proceed
5. ✅ If retry fails with same infrastructure error, manual override okay with reviewer approval

### 2. Code Failures (Always Blocking)

**Characteristics:**
- Unit tests failed
- Widget tests failed
- Integration tests (Firebase Emulators) failed
- Multiple test suites failing

**Common Error Patterns:**
```
Test assertion failed
Expected X but got Y
Null check operator used on null value
Type 'X' is not a subtype of type 'Y'
Provider not found
```

**What to do:**
1. ❌ **DO NOT merge** until fixed
2. 🔍 Review test failure logs
3. 🛠️  Fix the failing code
4. 🔄 Push fix and wait for tests to pass
5. ✅ Only merge when all blocking tests pass

### 3. Mixed Failures (Use Judgment)

**Characteristics:**
- Some unit/widget tests pass, some fail
- E2E tests also fail
- Unclear if infrastructure or code issue

**What to do:**
1. 🔍 Review ALL test logs carefully
2. 🤔 Determine root cause (infrastructure vs code)
3. 🛠️  Fix any code issues first
4. 🔄 Re-run tests
5. 💬 Discuss with team if unsure

---

## Interpreting Test Results

### Flowchart

```
┌─────────────────────────────────┐
│   CI Tests Complete             │
└────────────┬────────────────────┘
             │
             ▼
       All tests pass?
             │
      ┌──────┴──────┐
      │YES          NO│
      │             │
      ▼             ▼
   ✅ MERGE    Which tests failed?
   APPROVED      │
              ┌──┴──────────────────────────┐
              │                              │
              ▼                              ▼
        Unit/Widget/                    Only E2E
        Integration                     (Android)
        Failed                          Failed
              │                              │
              ▼                              ▼
         ❌ BLOCKED                    Unit+Widget
         FIX CODE                      Passed?
                                            │
                                     ┌──────┴──────┐
                                     │YES         NO│
                                     │             │
                                     ▼             ▼
                               ⚠️  ADVISORY    ❌ BLOCKED
                               Check logs    FIX CODE
                               Review errors
                               Manual approval
```

### Quick Reference

| Unit | Widget | Integration | E2E | Result | Action |
|------|--------|-------------|-----|--------|--------|
| ✅ | ✅ | ✅ | ✅ | ✅ Pass | Merge approved |
| ✅ | ✅ | ✅ | ❌ | ⚠️  Advisory | Review logs, likely infrastructure |
| ✅ | ✅ | ❌ | ❌ | ❌ Blocked | Fix integration tests |
| ✅ | ❌ | ✅ | ❌ | ❌ Blocked | Fix widget tests |
| ❌ | ✅ | ✅ | ❌ | ❌ Blocked | Fix unit tests |
| ❌ | ❌ | ❌ | ❌ | ❌ Blocked | Fix all code issues |

---

## Troubleshooting Common Issues

### E2E Tests Timeout

**Symptom:** E2E tests fail with timeout after 40+ minutes

**Causes:**
- Slow emulator startup
- Gradle/NDK download delays
- Emulator resource constraints

**Solutions:**
1. Wait for automatic retry (happens automatically)
2. Check if retry passes
3. If persistent, may need manual review

### E2E Tests "Connection Refused"

**Symptom:** Tests fail with `Connection refused` to `10.0.2.2:8080` or `10.0.2.2:9099`

**Causes:**
- Firebase emulators not started
- Emulator can't reach host machine
- Port forwarding issues

**Solutions:**
1. Check emulator health check step passed
2. Verify Firebase emulators started correctly
3. Wait for retry

### APK Installation Failure

**Symptom:** `Failed to install APK on emulator`

**Causes:**
- Emulator disk space full
- Emulator not fully ready
- ADB connection unstable

**Solutions:**
1. Health check script should catch this
2. Automatic retry should resolve
3. If persistent, infrastructure issue

### All Tests Fail

**Symptom:** Unit, widget, integration, AND E2E all fail

**Causes:**
- Actual code bug
- Breaking change introduced
- Dependencies broken

**Solutions:**
1. ❌ **DO NOT use advisory mode**
2. Review code changes carefully
3. Fix the breaking change
4. Run tests locally if possible
5. Push fix and re-test

---

## Manual Override Process

### When to Override

Use manual override **ONLY** when:
1. ✅ E2E tests failed with infrastructure error
2. ✅ Unit and widget tests passed
3. ✅ Error matches known infrastructure patterns
4. ✅ Code review confirms changes are safe
5. ✅ Team lead or reviewer approves

### When NOT to Override

**NEVER** override when:
- ❌ Unit tests failed
- ❌ Widget tests failed
- ❌ Integration tests (Firebase Emulators) failed
- ❌ Error messages indicate code issues
- ❌ Multiple test suites failing
- ❌ Changes affect critical paths (auth, data loss scenarios)

### How to Override

1. **Review test logs thoroughly**
2. **Confirm error matches infrastructure patterns**
3. **Get reviewer approval**
4. **Add comment to PR explaining override decision**
5. **Merge with reviewer approval**

**Example PR Comment:**
```
E2E tests failed with known infrastructure issue (APK installation timeout).
Unit tests: ✅ Pass
Widget tests: ✅ Pass
Integration tests: ✅ Pass

Error matches pattern: "Failed to install APK"
Retry also failed with same infrastructure error.

Code review confirmed changes are safe.
Merging with manual override.
```

---

## Best Practices

### For Developers

1. **Always review test logs** - Don't assume failures are infrastructure
2. **Check multiple test suites** - If only E2E fails, likely infrastructure
3. **Fix code issues first** - Never ignore failing unit/widget tests
4. **Use advisory mode responsibly** - Get reviewer approval for overrides
5. **Report persistent issues** - If E2E fails repeatedly, file issue

### For Reviewers

1. **Verify test logs** - Confirm infrastructure vs code failure
2. **Check error patterns** - Match against known infrastructure issues
3. **Review code changes** - Ensure changes are safe despite E2E failure
4. **Use judgment** - If unsure, ask for re-run or fixes
5. **Document decisions** - Add comments explaining override approval

---

## CI Improvements Roadmap

### Current State (Phase 1)
- ✅ Automatic retry logic (max 2 attempts)
- ✅ Emulator health checks
- ✅ Increased timeouts
- ✅ Advisory mode for E2E tests
- ✅ Failure classification

### Future Improvements (Phase 2)
- 🔄 Migrate to Firebase Test Lab (more reliable)
- 🔄 Optimize emulator configuration
- 🔄 Add test stability metrics
- 🔄 Implement automatic issue creation for persistent failures

**See Issue #29 for detailed roadmap**

---

## FAQ

### Q: Why do E2E tests fail so often?

A: GitHub Actions Android emulator has known reliability issues. We've implemented retry logic, health checks, and advisory mode to work around this while we plan migration to Firebase Test Lab.

### Q: Can I merge if E2E tests fail?

A: Yes, IF:
- Unit and widget tests pass
- Error is infrastructure-related
- Code review approves
- You understand advisory mode criteria

### Q: Should I re-run failed tests?

A: Tests automatically retry once. If retry also fails, review logs before manual re-run.

### Q: How do I know if it's infrastructure vs code issue?

A: Check error messages against patterns in [Test Failure Types](#test-failure-types) section. When in doubt, ask for review.

### Q: What if tests pass locally but fail in CI?

A: Could be environment differences. Check:
- Flutter version matches CI (3.35.1)
- Dependencies are up to date
- Emulators configured correctly

---

## Related Documentation

- [Test Classification Guide](../Testing/TestClassification.md)
- [Testing Framework](../Testing/TestingFramework.md)
- [GitHub Issue #29 - Flaky Android Emulator CI](https://github.com/justbuildstuff-dev/Fitness-App/issues/29)
- [Technical Design - Flaky Android Emulator CI Fix](../Technical_Designs/Flaky_Android_Emulator_CI_Fix_Technical_Design.md)

---

**Questions or Issues?**
File an issue in GitHub or reach out to the development team.
