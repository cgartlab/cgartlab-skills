#!/usr/bin/env bash
set -euo pipefail

# ── cgartlab-skills 验证脚本 ──
# 检查所有 SKILL.md 的 frontmatter 和命名规范

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="${REPO_ROOT}/skills"
ERRORS=0
WARNINGS=0

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
yellow(){ printf '\033[33m%s\033[0m\n' "$*"; }

check_skill() {
  local dir="$1"
  local name
  name="$(basename "$dir")"
  local skill_file="${dir}/SKILL.md"
  local ok=true

  # 检查 SKILL.md 是否存在
  if [ ! -f "$skill_file" ]; then
    red "  ✗ ${name}: missing SKILL.md"
    ERRORS=$((ERRORS + 1))
    return
  fi

  # 读取 frontmatter 中的 name 字段
  local fm_name
  fm_name=$(sed -n '/^---$/,/^---$/p' "$skill_file" | grep '^name:' | head -1 | sed 's/^name:[[:space:]]*//' | tr -d ' \t\n\r"' )

  if [ -z "$fm_name" ]; then
    red "  ✗ ${name}: SKILL.md missing 'name' field in frontmatter"
    ERRORS=$((ERRORS + 1))
    ok=false
  elif [ "$fm_name" != "$name" ]; then
    red "  ✗ ${name}: name '${fm_name}' does not match directory name '${name}'"
    ERRORS=$((ERRORS + 1))
    ok=false
  fi

  # 检查 description 是否存在
  local fm_desc
  fm_desc=$(sed -n '/^---$/,/^---$/p' "$skill_file" | grep '^description:' | head -1 || true)
  if [ -z "$fm_desc" ]; then
    red "  ✗ ${name}: SKILL.md missing 'description' field in frontmatter"
    ERRORS=$((ERRORS + 1))
    ok=false
  fi

  # 检查 name 格式：小写字母、数字、连字符
  if ! echo "$name" | grep -qE '^[a-z0-9][a-z0-9-]*[a-z0-9]$' && [ "${#name}" -gt 1 ]; then
    if ! echo "$name" | grep -qE '^[a-z0-9]$'; then
      yellow "  ⚠ ${name}: name should match ^[a-z0-9][a-z0-9-]*[a-z0-9]$"
      WARNINGS=$((WARNINGS + 1))
    fi
  fi

  # 检查是否包含 `--`（连续连字符）
  if echo "$name" | grep -q '--'; then
    yellow "  ⚠ ${name}: name contains consecutive hyphens '--'"
    WARNINGS=$((WARNINGS + 1))
  fi

  if $ok; then
    green "  ✓ ${name}"
  fi
}

echo "── Validating skills in ${SKILLS_DIR} ──"
echo ""

if [ ! -d "$SKILLS_DIR" ]; then
  yellow "  (skills/ directory does not exist yet)"
  echo ""
  echo "✔ 0 skills, 0 errors"
  exit 0
fi

shopt -s nullglob
skill_dirs=("$SKILLS_DIR"/*/)
shopt -u nullglob

if [ ${#skill_dirs[@]} -eq 0 ]; then
  yellow "  (no skills found)"
  echo ""
  echo "✔ 0 skills, 0 errors"
  exit 0
fi

for dir in "${skill_dirs[@]}"; do
  check_skill "$dir"
done

echo ""
total=${#skill_dirs[@]}
if [ "$ERRORS" -gt 0 ]; then
  red "✗ ${total} skills, ${ERRORS} errors, ${WARNINGS} warnings"
  exit 1
else
  green "✔ ${total} skills, ${ERRORS} errors, ${WARNINGS} warnings"
  exit 0
fi
