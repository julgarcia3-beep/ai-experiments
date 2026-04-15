#!/usr/bin/env bash
# test_scanner.sh — Integration tests for scanner.sh
#
# Stubs the `claude` command so the full scanner runs end-to-end without
# the real research-loop pipeline. Validates tag extraction, context routing,
# deduplication, and edge cases.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCANNER="${SCRIPT_DIR}/scanner.sh"

# ---------------------------------------------------------------------------
# Test infrastructure
# ---------------------------------------------------------------------------
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() { TESTS_PASSED=$((TESTS_PASSED + 1)); echo "  PASS: $1"; }
fail() { TESTS_FAILED=$((TESTS_FAILED + 1)); echo "  FAIL: $1 — $2"; }

TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)

# Create a temp workspace so tests don't pollute real directories
TEST_HOME=$(mktemp -d)
export HOME="${TEST_HOME}"

DAILY_DIR="${TEST_HOME}/Documents/AI Data Hub/Obsidian/DailyNotes"
RESEARCH_DIR="${TEST_HOME}/Documents/AI Data Hub/Obsidian/Research"
LOG_DIR="${TEST_HOME}/Documents/AI Data Hub/logs/research-loop-scan"

# Stub claude command — logs invocations to a file for assertions
STUB_DIR=$(mktemp -d)
STUB_LOG="${STUB_DIR}/claude_calls.log"

cat > "${STUB_DIR}/claude" << 'STUBEOF'
#!/usr/bin/env bash
echo "$@" >> "${STUB_LOG}"
echo "[stub] claude $*"
exit 0
STUBEOF
chmod +x "${STUB_DIR}/claude"
export PATH="${STUB_DIR}:${PATH}"
export STUB_LOG

cleanup() {
  rm -rf "${TEST_HOME}" "${STUB_DIR}"
}
trap cleanup EXIT

setup_dirs() {
  rm -rf "${DAILY_DIR}" "${RESEARCH_DIR}" "${LOG_DIR}"
  mkdir -p "${DAILY_DIR}" "${RESEARCH_DIR}" "${LOG_DIR}"
  : > "${STUB_LOG}"
}

# ---------------------------------------------------------------------------
# Test 1: Basic tag extraction + context routing
# ---------------------------------------------------------------------------
test_basic_extraction() {
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "TEST 1: Basic tag extraction and context routing"
  setup_dirs

  cat > "${DAILY_DIR}/${TODAY}.md" << 'EOF'
# Daily Note
#research-for-work LLM Fine-Tuning Best Practices
#research-topic Prompt Engineering Patterns
#deep-dive Local RAG Pipelines
EOF

  bash "${SCANNER}" > /dev/null 2>&1

  # Should have 3 claude calls
  local call_count
  call_count=$(wc -l < "${STUB_LOG}")
  if [[ "${call_count}" -eq 3 ]]; then
    pass "Found 3 dispatch calls"
  else
    fail "Expected 3 dispatch calls" "got ${call_count}"
  fi

  # Check context routing: first should be --work, others --personal
  if grep -q "LLM Fine-Tuning Best Practices.*--work" "${STUB_LOG}"; then
    pass "#research-for-work routed to --work"
  else
    fail "#research-for-work context" "expected --work in call"
  fi

  if grep -q "Prompt Engineering Patterns.*--personal" "${STUB_LOG}"; then
    pass "#research-topic routed to --personal"
  else
    fail "#research-topic context" "expected --personal in call"
  fi

  if grep -q "Local RAG Pipelines.*--personal" "${STUB_LOG}"; then
    pass "#deep-dive routed to --personal"
  else
    fail "#deep-dive context" "expected --personal in call"
  fi
}

# ---------------------------------------------------------------------------
# Test 2: Cross-day deduplication
# ---------------------------------------------------------------------------
test_cross_day_dedup() {
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "TEST 2: Cross-day deduplication"
  setup_dirs

  # Same topic in today and yesterday
  cat > "${DAILY_DIR}/${TODAY}.md" << 'EOF'
#research-topic Prompt Engineering Patterns
#research-topic Unique Today Topic
EOF
  cat > "${DAILY_DIR}/${YESTERDAY}.md" << 'EOF'
#research-topic Prompt Engineering Patterns
#research-later Unique Yesterday Topic
EOF

  bash "${SCANNER}" > /dev/null 2>&1

  local call_count
  call_count=$(wc -l < "${STUB_LOG}")
  if [[ "${call_count}" -eq 3 ]]; then
    pass "3 unique topics dispatched (deduped cross-day duplicate)"
  else
    fail "Expected 3 unique dispatches" "got ${call_count}"
  fi

  # "Prompt Engineering Patterns" should appear exactly once
  local pep_count
  pep_count=$(grep -c "Prompt Engineering Patterns" "${STUB_LOG}" || true)
  if [[ "${pep_count}" -eq 1 ]]; then
    pass "Duplicate topic dispatched only once"
  else
    fail "Duplicate topic dedup" "dispatched ${pep_count} times"
  fi
}

# ---------------------------------------------------------------------------
# Test 3: Already-processed dedup
# ---------------------------------------------------------------------------
test_already_processed_dedup() {
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "TEST 3: Already-processed deduplication"
  setup_dirs

  cat > "${DAILY_DIR}/${TODAY}.md" << 'EOF'
#research-topic Prompt Engineering Patterns
#research-topic Brand New Topic
EOF

  # Simulate that "Prompt Engineering Patterns" was already processed today
  touch "${RESEARCH_DIR}/${TODAY}-prompt-engineering-patterns.md"

  bash "${SCANNER}" > /dev/null 2>&1

  local call_count
  call_count=$(wc -l < "${STUB_LOG}")
  if [[ "${call_count}" -eq 1 ]]; then
    pass "Only 1 topic dispatched (already-processed one skipped)"
  else
    fail "Expected 1 dispatch" "got ${call_count}"
  fi

  if grep -q "Brand New Topic" "${STUB_LOG}"; then
    pass "Correct topic dispatched"
  else
    fail "Wrong topic dispatched" "expected Brand New Topic"
  fi
}

# ---------------------------------------------------------------------------
# Test 4: No daily notes exist
# ---------------------------------------------------------------------------
test_missing_daily_notes() {
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "TEST 4: Missing daily notes (graceful exit)"
  setup_dirs

  # Don't create any daily note files
  local output
  output=$(bash "${SCANNER}" 2>&1)
  local exit_code=$?

  if [[ ${exit_code} -eq 0 ]]; then
    pass "Exited cleanly with code 0"
  else
    fail "Expected exit 0" "got exit ${exit_code}"
  fi

  if echo "${output}" | grep -q "WARNING.*Daily note not found"; then
    pass "Logged warning about missing files"
  else
    fail "Expected missing-file warning" "not found in output"
  fi
}

# ---------------------------------------------------------------------------
# Test 5: No tags in daily notes
# ---------------------------------------------------------------------------
test_no_tags() {
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "TEST 5: No research tags in daily notes"
  setup_dirs

  cat > "${DAILY_DIR}/${TODAY}.md" << 'EOF'
# Daily Note
Just a regular day, no research tags here.
- Did some work
- Had lunch
EOF

  local output
  output=$(bash "${SCANNER}" 2>&1)
  local exit_code=$?

  if [[ ${exit_code} -eq 0 ]]; then
    pass "Exited cleanly with code 0"
  else
    fail "Expected exit 0" "got exit ${exit_code}"
  fi

  if echo "${output}" | grep -q "No research tags found"; then
    pass "Logged no-tags message"
  else
    fail "Expected no-tags message" "not found in output"
  fi

  local call_count
  call_count=$(wc -l < "${STUB_LOG}")
  if [[ "${call_count}" -eq 0 ]]; then
    pass "No dispatches made"
  else
    fail "Expected 0 dispatches" "got ${call_count}"
  fi
}

# ---------------------------------------------------------------------------
# Test 6: Empty topic after tag (should be skipped)
# ---------------------------------------------------------------------------
test_empty_topic() {
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "TEST 6: Empty topic after tag is skipped"
  setup_dirs

  cat > "${DAILY_DIR}/${TODAY}.md" << 'EOF'
#research-topic
#research-topic Real Topic Here
EOF

  bash "${SCANNER}" > /dev/null 2>&1

  local call_count
  call_count=$(wc -l < "${STUB_LOG}")
  if [[ "${call_count}" -eq 1 ]]; then
    pass "Only non-empty topic dispatched"
  else
    fail "Expected 1 dispatch" "got ${call_count}"
  fi
}

# ---------------------------------------------------------------------------
# Test 7: #research-later tag works
# ---------------------------------------------------------------------------
test_research_later_tag() {
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "TEST 7: #research-later tag extraction"
  setup_dirs

  cat > "${DAILY_DIR}/${TODAY}.md" << 'EOF'
#research-later Agent Memory Architectures
EOF

  bash "${SCANNER}" > /dev/null 2>&1

  if grep -q "Agent Memory Architectures.*--personal" "${STUB_LOG}"; then
    pass "#research-later extracted and routed to personal"
  else
    fail "#research-later handling" "not found or wrong context"
  fi
}

# ---------------------------------------------------------------------------
# Test 8: Log file is created with expected content
# ---------------------------------------------------------------------------
test_log_file() {
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "TEST 8: Log file creation and content"
  setup_dirs

  cat > "${DAILY_DIR}/${TODAY}.md" << 'EOF'
#research-topic Test Logging
EOF

  bash "${SCANNER}" > /dev/null 2>&1

  local logfile="${LOG_DIR}/${TODAY}.log"
  if [[ -f "${logfile}" ]]; then
    pass "Log file created at ${logfile}"
  else
    fail "Log file missing" "expected ${logfile}"
    return
  fi

  if grep -q "research-loop-scan START" "${logfile}"; then
    pass "Log contains START marker"
  else
    fail "Missing START marker" "in log file"
  fi

  if grep -q "research-loop-scan COMPLETE" "${logfile}"; then
    pass "Log contains COMPLETE marker"
  else
    fail "Missing COMPLETE marker" "in log file"
  fi
}

# ---------------------------------------------------------------------------
# Test 9: Failed dispatch handling
# ---------------------------------------------------------------------------
test_failed_dispatch() {
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "TEST 9: Failed dispatch is logged and continues"
  setup_dirs

  # Make the claude stub fail for a specific topic
  cat > "${STUB_DIR}/claude" << 'STUBEOF'
#!/usr/bin/env bash
echo "$@" >> "${STUB_LOG}"
if echo "$@" | grep -q "Failing Topic"; then
  exit 1
fi
echo "[stub] claude $*"
exit 0
STUBEOF
  chmod +x "${STUB_DIR}/claude"

  cat > "${DAILY_DIR}/${TODAY}.md" << 'EOF'
#research-topic Failing Topic
#research-topic Succeeding Topic
EOF

  bash "${SCANNER}" > /dev/null 2>&1 || true

  local call_count
  call_count=$(wc -l < "${STUB_LOG}")
  if [[ "${call_count}" -eq 2 ]]; then
    pass "Both topics were attempted despite first failure"
  else
    fail "Expected 2 dispatch attempts" "got ${call_count}"
  fi

  local logfile="${LOG_DIR}/${TODAY}.log"
  if grep -q "FAILED.*Failing Topic" "${logfile}"; then
    pass "Failed topic logged as FAILED"
  else
    fail "Expected FAILED log entry" "not found"
  fi

  if grep -q "DONE.*Succeeding Topic" "${logfile}"; then
    pass "Succeeding topic logged as DONE"
  else
    fail "Expected DONE log entry for second topic" "not found"
  fi

  # Restore normal stub
  cat > "${STUB_DIR}/claude" << 'STUBEOF'
#!/usr/bin/env bash
echo "$@" >> "${STUB_LOG}"
echo "[stub] claude $*"
exit 0
STUBEOF
  chmod +x "${STUB_DIR}/claude"
}

# ---------------------------------------------------------------------------
# Test 10: Slug generation
# ---------------------------------------------------------------------------
test_slug_generation() {
  TESTS_RUN=$((TESTS_RUN + 1))
  echo "TEST 10: Topic slug generation"
  setup_dirs

  cat > "${DAILY_DIR}/${TODAY}.md" << 'EOF'
#research-topic LLM Fine-Tuning!!! Best @#$ Practices
EOF

  bash "${SCANNER}" > /dev/null 2>&1

  local logfile="${LOG_DIR}/${TODAY}.log"
  # The already-processed check uses the slug, so we test indirectly:
  # create a file with the expected slug and re-run — it should be skipped
  : > "${STUB_LOG}"
  touch "${RESEARCH_DIR}/${TODAY}-llm-fine-tuning-best-practices.md"

  bash "${SCANNER}" > /dev/null 2>&1

  local call_count
  call_count=$(wc -l < "${STUB_LOG}")
  if [[ "${call_count}" -eq 0 ]]; then
    pass "Slug correctly generated — matched existing file and skipped"
  else
    fail "Slug mismatch" "topic was dispatched instead of skipped"
  fi
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------
echo "========================================"
echo " research-loop-scan — Test Suite"
echo "========================================"
echo ""

test_basic_extraction
echo ""
test_cross_day_dedup
echo ""
test_already_processed_dedup
echo ""
test_missing_daily_notes
echo ""
test_no_tags
echo ""
test_empty_topic
echo ""
test_research_later_tag
echo ""
test_log_file
echo ""
test_failed_dispatch
echo ""
test_slug_generation

echo ""
echo "========================================"
echo " Results: ${TESTS_PASSED} passed, ${TESTS_FAILED} failed (${TESTS_RUN} tests)"
echo "========================================"

if [[ ${TESTS_FAILED} -gt 0 ]]; then
  exit 1
fi
exit 0
