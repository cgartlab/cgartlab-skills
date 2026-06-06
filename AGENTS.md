# AGENTS.md — cgartlab-skills

**分层**: 元层 (Meta) — 知识管理

**授权**: CC BY-NC-SA 4.0

---

CGArtLab 生态系统 AI 技能仓库。本仓库存储、管理和维护所有用于 AI 编码代理（OpenCode、Claude Code、OpenClaw、Codex CLI、Gemini CLI、GitHub Copilot、Harmony 等）的 Agent Skills。

本仓库**不是项目配置文件**——只存放遵循 Agent Skills 开放标准（[agentskills.io](https://agentskills.io)）的纯 `SKILL.md` 文件，任何兼容该标准的 AI 代理均可直接加载使用。

---

## 目录结构

```
cgartlab-skills/
├── skills/                     # ── 扁平技能目录 ──
│   └── <skill-name>/           #     skills/<name>/SKILL.md
│       ├── SKILL.md            #     必需：元数据 + 指令
│       ├── references/         #     可选：深度技术文档
│       └── assets/             #     可选：资源文件
├── templates/                  # 技能模板
│   ├── skill-template.md
│   └── reference-template.md
├── scripts/                    # 工具脚本
│   ├── install.sh
│   ├── dev-link.sh
│   ├── validate.sh
│   └── new-skill.sh
├── .editorconfig
├── .gitignore
├── AGENTS.md                   # 本文件
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── Makefile
├── README.md
└── SKILLS_GUIDE.md
```

---

## Skill 命名规范

```
skills/<name>/SKILL.md
```

| 规则 | 说明 |
|------|------|
| 命名风格 | `kebab-case` — 全小写字母、数字、单连字符 |
| 长度 | 1–64 字符 |
| 禁止 | 首尾连字符、连续 `--`、大写、下划线、空格 |
| 一致性 | 目录名 **必须精确匹配** `SKILL.md` 中 `name` 字段 |

✅ 合法示例：`astro-content-site`、`edic-design-system`、`go-cli-tool`
❌ 非法示例：`Astro-Content-Site`（大写）、`astro_content_site`（下划线）、`astro--site`（双连字符）

## SKILL.md 格式

```markdown
---
name: <skill-name>               # 必需，匹配目录名
description: >-                  # 必需，"做什么 + 何时触发"
  One to three sentences.
  First: what the skill does.
  Second: when to use it (trigger phrases).
license: CC BY-NC-SA 4.0         # 可选
compatibility: (omit)            # 可选，省略以保持通用
metadata: (omit)                 # 可选，省略以保持通用
---

# Skill Name

(markdown instructions below frontmatter)
```

### 跨 Agent 兼容性原则

本仓库的 skill 遵循 Agent Skills 开放标准。**仅使用所有 Agent 通用的字段**：

| 字段 | OpenCode | Claude Code | OpenClaw | Copilot | Codex CLI | Gemini CLI |
|------|:--------:|:-----------:|:--------:|:-------:|:---------:|:----------:|
| `name` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `description` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `license` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| `compatibility` | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `metadata` | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |

> **黄金法则**：只使用 `name` + `description` 可保证 100% 跨 Agent 兼容。其他字段被不支持的 Agent 安全忽略，不会报错。

### description 编写规范

```yaml
description: >-
  [功能描述] [技术栈]。
  Use ONLY when [具体触发条件]。
  遵循 [参考来源] 约定。
```

示例：
```yaml
description: >-
  Generate EDIC design system components with OKLch tokens, dark mode,
  and CJK typography. Use ONLY when building UI for any cgartlab project.
  Follows the EDIC token system and BEM naming conventions.
```

三要素：
1. **做什么** — 功能 + 技术（首句）
2. **何时触发** — 关键词、文件类型、场景（第二句）
3. **限制条件** — `Use ONLY when` 缩小触发范围（避免误激活）

### references/ 子目录

当 SKILL.md 超过 200 行或涉及可分离的知识点时，拆分为 `references/` 中的独立文件：

```
skills/<name>/
├── SKILL.md              # 核心指令（保持精简）
├── references/
│   ├── token-reference.md
│   ├── component-api.md
│   └── deployment.md
└── assets/
    └── example-output.html
```

Agent 按需加载引用文件，不占用系统提示上下文。

---

## 开发命令

```bash
make new name=<skill-name>     # 从模板创建新技能
make validate                  # 验证所有技能 frontmatter + 命名
make dev-link                  # 符号链接到 ~/.claude/skills/
make dev-unlink                # 移除符号链接
make install                   # 复制安装到 ~/.claude/skills/
make info                      # 显示技能统计
make help                      # 全部命令
```

---

## Git 提交规范

```
<type>(<scope>): <description>
```

| 类型 | 场景 |
|------|------|
| `feat(skill)` | 新增技能 |
| `fix(skill)` | 修改技能内容 |
| `docs(skill)` | 修改技能文档/注释 |
| `docs(repo)` | 修改仓库文档（README 等） |
| `chore(repo)` | 仓库维护、工具脚本、CI |

示例：
- `feat(skill): add astro-content-site skill`
- `docs(skill): update description triggers for edic-design-system`
- `chore(repo): add validate.sh script`

---

## 版权

(C) 2026 CGArtLab · CC BY-NC-SA 4.0
