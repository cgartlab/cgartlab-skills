#!/usr/bin/env bash
set -euo pipefail

# ── cgartlab-skills 开发符号链接 ──
# 将 skills/ 下所有技能符号链接到 ~/.claude/skills/
# 修改技能文件后即时生效，无需重新安装

INSTALL_DIR="${HOME}/.claude/skills"
SKILLS_SRC="$(cd "$(dirname "$0")/.." && pwd)/skills"

mkdir -p "$INSTALL_DIR"

count=0
for skill_dir in "$SKILLS_SRC"/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  target="${INSTALL_DIR}/${name}"

  # 备份已存在的非符号链接目录
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mv "$target" "${target}.backup"
    echo "  ⚠  Backed up existing: ${target} → ${target}.backup"
  fi

  ln -sfn "$skill_dir" "$target"
  echo "  🔗 ${name} → ${target}"
  count=$((count + 1))
done

echo "✔ Linked ${count} skills to ${INSTALL_DIR}"
echo "   Changes to skills/ are now live. Restart your AI agent."
