#!/usr/bin/env bash
# run_tests.sh — zero-dependency test runner for update-catalog.sh
#
# Usage: bash tests/run_tests.sh
# Exit 0 = all tests passed; non-zero = failures (each printed).
#
# Strategy: each test runs the real update-catalog.sh in a temp sandbox with a
# mock gh on PATH. The script's outputs (skills.json, README.md) are then
# asserted with grep/jq. No network access is needed.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SCRIPT="$ROOT/bin/update-catalog.sh"

PASS=0
FAIL=0
declare -a FAILURES=()

log() { printf '%s\n' "$*"; }

fail() {
  FAIL=$((FAIL + 1))
  FAILURES+=("$1")
  log "  ❌ $1"
}

pass() { PASS=$((PASS + 1)); log "  ✅ $1"; }

# run_case <name> <mode> <assert_fn> <workdir>
run_case() {
  local name="$1" mode="$2" assert_fn="$3" workdir="$4"
  log "▶ $name"
  # Fresh sandbox per case
  local sandbox="$workdir/sandbox"
  rm -rf "$sandbox"
  mkdir -p "$sandbox"
  ( cd "$sandbox" && \
      MOCK_MODE="$mode" \
      GH_OWNER="cgartlab" \
      PATH="$HERE/fixtures:$PATH" \
      bash "$SCRIPT" >/dev/null 2>&1 )
  local rc=$?
  "$assert_fn" "$sandbox" "$rc" "$name"
}

# ---------------------------------------------------------------------------
# Assertions
# ---------------------------------------------------------------------------
assert_release_ok() {
  local sandbox="$1" rc="$2" name="$3"
  [[ $rc -eq 0 ]] && pass "$name: exit 0" || fail "$name: expected exit 0, got $rc"
  if [[ -f "$sandbox/skills.json" ]] && grep -q '"version": "v0.3.0"' "$sandbox/skills.json" \
      && grep -q '"version_source": "release"' "$sandbox/skills.json"; then
    pass "$name: version from release"
  else
    fail "$name: version should come from release (v0.3.0 / release)"
  fi
  [[ -f "$sandbox/README.md" ]] && grep -q 'v0.3.0' "$sandbox/README.md" \
    && pass "$name: README shows version" || fail "$name: README should contain v0.3.0"
}

assert_fallback_skill_md() {
  local sandbox="$1" rc="$2" name="$3"
  [[ $rc -eq 0 ]] && pass "$name: exit 0" || fail "$name: expected exit 0, got $rc"
  if [[ -f "$sandbox/skills.json" ]] && grep -q '"version": "0.1.1"' "$sandbox/skills.json" \
      && grep -q '"version_source": "skill-md"' "$sandbox/skills.json"; then
    pass "$name: fallback to SKILL.md version"
  else
    fail "$name: person-profile has no release, version must fall back to 0.1.1/skill-md"
  fi
  [[ -f "$sandbox/README.md" ]] && grep -q '0\.1\.1' "$sandbox/README.md" \
    && pass "$name: README shows fallback version" || fail "$name: README should contain 0.1.1"
}

assert_no_skill_md() {
  local sandbox="$1" rc="$2" name="$3"
  [[ $rc -eq 0 ]] && pass "$name: exit 0 (no SKILL.md must not abort)" || fail "$name: expected exit 0, got $rc"
  if [[ -f "$sandbox/skills.json" ]]; then
    if grep -q '"version": ""' "$sandbox/skills.json" && grep -q '"version_source": ""' "$sandbox/skills.json"; then
      pass "$name: empty version + empty source recorded"
    else
      fail "$name: expected empty version/version_source for gamma-skill"
    fi
    if grep -q '"has_skill_md": ""' "$sandbox/skills.json"; then
      pass "$name: has_skill_md empty for repo without SKILL.md"
    else
      fail "$name: skills.json should record empty has_skill_md"
    fi
  else
    fail "$name: skills.json missing"
  fi
  [[ -f "$sandbox/README.md" ]] && grep -q '| — |' "$sandbox/README.md" \
    && pass "$name: README shows — for missing version" || fail "$name: README should show — placeholder"
  [[ -f "$sandbox/README.md" ]] && grep -q 'gamma-skill.*⚠️' "$sandbox/README.md" \
    && pass "$name: README marks missing SKILL.md with warning" || fail "$name: README should flag dead-link candidate with warning"
}

assert_api_error() {
  local sandbox="$1" rc="$2" name="$3"
  [[ $rc -ne 0 ]] && pass "$name: exits non-zero on search failure" || fail "$name: expected failure, got exit 0"
  # script must not leave partial artifacts as if successful
  [[ ! -f "$sandbox/skills.json" ]] && pass "$name: no skills.json left behind" \
    || fail "$name: should not write skills.json on search failure"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
# Ensure the gh mock is executable: git checkouts on Windows may drop the
# exec bit, and then PATH lookup on Linux skips it entirely (the real, token-
# less gh gets picked instead — CI failure mode seen 2026-10-12).
chmod +x "$HERE/fixtures/gh" 2>/dev/null || true

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

run_case "release_ok (release path)"        release_ok        assert_release_ok     "$workdir"
run_case "fallback_skill_md (no release)"   fallback_skill_md  assert_fallback_skill_md "$workdir"
run_case "no_skill_md (no release, no md)"  no_skill_md        assert_no_skill_md   "$workdir"
run_case "api_error (search fails)"         api_error          assert_api_error     "$workdir"

log ""
log "=========="
log "PASS: $PASS  FAIL: $FAIL"
if [[ $FAIL -gt 0 ]]; then
  log "Failed:"
  for f in "${FAILURES[@]}"; do log "  - $f"; done
  exit 1
fi
exit 0
