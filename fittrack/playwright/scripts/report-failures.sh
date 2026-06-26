#!/usr/bin/env bash
# report-failures.sh — Posts Playwright E2E results to a PR and escalates failures
# to a single GitHub issue (not one per test).
#
# Usage:
#   bash playwright/scripts/report-failures.sh <pr_number> <run_id> <run_url>
#
# Requires: gh CLI authenticated, jq, RESULTS_FILE (playwright-report/results.json)
#
# Behaviour:
#   - PASS: posts "✅ all tests passed" PR comment, closes any open playwright-failure issue
#   - FAIL: creates/updates ONE issue listing all failing tests; posts "⚠️ N tests failed" PR comment
#   - Always exits 0 (non-blocking)

set -euo pipefail

PR_NUMBER="${1:?PR number required}"
RUN_ID="${2:?Run ID required}"
RUN_URL="${3:?Run URL required}"
# Optional: "success"|"failure"|"cancelled" from ${{ steps.playwright.outcome }}.
# Used to detect a global-setup crash (Playwright exits non-zero but 0 tests ran).
PLAYWRIGHT_OUTCOME="${4:-}"

RESULTS_FILE="playwright/playwright-report/results.json"
LABEL="playwright-failure"

# Ensure we always exit 0 so CI is non-blocking
trap 'exit 0' EXIT ERR

# ─── Check results file ──────────────────────────────────────────────────────
if [ ! -f "$RESULTS_FILE" ]; then
  echo "⚠️  Results file not found at $RESULTS_FILE — skipping report"
  gh pr comment "$PR_NUMBER" \
    --body "⚠️ Playwright E2E: results file not found — [View run]($RUN_URL)" \
    2>/dev/null || true
  exit 0
fi

# ─── Parse results via jq ────────────────────────────────────────────────────
TOTAL=$(jq '.stats.expected // 0' "$RESULTS_FILE")
PASSED=$(jq '.stats.expected // 0' "$RESULTS_FILE")
FAILED=$(jq '.stats.unexpected // 0' "$RESULTS_FILE")
SKIPPED=$(jq '.stats.skipped // 0' "$RESULTS_FILE")

# ─── Detect global-setup / infra crash ───────────────────────────────────────
# When global-setup throws, Playwright exits non-zero but results.json shows
# 0 tests (stats.expected=0). Without this guard the script would report
# "all tests passed" (0 failures = pass) even though nothing ran.
if [ "$PLAYWRIGHT_OUTCOME" = "failure" ] && [ "$TOTAL" -eq 0 ]; then
  echo "⚠️  Playwright crashed before any tests ran (global-setup failure)"

  ISSUE_TITLE="Playwright E2E crash — PR #${PR_NUMBER} run #${RUN_ID}"
  ISSUE_BODY="## Playwright E2E Setup Crash

**PR:** #${PR_NUMBER}
**Run:** [${RUN_ID}](${RUN_URL})
**Result:** Playwright exited non-zero with 0 tests run — likely a \`global-setup\` failure.

### What this means
The test suite crashed before any spec files were executed. Common causes:
- Firebase emulator not reachable
- Auth/Firestore seed data call failed
- TypeScript compile error in \`global-setup.ts\`

### How to investigate
1. Open the run link above and inspect the **Run Playwright E2E tests** step output
2. Look for the first uncaught error in \`global-setup.ts\`
3. Fix the root cause and re-run the workflow

---
*Auto-created by \`playwright/scripts/report-failures.sh\`. Closes automatically when tests run cleanly.*"

  EXISTING_ISSUE=$(gh issue list \
    --label "$LABEL" \
    --state open \
    --search "Playwright E2E crash — PR #${PR_NUMBER}" \
    --json number \
    --jq '.[0].number' 2>/dev/null || echo "")

  if [ -n "$EXISTING_ISSUE" ]; then
    gh issue edit "$EXISTING_ISSUE" --title "$ISSUE_TITLE" --body "$ISSUE_BODY" 2>/dev/null || true
    ISSUE_NUMBER="$EXISTING_ISSUE"
  else
    ISSUE_NUMBER=$(gh issue create \
      --title "$ISSUE_TITLE" \
      --body "$ISSUE_BODY" \
      --label "$LABEL" \
      --label "priority/high" \
      --json number \
      --jq '.number' 2>/dev/null || echo "")
  fi

  if [ -n "$ISSUE_NUMBER" ]; then
    gh pr comment "$PR_NUMBER" \
      --body "⚠️ **Playwright E2E**: test suite crashed before any tests ran — [GitHub Issue #${ISSUE_NUMBER}](../../issues/${ISSUE_NUMBER}) · [View run logs]($RUN_URL)" \
      2>/dev/null || true
  else
    gh pr comment "$PR_NUMBER" \
      --body "⚠️ **Playwright E2E**: test suite crashed before any tests ran — [View run logs]($RUN_URL)" \
      2>/dev/null || true
  fi
  exit 0
fi

# Build a list of failing test names with viewport and status
FAILING_TESTS=$(jq -r '
  .suites[]?
  | .suites[]?
  | . as $suite
  | .specs[]?
  | . as $spec
  | .tests[]?
  | select(.results[0].status != "expected")
  | "- **\($spec.title)** [\($suite.title)] — `\(.results[0].status)`"
' "$RESULTS_FILE" 2>/dev/null || echo "")

# ─── All tests passed ─────────────────────────────────────────────────────────
if [ "$FAILED" -eq 0 ] || [ -z "$FAILING_TESTS" ]; then
  echo "✅ Playwright E2E: all tests passed"

  # Close any existing playwright-failure issue for this PR
  EXISTING_ISSUE=$(gh issue list \
    --label "$LABEL" \
    --state open \
    --search "Playwright E2E failures — PR #${PR_NUMBER}" \
    --json number \
    --jq '.[0].number' 2>/dev/null || echo "")

  if [ -n "$EXISTING_ISSUE" ]; then
    gh issue close "$EXISTING_ISSUE" \
      --comment "✅ Playwright E2E tests are now passing on PR #${PR_NUMBER} (run [#${RUN_ID}]($RUN_URL)). Closing this issue." \
      2>/dev/null || true
    echo "Closed existing failure issue #$EXISTING_ISSUE"
  fi

  gh pr comment "$PR_NUMBER" \
    --body "✅ **Playwright E2E**: all tests passed — [View run & screenshots]($RUN_URL)" \
    2>/dev/null || true
  exit 0
fi

# ─── Tests failed ────────────────────────────────────────────────────────────
echo "⚠️  Playwright E2E: $FAILED test(s) failed"

ISSUE_TITLE="Playwright E2E failures — PR #${PR_NUMBER} run #${RUN_ID}"

ISSUE_BODY="## Playwright E2E Test Failures

**PR:** #${PR_NUMBER}
**Run:** [${RUN_ID}](${RUN_URL})
**Failed:** ${FAILED} test(s)

### Failing Tests

${FAILING_TESTS}

### Screenshots

Screenshots are available in the **playwright-screenshots** artifact:
[View artifacts](${RUN_URL})

### How to fix

1. Click the run link above to view Playwright HTML report
2. Download the \`playwright-screenshots\` artifact for visual inspection
3. Re-run the workflow after fixing to close this issue automatically

---
*Auto-created by \`playwright/scripts/report-failures.sh\`. Closes automatically when all tests pass.*"

# Find an existing open failure issue for this PR
EXISTING_ISSUE=$(gh issue list \
  --label "$LABEL" \
  --state open \
  --search "Playwright E2E failures — PR #${PR_NUMBER}" \
  --json number \
  --jq '.[0].number' 2>/dev/null || echo "")

if [ -n "$EXISTING_ISSUE" ]; then
  # Update existing issue with new run details
  gh issue edit "$EXISTING_ISSUE" \
    --title "$ISSUE_TITLE" \
    --body "$ISSUE_BODY" \
    2>/dev/null || true
  ISSUE_NUMBER="$EXISTING_ISSUE"
  echo "Updated existing failure issue #$ISSUE_NUMBER"
else
  # Create new issue
  ISSUE_NUMBER=$(gh issue create \
    --title "$ISSUE_TITLE" \
    --body "$ISSUE_BODY" \
    --label "$LABEL" \
    --label "priority/high" \
    --json number \
    --jq '.number' 2>/dev/null || echo "")
  echo "Created failure issue #$ISSUE_NUMBER"
fi

# Post PR comment with link to issue and artifact
if [ -n "$ISSUE_NUMBER" ]; then
  PR_COMMENT="⚠️ **Playwright E2E**: ${FAILED} test(s) failed — [GitHub Issue #${ISSUE_NUMBER}](../../issues/${ISSUE_NUMBER}) · [View screenshots & report]($RUN_URL)"
else
  PR_COMMENT="⚠️ **Playwright E2E**: ${FAILED} test(s) failed — [View screenshots & report]($RUN_URL)"
fi

gh pr comment "$PR_NUMBER" \
  --body "$PR_COMMENT" \
  2>/dev/null || true
