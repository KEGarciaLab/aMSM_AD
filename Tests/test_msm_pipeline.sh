#!/usr/bin/env bash
# Simple harness to run a set of commands, capture exit code and output.
# Populate the COMMANDS array with commands you want to test.
# Usage: chmod +x test_msm_pipeline.sh && ./test_msm_pipeline.sh

set -euo pipefail

# Adjust this timeout (requires coreutils timeout)
TIMEOUT=60

# Commands to test: put each command as a single quoted string
# Replace these placeholders with the commands from MSM_pipeline.py
COMMANDS=(
  'python --version'
  # 'msm_step1 --input tests/data/a.txt'
  # 'msm_step2 --foo bar'
)

# Expected exit codes per command (same index as COMMANDS)
EXPECTED=(0  # for python --version
  # 0
  # 0
)

# Optional patterns to check in stdout/stderr (use empty string to skip)
PATTERNS=(
  'Python [0-9]+\.[0-9]+'
  # 'Completed'
  # ''
)

failures=0
for i in "${!COMMANDS[@]}"; do
  cmd="${COMMANDS[$i]}"
  expect="${EXPECTED[$i]:-0}"
  pattern="${PATTERNS[$i]:-}"
  echo "==> Running: $cmd"
  # run in a subshell to capture both stdout+stderr
  output="$(timeout ${TIMEOUT}s bash -lc "$cmd" 2>&1)" || rc=$?; rc=${rc:-0}
  echo "Exit code: $rc"
  echo "$output"
  if [ "$rc" -ne "$expect" ]; then
    echo "  [FAIL] exit code $rc != expected $expect"
    failures=$((failures+1))
  elif [ -n "$pattern" ]; then
    if ! echo "$output" | grep -Pq "$pattern"; then
      echo "  [FAIL] output did not match pattern: $pattern"
      failures=$((failures+1))
    else
      echo "  [OK] pattern matched"
    fi
  else
    echo "  [OK]"
  fi
  echo
done

if [ "$failures" -ne 0 ]; then
  echo "Some tests failed: $failures"
  exit 2
fi
echo "All tests passed."