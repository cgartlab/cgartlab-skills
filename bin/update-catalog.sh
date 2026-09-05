#!/usr/bin/env bash
# update-catalog.sh — Scan cgartlab skill repos and regenerate README.md
#
# Detection rule: repos whose name ends with "-skill", plus an explicit
# exception for cgartlab/news-report (renamed from cgartlab/miniflux-mcp-skill).
# The GitHub rename dropped the "-skill" suffix, but news-report is still an
# official skill repo and must keep being catalogued.
#
# Requires: gh, jq
# Env:      GH_TOKEN (GitHub PAT with repo scope)
#           GH_OWNER (default: cgartlab)
#
# Usage:    GH_TOKEN=xxx bash bin/update-catalog.sh

set -euo pipefail

OWNER="${GH_OWNER:-cgartlab}"
THIS_REPO="${GITHUB_REPOSITORY:-cgartlab/cgartlab-skills}"
DATA_FILE="skills.json"

echo "[*] Scanning $OWNER for repos ending with -skill (plus explicit exception: news-report) ..."

# Fetch all repos for the owner, filter by "-skill" suffix or the explicit
# exception "news-report" (formerly miniflux-mcp-skill), exclude this repo
REPOS=$(gh api "search/repositories?q=user:$OWNER&per_page=100" --paginate --jq '[.items[] | select((.name | endswith("-skill")) or (.name == "news-report")) | select(.full_name != "cgartlab/cgartlab-skills") | {name, full_name, description, updated_at, html_url}]' | jq -s 'add // []')

TOTAL=$(echo "$REPOS" | jq 'length // 0')
echo "[*] Found $TOTAL skill repo(s)"

# Enrich each repo with latest release version
SKILLS=$(echo "$REPOS" | jq -c '.[] // empty' | while read -r repo; do
  FULL_NAME=$(echo "$repo" | jq -r '.full_name')
  VERSION=$(gh api "/repos/$FULL_NAME/releases/latest" --jq '.tag_name // empty' || echo "")
  echo "$repo" | jq --arg v "$VERSION" '. + {version: $v}'
done | jq -s 'if . == null then [] else . end')

# Write skills.json
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
jq -n --arg updatedAt "$NOW" --argjson skills "$SKILLS" \
  '{updatedAt: $updatedAt, skills: $skills}' > "$DATA_FILE"

echo "[*] Written $DATA_FILE"

# --- Generate README.md ---
TABLE_ROWS=$(echo "$SKILLS" | jq -r '
  if length == 0 then
    "| _暂无 skill 条目_ | _—_ | _—_ | _—_ |"
  else
    sort_by(.name) | map(
      "| [\(.name)](\(.html_url)) "
      + "| \(if .version != "" then .version else "—" end) "
      + "| \(.description // "—" | gsub("\\s+$"; "") | gsub("\\n"; " ")) "
      + "| \(.updated_at[:10]) |"
    ) | .[]
  end
')

UPDATED_AT=$(echo "$NOW" | sed 's/T.*//')

cat > README.md << EOF
# CGArtLab Skills Catalog

> 个人 AI Agent Skills 索引目录。
> 本仓库自动扫描 \`cgartlab\` 名下以 \`-skill\` 结尾的仓库，并显式收录 \`cgartlab/news-report\`（由原 miniflux-mcp-skill 更名而来，收录例外），收集摘要、版本和链接。

**授权**: [CC BY-NC-SA 4.0](LICENSE) · **来源**: [github.com/cgartlab/cgartlab-skills](https://github.com/cgartlab/cgartlab-skills)

---

## 📦 Skills

| Skill | Version | Description | Updated |
|-------|---------|-------------|---------|
$TABLE_ROWS

<sup>最后更新: ${UPDATED_AT} · 自动检测以 \`-skill\` 结尾的仓库及显式收录的 \`news-report\`</sup>

---

## ➕ 添加新 Skill

只需在你的 GitHub 账号下创建一个以 \`-skill\` 结尾的公开或私有仓库，本目录会在下次自动扫描时收录。

建议每个 skill 仓库包含：

| 文件 | 说明 |
|------|------|
| \`SKILL.md\` | 遵循 [Agent Skills 标准](https://agentskills.io) 的 skill 定义 |
| \`README.md\` | 项目的简明介绍 |
| License | 推荐 CC BY-NC-SA 4.0（与母仓库一致） |

## 🔄 更新方式

本仓库通过 GitHub Actions 自动更新：

- **定时扫描**: 每周一次
- **手动触发**: 前往 Actions → Update Skill Catalog → Run workflow
- **自动触发**（可选）: skill 仓库 release 时可配置 webhook 触发更新

> 要求仓库设置 **SKILL_CATALOG_PAT** secret（GitHub Personal Access Token，scope: \`repo\`）。

---

(C) 2026 CGArtLab · CC BY-NC-SA 4.0
EOF

echo "[*] README.md regenerated"
echo "[✓] Done"
