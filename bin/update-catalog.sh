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

# ── Rate-limit protection (issue #13) ───────────────────────────────────────
# GitHub's REST API allows 5000 req/hour for authenticated requests. This
# script makes 2-3 calls per repo, so a 0.5s inter-request delay keeps us far
# below the ceiling while adding only ~35s for a 60-repo scan.
API_DELAY="${API_DELAY:-0.5}"
# Retries for transient failures (network blips, secondary rate limits).
API_RETRIES="${API_RETRIES:-3}"
# Hard ceiling on consecutive rate-limit hits before aborting the whole run.
MAX_RATE_LIMIT_HITS="${MAX_RATE_LIMIT_HITS:-5}"

RATE_LIMIT_HITS=0
TRANSIENT_ERRORS=0

# api_call <endpoint> [extra gh api args...]
# Wraps `gh api` with pacing, Retry-After handling and bounded retries.
# Prints the response body on success. Returns non-zero only when retries are
# exhausted — callers decide whether that is fatal.
api_call() {
  local endpoint="$1"; shift
  local attempt=0

  while :; do
    attempt=$((attempt + 1))

    local out rc
    # Capture headers so we can read Retry-After / X-RateLimit-Remaining.
    out=$(gh api --include "$@" "$endpoint" 2>&1) && rc=0 || rc=$?

    if [[ $rc -eq 0 ]]; then
      # Strip the HTTP header block; keep the body only.
      # `gh api --include` separates headers from body with a blank line whose
      # terminator varies (CRLF on some platforms, LF on others), so match any
      # empty line rather than a literal CRLF.
      printf '%s\n' "$out" | awk 'BEGIN{h=1} h && /^[[:space:]]*$/ {h=0; next} !h {print}'
      sleep "$API_DELAY"
      return 0
    fi

    # Rate limit / server-side failures need a cooldown before retrying.
    if printf '%s' "$out" | grep -qiE 'rate limit|abuse detection|HTTP 429|HTTP 5[0-9][0-9]'; then
      RATE_LIMIT_HITS=$((RATE_LIMIT_HITS + 1))
      if [[ $RATE_LIMIT_HITS -ge $MAX_RATE_LIMIT_HITS ]]; then
        echo "[!] aborted: $RATE_LIMIT_HITS rate-limit/server errors in this run" >&2
        return 1
      fi
      local wait_for
      wait_for=$(printf '%s' "$out" | grep -iE '^retry-after:' | head -1 | tr -dc '0-9') || true
      [[ -n "$wait_for" ]] || wait_for=$((attempt * 5))
      echo "[!] rate limited on $endpoint, waiting ${wait_for}s (hit $RATE_LIMIT_HITS)" >&2
      sleep "$wait_for"
    elif printf '%s' "$out" | grep -qE 'HTTP 404|Not Found'; then
      # 404 is a definitive answer (resource absent), not a transient failure.
      # Retrying it wastes quota and pollutes the transient-error count.
      # No stderr noise: callers treat rc=2 as "absent" and log their own reason.
      return 2
    else
      # Plain transient failure (network, DNS, 502): short backoff.
      TRANSIENT_ERRORS=$((TRANSIENT_ERRORS + 1))
      if [[ $attempt -ge $API_RETRIES ]]; then
        echo "[!] giving up on $endpoint after $attempt attempts" >&2
        return 1
      fi
      echo "[!] transient error on $endpoint (attempt $attempt/$API_RETRIES), backing off" >&2
      sleep "$attempt"
    fi
  done
}

echo "[*] Scanning ALL repos of $OWNER (frontmatter contract + release gate) ..."

# Fetch all repos for the owner, exclude this repo.
# Enumerate ALL repos of the owner. search/repositories is used instead of
# /users/<owner>/repos because the latter returns an INCOMPLETE list of private
# repos (observed 2026-10: 25 of 47 returned, silently dropping blacklight-weekly
# and news-report). search returns the full set for user:<owner> queries.
# A freshly renamed repo may lag in the search index; that is a bounded delay
# (minutes) and self-heals on the next run, which is acceptable versus silently
# missing private repos forever.
if ! REPOS=$(api_call "search/repositories?q=user:$OWNER&per_page=100" --paginate \
  --jq '[.items[] | select(.full_name != "cgartlab/cgartlab-skills")
        | {name, full_name, description, updated_at, html_url}]' \
  | jq -s 'add // []'); then
  echo "[!] FATAL: could not list repos for $OWNER — refusing to write a partial catalog" >&2
  exit 1
fi

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

# Fetch SKILL.md into a file.
# Returns 0 on success, 2 when the file simply does not exist (normal skip),
# 1 on a genuine API failure. Callers log different reasons accordingly.
# Uses the raw media type so the API returns the decoded file directly —
# no base64 round-trip (which is fragile on Windows/MSYS for large files).
fetch_skill_md() {
  local full="$1" out="$2" rc=0
  api_call "/repos/$full/contents/SKILL.md" \
      -H "Accept: application/vnd.github.raw" > "$out" 2>/dev/null || rc=$?
  if [[ $rc -ne 0 ]]; then
    return $rc
  fi
  [[ -s "$out" ]] || return 2
  return 0
}

while IFS= read -r repo; do
  FULL_NAME=$(echo "$repo" | jq -r '.full_name')

  # --- Gate 1: SKILL.md must exist at the repo root -------------------------
  SKILL_MD_FILE="$TMP_DIR/skill.md"
  FETCH_RC=0
  fetch_skill_md "$FULL_NAME" "$SKILL_MD_FILE" || FETCH_RC=$?
  if [[ $FETCH_RC -ne 0 ]]; then
    if [[ $FETCH_RC -eq 2 ]]; then
      echo "[-] $FULL_NAME: no SKILL.md at root, skipped" >> "$SKIPPED_FILE"
    else
      echo "[!] $FULL_NAME: SKILL.md fetch failed (API error), skipped" >> "$SKIPPED_FILE"
    fi
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
  # A 404 means "this repo has no release" (normal skip). Any other failure is
  # annotated as an API error so a degraded run stays distinguishable from a
  # legitimately release-less repo.
  VERSION=""
  REL_RC=0
  RELEASE_JSON=$(api_call "/repos/$FULL_NAME/releases/latest" 2>/dev/null) || REL_RC=$?
  if [[ $REL_RC -eq 0 && -n "$RELEASE_JSON" ]]; then
    VERSION=$(echo "$RELEASE_JSON" | jq -r '.tag_name // empty' 2>/dev/null || true)
  fi
  if [[ -z "$VERSION" ]]; then
    if [[ $REL_RC -eq 0 ]]; then
      echo "[-] $FULL_NAME: no GitHub Release, skipped (release is mandatory)" >> "$SKIPPED_FILE"
    elif [[ $REL_RC -eq 2 ]]; then
      echo "[-] $FULL_NAME: no GitHub Release, skipped (release is mandatory)" >> "$SKIPPED_FILE"
    else
      echo "[!] $FULL_NAME: release lookup failed (API error), skipped" >> "$SKIPPED_FILE"
    fi
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

# --- Completeness guard (issue #13) ---------------------------------------
# A catalog written while the API was degraded would silently drop skills.
# Every repo must be accounted for: either catalogued, or explicitly skipped.
EXAMINED=$(( COUNT + $(wc -l < "$SKIPPED_FILE" | tr -d ' ') ))
if [[ "$TOTAL" -gt 0 && "$EXAMINED" -lt "$TOTAL" ]]; then
  echo "[!] FATAL: examined $EXAMINED of $TOTAL repos — refusing to write a partial catalog" >&2
  echo "[!] re-run once the API is healthy (rate-limit hits: $RATE_LIMIT_HITS, transient: $TRANSIENT_ERRORS)" >&2
  exit 1
fi
if [[ "$RATE_LIMIT_HITS" -gt 0 || "$TRANSIENT_ERRORS" -gt 0 ]]; then
  echo "[!] note: run completed with $RATE_LIMIT_HITS rate-limit hit(s) and $TRANSIENT_ERRORS transient error(s)" >&2
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
