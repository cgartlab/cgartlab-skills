#!/usr/bin/env bash
set -euo pipefail

# ── cgartlab-skills 脚手架生成器 ──
# 创建一个新技能目录、SKILL.md、references/ 子目录

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="${REPO_ROOT}/skills"
TEMPLATES_DIR="${REPO_ROOT}/templates"

show_help() {
  cat <<EOF
Usage: make new name=<skill-name>

Creates a new skill skeleton:

  skills/<skill-name>/
    SKILL.md           # From template
    references/        # Reference docs directory

The skill name must match:
  ^[a-z0-9][a-z0-9-]*[a-z0-9]\$  (kebab-case, 1-64 chars)
EOF
}

if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  show_help
  exit 0
fi

SKILL_NAME="$1"

# 验证 name 格式
if ! echo "$SKILL_NAME" | grep -qE '^[a-z0-9][a-z0-9-]*[a-z0-9]$' && [ "${#SKILL_NAME}" -gt 1 ]; then
  if ! echo "$SKILL_NAME" | grep -qE '^[a-z0-9]$'; then
    echo "Error: name must match ^[a-z0-9][a-z0-9-]*[a-z0-9]\$"
    echo "  Got: ${SKILL_NAME}"
    exit 1
  fi
fi

if echo "$SKILL_NAME" | grep -q '--'; then
  echo "Error: name must not contain consecutive hyphens '--'"
  exit 1
fi

if [ "${#SKILL_NAME}" -gt 64 ]; then
  echo "Error: name must be 64 characters or fewer (got ${#SKILL_NAME})"
  exit 1
fi

TARGET_DIR="${SKILLS_DIR}/${SKILL_NAME}"

if [ -d "$TARGET_DIR" ]; then
  echo "Error: skill '${SKILL_NAME}' already exists at ${TARGET_DIR}"
  exit 1
fi

mkdir -p "${TARGET_DIR}/references"

# 从模板生成 SKILL.md
if [ -f "${TEMPLATES_DIR}/skill-template.md" ]; then
  sed "s/{{SKILL_NAME}}/${SKILL_NAME}/g" "${TEMPLATES_DIR}/skill-template.md" > "${TARGET_DIR}/SKILL.md"
else
  cat > "${TARGET_DIR}/SKILL.md" <<SKILLEOF
---
name: ${SKILL_NAME}
description: >-
  TODO: Describe what this skill does and when to use it.
  Use ONLY when [trigger conditions].
license: CC BY-NC-SA 4.0
---

# ${SKILL_NAME}

## 概述

## 核心规则

## 工作流

## 示例

## 参考
SKILLEOF
fi

echo "✔ Created skill: ${TARGET_DIR}"
echo "   Next steps:"
echo "   1. Edit ${TARGET_DIR}/SKILL.md"
echo "   2. Run 'make validate'"
echo "   3. Run 'make dev-link' to activate"
