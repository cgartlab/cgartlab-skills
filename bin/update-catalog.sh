#!/usr/bin/env bash
# update-catalog.sh — Scan cgartlab skill repos and regenerate skills.json + README.md
#
# Detection rule (D: frontmatter contract + release gate):
#   1. Scan ALL repos owned by GH_OWNER (name is irrelevant).
#   2. A repo is a catalogued skill ONLY IF its root SKILL.md frontmatter
#      contains name, description and metadata.kind, AND metadata.kind is one
#      of skill|agent|mcp.
#   3. A repo MUST have a latest GitHub Release; the tag_name becomes the
#      version. No release → not catalogued (hard gate, no fallback).
#   4. Repos failing any rule are skipped silently in the index, but the skip
#      reason is printed to stderr so misconfigured repos stay visible.
#
# Requires: gh, jq
# Env:      GH_TOKEN (GitHub PAT with repo scope)
#           GH_OWNER (default: cgartlab)
#
# Usage:    GH_TOKEN=xxx bash bin/update-catalog.sh

set -euo pipefail

# MSYS/Git-Bash on Windows rewrites a leading-slash endpoint argument into a
# filesystem path ("/repos/..." -> "C:/Program Files/Git/repos/..."), which the
# API then rejects. Disabling that conversion keeps POSIX-style endpoints intact.
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL="*"

OWNER="${GH_OWNER:-cgartlab}"
DATA_FILE="skills.json"

echo "[*] Scanning ALL repos of $OWNER (frontmatter contract + release gate) ..."

# Fetch all repos for the owner, exclude this repo.
# Enumerate ALL repos of the owner. search/repositories is used instead of
# /users/<owner>/repos because the latter returns an INCOMPLETE list of private
# repos (observed 2026-10: 25 of 47 returned, silently dropping blacklight-weekly
# and news-report). search returns the full set for user:<owner> queries.
# A freshly renamed repo may lag in the search index; that is a bounded delay
# (minutes) and self-heals on the next run, which is acceptable versus silently
# missing private repos forever.
REPOS=$(gh api "search/repositories?q=user:$OWNER&per_page=100" --paginate \
  --jq '[.items[] | select(.full_name != "cgartlab/cgartlab-skills")
        | {name, full_name, description, updated_at, html_url}]' \
  | jq -s 'add // []')

TOTAL=$(echo "$REPOS" | jq 'length // 0')
echo "[*] Found $TOTAL repo(s) to evaluate"

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
SKIPPED_FILE="$TMP_DIR/skipped.log"
: > "$SKILLS_FILE"
: > "$SKIPPED_FILE"

# Extract the YAML frontmatter block (first --- ... --- pair) from SKILL.md.
# Prints the block WITHOUT the delimiters. Empty output when there is none.
extract_frontmatter() {
  awk 'BEGIN{infm=0} /^---[[:space:]]*$/{infm++; if(infm==1) next; if(infm==2) exit; next} infm==1{print}' "$1"
}

# Read a scalar value from the frontmatter by top-level or metadata.child key.
# Args: <frontmatter file> <key path, e.g. "name" or "metadata.kind">
# Handles both "key: value" and block scalars are NOT expanded (only the first
# line of a block scalar is returned, which is enough for kind/name).
fm_value() {
  local fm="$1" keypath="$2"
  awk -v want="$keypath" '
    BEGIN { split(want, parts, "."); depth = 0 }
    {
      line = $0
      # measure indent
      match(line, /^ */)
      ind = RLENGTH
      sub(/^ */, "", line)
      if (line ~ /^#/ || line == "") next
      if (line ~ /^---[[:space:]]*$/) next
      # split "key: rest"
      ci = index(line, ":")
      if (ci == 0) next
      key = substr(line, 1, ci - 1)
      val = substr(line, ci + 1)
      sub(/^[[:space:]]+/, "", val)
      sub(/[[:space:]]+$/, "", val)
      gsub(/^["'\'']|["'\'']$/, "", val)
      if (ind == 0) { cur = key }
      # match the requested path
      n = split(want, p, ".")
      if (n == 1) {
        if (ind == 0 && key == want && val != "") { print val; exit }
      } else {
        if (ind == 0) { cur = key; next }
        if (cur == p[1] && key == p[2] && val != "") { print val; exit }
      }
    }
  ' "$fm"
}

# Fetch SKILL.md into a file; return 0 on success, 1 on any failure.
# Uses the raw media type so the API returns the decoded file directly —
# no base64 round-trip (which is fragile on Windows/MSYS for large files).
fetch_skill_md() {
  local full="$1" out="$2"
  if ! gh api -H "Accept: application/vnd.github.raw" \
      "/repos/$full/contents/SKILL.md" > "$out" 2>/dev/null; then
    return 1
  fi
  [[ -s "$out" ]] || return 1
  return 0
}

while IFS= read -r repo; do
  FULL_NAME=$(echo "$repo" | jq -r '.full_name')

  # --- Gate 1: SKILL.md must exist at the repo root -------------------------
  SKILL_MD_FILE="$TMP_DIR/skill.md"
  if ! fetch_skill_md "$FULL_NAME" "$SKILL_MD_FILE"; then
    echo "[-] $FULL_NAME: no SKILL.md at root, skipped" >> "$SKIPPED_FILE"
    continue
  fi

  FM_FILE="$TMP_DIR/frontmatter.yml"
  extract_frontmatter "$SKILL_MD_FILE" > "$FM_FILE"
  if [[ ! -s "$FM_FILE" ]]; then
    echo "[-] $FULL_NAME: SKILL.md has no frontmatter, skipped" >> "$SKIPPED_FILE"
    continue
  fi

  # --- Gate 2: frontmatter contract (name + description + metadata.kind) ----
  KIND=$(fm_value "$FM_FILE" "metadata.kind")
  case "$KIND" in
    skill|agent|mcp) ;;
    "") echo "[-] $FULL_NAME: metadata.kind missing, skipped" >> "$SKIPPED_FILE"; continue ;;
    *)  echo "[-] $FULL_NAME: metadata.kind '$KIND' not in {skill,agent,mcp}, skipped" >> "$SKIPPED_FILE"; continue ;;
  esac

  SKILL_NAME=$(fm_value "$FM_FILE" "name")
  if [[ -z "$SKILL_NAME" ]]; then
    echo "[-] $FULL_NAME: frontmatter 'name' missing, skipped" >> "$SKIPPED_FILE"
    continue
  fi

  # description may be a plain scalar or a block scalar (>- / | / >); for the
  # gate we only need "is a description field present at all".
  if ! grep -qE '^[[:space:]]*description:' "$FM_FILE"; then
    echo "[-] $FULL_NAME: frontmatter 'description' missing, skipped" >> "$SKIPPED_FILE"
    continue
  fi

  # --- Gate 3: a release must exist (tag_name becomes the version) ----------
  # The releases endpoint 404s for repos without one. Treat that as "no
  # release" and skip, never as a fatal error.
  VERSION=""
  RELEASE_JSON=$(gh api "/repos/$FULL_NAME/releases/latest" 2>/dev/null || true)
  if [[ -n "$RELEASE_JSON" ]]; then
    VERSION=$(echo "$RELEASE_JSON" | jq -r '.tag_name // empty')
  fi
  if [[ -z "$VERSION" ]]; then
    echo "[-] $FULL_NAME: no GitHub Release, skipped (release is mandatory)" >> "$SKIPPED_FILE"
    continue
  fi

  # The catalog's display name is the REPO name, not the frontmatter name:
  # repo names are unique and match the html_url the table links to.
  echo "$repo" | jq --arg v "$VERSION" --arg k "$KIND" \
    '. + {version: $v, kind: $k}' >> "$SKILLS_FILE"
  echo "[+] $FULL_NAME: kind=$KIND version=$VERSION" >> "$SKIPPED_FILE"
done < <(echo "$REPOS" | jq -c '.[] // empty')

SKILLS=$(jq -s 'if . == null then [] else . end' "$SKILLS_FILE")
COUNT=$(echo "$SKILLS" | jq 'length')

# Surface every skip decision on stderr (fail-visible).
if [[ -s "$SKIPPED_FILE" ]]; then
  cat "$SKIPPED_FILE" >&2
fi

# Write skills.json
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
jq -n --arg updatedAt "$NOW" --argjson skills "$SKILLS" \
  '{updatedAt: $updatedAt, skills: $skills}' > "$DATA_FILE"

echo "[*] Written $DATA_FILE ($COUNT skill(s))"

# --- Generate README.md ---
TABLE_ROWS=$(echo "$SKILLS" | jq -r '
  if length == 0 then
    "| _暂无 skill 条目_ | _—_ | _—_ | _—_ | _—_ |"
  else
    sort_by(.name) | map(
      "| [\(.name)](\(.html_url)) "
      + "| \(.kind // "—") "
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
> 本仓库自动扫描 \`cgartlab\` 名下所有仓库，按 **SKILL.md frontmatter 契约 + Release 硬门槛** 收录，收集类型、摘要、版本和链接。

**授权**: [CC BY-NC-SA 4.0](LICENSE) · **来源**: [github.com/cgartlab/cgartlab-skills](https://github.com/cgartlab/cgartlab-skills)

---

## 📦 Skills

| Skill | Kind | Version | Description | Updated |
|-------|------|---------|-------------|---------|
$TABLE_ROWS

<sup>最后更新: ${UPDATED_AT} · 收录条件：根目录 SKILL.md 的 frontmatter 含 name / description / metadata.kind（kind ∈ skill, agent, mcp），且仓库已发布 Release</sup>

---

## ➕ 添加新 Skill

只需在 \`cgartlab\` 账号下创建仓库（**名称不限**），并满足以下契约，本目录会在下次自动扫描时收录。

| 条件 | 说明 |
|------|------|
| 根目录存在 \`SKILL.md\` | 遵循 [Agent Skills 标准](https://agentskills.io) 的 skill 定义 |
| frontmatter 含 \`name\` 与 \`description\` | 技能名与触发描述 |
| frontmatter 含 \`metadata.kind\` | 取值 \`skill\` / \`agent\` / \`mcp\`，用于索引分类 |
| **已发布 Release** | \`tag_name\` 作为版本号；**无 Release 不收录** |

\`SKILL.md\` frontmatter 示例：

\`\`\`yaml
---
name: my-skill
description: >-
  一句话说明这个 skill 做什么、何时触发。
metadata:
  kind: skill
---
\`\`\`

其他建议文件：

| 文件 | 说明 |
|------|------|
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
