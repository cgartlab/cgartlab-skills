#!/usr/bin/env bash
# update-catalog.sh — Scan cgartlab skill repos and regenerate README.md
#
# Detection rule: repos whose name ends with "-skill", plus explicit
# exceptions for cgartlab/news-report (renamed from cgartlab/miniflux-mcp-skill)
# and cgartlab/person-profile (a skill repo that predates the "-skill" naming
# convention). Neither ends with "-skill" but both are official skill repos and
# must keep being catalogued.
#
# Requires: gh, jq
# Env:      GH_TOKEN (GitHub PAT with repo scope)
#           GH_OWNER (default: cgartlab)
#
# Usage:    GH_TOKEN=xxx bash bin/update-catalog.sh

set -euo pipefail

OWNER="${GH_OWNER:-cgartlab}"
DATA_FILE="skills.json"

echo "[*] Scanning $OWNER for repos ending with -skill (plus explicit exceptions: news-report, person-profile) ..."

# Fetch all repos for the owner, filter by "-skill" suffix or the explicit
# exceptions "news-report" (formerly miniflux-mcp-skill) and "person-profile"
# (predates the -skill naming convention), exclude this repo
REPOS=$(gh api "search/repositories?q=user:$OWNER&per_page=100" --paginate --jq '[.items[] | select((.name | endswith("-skill")) or (.name == "news-report") or (.name == "person-profile")) | select(.full_name != "cgartlab/cgartlab-skills") | {name, full_name, description, updated_at, html_url}]' | jq -s 'add // []')

TOTAL=$(echo "$REPOS" | jq 'length // 0')
echo "[*] Found $TOTAL skill repo(s)"

# Enrich each repo with latest release version
# NOTE: the while loop below must NOT run in a $( ) subshell — mktemp + trap
# cleanup there would delete the temp dir (and its files) before the main
# shell reads them. Process substitution (< <(...)) keeps the loop in this shell.
# TMP_DIR uses a RELATIVE path: on Windows/MSYS a POSIX /tmp path is invisible
# to native jq.exe (it resolves it as C:\tmp), which breaks the pipeline.
# A CWD-relative dir works identically on Linux CI and Windows dev boxes and
# is removed by the EXIT trap either way.
TMP_DIR=$(mktemp -d .catalog-tmp.XXXXXX)
trap 'rm -rf "$TMP_DIR"' EXIT
SKILLS_FILE="$TMP_DIR/skills.jsonl"
API_ERR_FILE="$TMP_DIR/releases.err"
: > "$SKILLS_FILE"
: > "$API_ERR_FILE"

while IFS= read -r repo; do
  FULL_NAME=$(echo "$repo" | jq -r '.full_name')

  # Version strategy (fallback chain):
  #   1. latest GitHub release tag
  #   2. SKILL.md frontmatter metadata.version (Agent Skills standard)
  # A repo without any release MUST NOT abort the whole scan: the releases
  # endpoint returns 404 for such repos, so treat it as "no release found"
  # and fall through to the SKILL.md fallback instead of failing.
  VERSION=""
  VERSION_SRC=""

  RELEASE_JSON=$(gh api "/repos/$FULL_NAME/releases/latest" 2> "$API_ERR_FILE" || true)
  if [[ -n "$RELEASE_JSON" ]]; then
    TAG=$(echo "$RELEASE_JSON" | jq -r '.tag_name // empty')
    if [[ -n "$TAG" ]]; then
      VERSION="$TAG"
      VERSION_SRC="release"
    fi
  fi

  if [[ -z "$VERSION" ]]; then
    # SKILL.md fetch is best-effort: a -skill repo without SKILL.md is a data
    # gap (dead link candidate), not a reason to abort the whole scan.
    SKILL_MD=$(gh api "/repos/$FULL_NAME/contents/SKILL.md" --jq '.content' 2> /dev/null || true)
    if [[ -n "$SKILL_MD" ]]; then
      # || true: with set -o pipefail, a malformed base64 body (API glitch)
      # would otherwise kill the whole scan; empty output is handled below.
      # Strip surrounding quotes with tr (shellcheck-parseable, unlike a
      # quote-juggling sed replacement).
      FM_VERSION=$(echo "$SKILL_MD" | base64 -d 2> /dev/null \
        | sed -n 's/^[[:space:]]*version:[[:space:]]*//p' \
        | head -1 \
        | tr -d "\"'" || true)
      if [[ -n "$FM_VERSION" ]]; then
        VERSION="$FM_VERSION"
        VERSION_SRC="skill-md"
      fi
    fi
    if [[ -z "$VERSION" ]]; then
      echo "[!] $FULL_NAME: no version from release or SKILL.md (missing SKILL.md? dead-link candidate)" >&2
    fi
  fi

  if [[ $VERSION_SRC != "release" ]]; then
    echo "[i] $FULL_NAME: no release found (version source: ${VERSION_SRC:-none})" >&2
  fi

  jq -n --argjson repo "$repo" --arg v "$VERSION" --arg src "$VERSION_SRC" \
    '$repo + {version: $v, version_source: $src}' >> "$SKILLS_FILE"
done < <(echo "$REPOS" | jq -c '.[] // empty')

SKILLS=$(jq -s 'if . == null then [] else . end' "$SKILLS_FILE")


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
> 本仓库自动扫描 \`cgartlab\` 名下以 \`-skill\` 结尾的仓库，并显式收录 \`cgartlab/news-report\`（由原 miniflux-mcp-skill 更名而来）与 \`cgartlab/person-profile\`（早于 -skill 命名约定的 skill 仓），收集摘要、版本和链接。

**授权**: [CC BY-NC-SA 4.0](LICENSE) · **来源**: [github.com/cgartlab/cgartlab-skills](https://github.com/cgartlab/cgartlab-skills)

---

## 📦 Skills

| Skill | Version | Description | Updated |
|-------|---------|-------------|---------|
$TABLE_ROWS

<sup>最后更新: ${UPDATED_AT} · 自动检测以 \`-skill\` 结尾的仓库及显式收录的 \`news-report\`、\`person-profile\`</sup>

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
