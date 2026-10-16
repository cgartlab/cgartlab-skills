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

# Helper: count entries in skills.json
skill_count() {
  jq '.skills | length' "$1/skills.json" 2>/dev/null || echo "-1"
}

assert_release_ok() {
  local sandbox="$1" rc="$2" name="$3"
  [[ $rc -eq 0 ]] && pass "$name: exit 0" || fail "$name: expected exit 0, got $rc"

  local n
  n=$(skill_count "$sandbox")
  [[ "$n" == "2" ]] && pass "$name: 2 skills catalogued" \
    || fail "$name: expected 2 skills, got $n"

  if grep -q '"kind": "skill"' "$sandbox/skills.json" \
      && grep -q '"version": "v0.3.0"' "$sandbox/skills.json"; then
    pass "$name: kind + version recorded"
  else
    fail "$name: skills.json must record kind=skill and version=v0.3.0"
  fi

  # README: Kind column header and values
  grep -q '| Skill | Kind | Version | Description | Updated |' "$sandbox/README.md" \
    && pass "$name: README has Kind column" \
    || fail "$name: README must have a Kind column"
  grep -q '| skill | v0.3.0 |' "$sandbox/README.md" \
    && pass "$name: README shows kind + version" \
    || fail "$name: README should show '| skill | v0.3.0 |'"
}

# Repos failing the frontmatter contract are skipped, not fatal.
assert_contract_gate() {
  local sandbox="$1" rc="$2" name="$3" bad_repo="$4"
  [[ $rc -eq 0 ]] && pass "$name: exit 0 (contract failure is a skip, not a crash)" \
    || fail "$name: expected exit 0, got $rc"

  local n
  n=$(skill_count "$sandbox")
  [[ "$n" == "1" ]] && pass "$name: only the valid skill catalogued" \
    || fail "$name: expected exactly 1 skill, got $n"

  if grep -q "$bad_repo" "$sandbox/skills.json"; then
    fail "$name: $bad_repo must NOT appear in skills.json"
  else
    pass "$name: $bad_repo excluded from skills.json"
  fi

  # The good repo must still be present with kind + version.
  grep -q '"kind": "skill"' "$sandbox/skills.json" \
    && grep -q '"version": "v0.3.0"' "$sandbox/skills.json" \
    && pass "$name: valid skill still catalogued with kind + version" \
    || fail "$name: valid skill must be catalogued with kind + version"
}

assert_missing_kind()  { assert_contract_gate "$1" "$2" "$3" "no-kind-skill"; }
assert_bad_kind()      { assert_contract_gate "$1" "$2" "$3" "wrong-kind-skill"; }
assert_no_release()    { assert_contract_gate "$1" "$2" "$3" "unreleased-skill"; }

assert_no_skill_md() {
  local sandbox="$1" rc="$2" name="$3"
  [[ $rc -eq 0 ]] && pass "$name: exit 0 (missing SKILL.md is a skip, not a crash)" \
    || fail "$name: expected exit 0, got $rc"

  local n
  n=$(skill_count "$sandbox")
  [[ "$n" == "0" ]] && pass "$name: nothing catalogued" \
    || fail "$name: expected 0 skills, got $n"

  [[ -f "$sandbox/skills.json" ]] && pass "$name: skills.json still written" \
    || fail "$name: skills.json must exist even when empty"

  [[ -f "$sandbox/README.md" ]] && grep -q '| _暂无 skill 条目_' "$sandbox/README.md" \
    && pass "$name: README shows empty-state row" \
    || fail "$name: README should show the empty-state placeholder"
}

assert_api_error() {
  local sandbox="$1" rc="$2" name="$3"
  [[ $rc -ne 0 ]] && pass "$name: exits non-zero on listing failure" \
    || fail "$name: expected failure, got exit 0"
  # script must not leave partial artifacts as if successful
  [[ ! -f "$sandbox/skills.json" ]] && pass "$name: no skills.json left behind" \
    || fail "$name: should not write skills.json on listing failure"
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

run_case "release_ok (valid skills catalogued)"        release_ok        assert_release_ok     "$workdir"
run_case "missing_kind (metadata.kind absent)"         missing_kind      assert_missing_kind   "$workdir"
run_case "bad_kind (metadata.kind out of range)"       bad_kind          assert_bad_kind       "$workdir"
run_case "no_release (release gate)"                   no_release        assert_no_release     "$workdir"
run_case "no_skill_md (nothing to catalogue)"          no_skill_md       assert_no_skill_md    "$workdir"
run_case "api_error (listing fails)"                   api_error         assert_api_error      "$workdir"

log ""
log "=========="
log "PASS: $PASS  FAIL: $FAIL"
if [[ $FAIL -gt 0 ]]; then
  log "Failed:"
  for f in "${FAILURES[@]}"; do log "  - $f"; done
  exit 1
fi
exit 0
