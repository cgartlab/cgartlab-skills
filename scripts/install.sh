#!/usr/bin/env bash
set -euo pipefail

# ── cgartlab-skills 安装脚本 ──
# 安装到 ~/.claude/skills/（所有 Agent 通用的技能发现位置）
#
# 用法:
#   ./scripts/install.sh              # 复制安装
#   ./scripts/install.sh --link       # 符号链接安装

INSTALL_DIR="${HOME}/.claude/skills"
SKILLS_SRC="$(cd "$(dirname "$0")/.." && pwd)/skills"
MODE="copy"

for arg in "$@"; do
  case "$arg" in
    --link) MODE="link" ;;
    --help)
      echo "Usage: $0 [--link]"
      echo "  (default)  Copy skills to ${INSTALL_DIR}"
      echo "  --link     Symlink skills for live editing"
      exit 0
      ;;
  esac
done

mkdir -p "$INSTALL_DIR"

count=0
for skill_dir in "$SKILLS_SRC"/*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  target="${INSTALL_DIR}/${name}"

  if [ "$MODE" = "link" ]; then
    ln -sfn "$skill_dir" "$target"
    echo "  🔗 ${name} → ${target}"
  else
    cp -r "$skill_dir" "$target"
    echo "  📄 ${name} → ${target}"
  fi
  count=$((count + 1))
done

echo "✔ Installed ${count} skills to ${INSTALL_DIR}"
echo "   Restart your AI agent for changes to take effect."
