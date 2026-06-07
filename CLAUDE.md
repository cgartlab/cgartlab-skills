# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

**CGArtLab Skills** is a meta-repository: a collection of [Agent Skills](https://agentskills.io) — Markdown instruction files that AI coding agents (Claude Code, OpenCode, OpenClaw, Codex CLI, Gemini CLI, GitHub Copilot, Cursor, Harmony) load on demand. The skills encode conventions for the CGArtLab ecosystem (Astro sites, EDIC design system, RSS automation, app-config, etc.). This repo is not a project; it ships `SKILL.md` files that get installed into `~/.claude/skills/` (or the equivalent path on other agents).

The repo follows the [Agent Skills open standard](https://agentskills.io): progressive disclosure (description → SKILL.md → references/assets), YAML frontmatter with `name` + `description`, and cross-agent compatibility.

## Repository layout

```
.
├── skills/<name>/SKILL.md      # One folder per skill (flat, not nested)
│   ├── references/             # Optional, for content >200 lines / 5000 tokens
│   └── assets/                 # Optional resource files
├── templates/                  # skill-template.md, reference-template.md
├── scripts/                    # new-skill.sh, validate.sh, dev-link.sh, install.sh
├── Makefile                    # All dev commands
├── AGENTS.md                   # Detailed authoring spec (read this before adding skills)
├── SKILLS_GUIDE.md             # Deep guide on writing skill descriptions/frontmatter
├── CONTRIBUTING.md             # PR checklist + commit conventions
├── README.md                   # Install + overview
└── LICENSE                     # CC BY-NC-SA 4.0
```

The `skills/` directory is the installable artifact. Everything else is repo infrastructure.

## Common commands

All development goes through the `Makefile` (uses `bash` and standard Unix tools; no Node/Python required):

```bash
make new name=<kebab-case>   # Scaffold skills/<name>/ from templates + create references/
make validate                # Check frontmatter, name↔dir match, naming regex — exit 1 on errors
make dev-link                # Symlink skills/* into ~/.claude/skills/ for live editing
make dev-unlink              # Remove those symlinks
make install                 # Copy (not link) skills/* into ~/.claude/skills/
make info                    # Print skill count
make help                    # List all targets
```

There is no build, no test suite, and no linter beyond `make validate`. `validate.sh` is the single quality gate — it checks each `SKILL.md` has YAML frontmatter, a `name` field matching its directory, a `description` field, and that the name matches `^[a-z0-9][a-z0-9-]*[a-z0-9]$` (kebab-case, no consecutive `--`, ≤64 chars).

The scripts can also be invoked directly: `scripts/new-skill.sh`, `scripts/validate.sh`, etc.

## The skill format (what Claude Code will load)

A skill is a single `SKILL.md` with this shape:

```markdown
---
name: <kebab-case>            # MUST match the directory name exactly
description: >-               # Three elements: what, when triggered, "Use ONLY when" scope
  Build X with Y conventions.
  Use ONLY when <trigger conditions>.
  Follows <reference>.
license: CC BY-NC-SA 4.0      # Optional
---

# <Title>

## 概述
## 核心规则         # Hard constraints, use checklists
## 工作流           # Step-by-step
## 示例
## 参考              # Link to references/*.md
```

Body markdown is loaded only when Claude Code's description-matching decides this skill is relevant. The `description` is the **only** thing visible to the dispatcher — it must include trigger keywords so Claude Code picks the right skill. The AGENTS.md and SKILLS_GUIDE.md go into much more depth on writing good descriptions (three-element rule: what/when/limit).

### Cross-agent compatibility constraint

The repo is deliberately portable. `name` and `description` are the only fields every supported agent reads. Don't add `metadata`, `context`, `allowed-tools`, or other Claude-Code-specific frontmatter — unsupported agents ignore them silently, but adding them violates the "any agent can load this" contract. See the compatibility table in `AGENTS.md`.

### When to split into `references/`

- `SKILL.md` exceeds 200 lines or ~5000 tokens, OR
- The content has clearly separable topics (e.g. token tables, API references)

References are loaded only when the agent explicitly needs them, keeping the main `SKILL.md` lean.

## Working on this repo

1. **Add a skill**: `make new name=foo-bar` → edit `skills/foo-bar/SKILL.md` → `make validate` → `make dev-link` → restart Claude Code to test.
2. **Edit a skill**: edit `SKILL.md` in place. If `dev-link` was run, the change is live after Claude Code restart (no reinstall).
3. **Add a reference doc**: create `skills/<name>/references/<topic>.md` and link it from `SKILL.md`'s `## 参考` section.
4. **Commit**: follow Conventional Commits with scope `skill`, `repo`, or no scope — see `CONTRIBUTING.md`. Examples: `feat(skill): add astro-content-site`, `fix(skill): tighten edic trigger conditions`, `chore(repo): update validate.sh`.

The CLAUDE.md that lives in this repo is itself a skill-description file consumed by Claude Code — it should stay short. The deeper authoring rules (description three-element rule, frontmatter field semantics, install modes) live in `AGENTS.md` and `SKILLS_GUIDE.md`; read those before writing or editing skills.
