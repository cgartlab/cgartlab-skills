# SKILLS_GUIDE.md — Skill 编写深度指南

**授权**: CC BY-NC-SA 4.0

---

## 关于 Agent Skills

Agent Skills 是一个开放标准（[agentskills.io](https://agentskills.io)），起源于 Anthropic 的 Claude Code，现已得到所有主流 AI 编码代理的支持：

- OpenCode · Claude Code · OpenClaw · Codex CLI · Gemini CLI · GitHub Copilot · Cursor · Harmony

核心思想：**渐进式披露**——Agent 只在需要时加载技能内容，保持上下文精简。

```
用户提问
  → Agent 扫描所有技能 description（～100 tokens，始终在上下文中）
    → 匹配到相关技能 → 加载 SKILL.md 正文（＜5000 tokens）
      → 按需加载 references/*.md、scripts/、assets/
```

---

## 编写 SKILL.md

### 1. 结构模板

```markdown
---
name: <skill-name>
description: >-
  [功能]。Use ONLY when [触发条件]。
---

# Skill Name

## 概述
一两句话说明此技能解决什么问题、遵循哪些约定。

## 核心规则
- 硬性约束（不可违反的规则）
- 使用 checklist 语法

## 工作流
1. 步骤一
2. 步骤二
3. 步骤三

## 示例
``` ... ```

## 参考
- `references/detailed-guide.md`
```

### 2. description 编写原则

**好的 description**：
```yaml
description: >-
  Build Astro content sites with CGArtLab conventions — component patterns,
  content collections, i18n, UnoCSS tokens, Cloudflare deployment.
  Use ONLY when asked to create or modify Astro pages, components,
  or content in any cgartlab project.
```

**差的 description**：
```yaml
description: Helps with Astro development
```

三要素检查表：

| 要素 | 要求 | 示例 |
|------|------|------|
| **做什么** | 功能 + 技术栈 | "Build Astro content sites with CGArtLab conventions" |
| **何时触发** | 关键词、场景 | "Use ONLY when...create or modify Astro pages..." |
| **限制条件** | 缩小触发范围 | "Use ONLY when" 防止误激活 |

### 3. 跨 Agent 兼容

**黄金法则：只使用所有 Agent 都支持的字段。**

```markdown
---
name: my-skill
description: What and when.
---
```

这 3 行在任何 Agent 上都能工作。不要添加 agent 专属字段（如 `metadata.openclaw`、`context: fork`），它们虽然被忽略，但这会降低可移植性。

### 4. 何时拆分 references/

当出现以下情况之一时，将内容从 SKILL.md 拆分为 `references/` 文件：

- SKILL.md 超过 **200 行**或 **5000 tokens**
- 有独立的知识点（如完整的 API 文档、令牌表）
- 有大型代码示例

```
skills/my-skill/
├── SKILL.md                     # 核心工作流（保持精炼）
├── references/
│   ├── token-reference.md       # 令牌完整表格
│   ├── cli-commands.md          # CLI 命令参考
│   └── migration-guide.md       # 迁移指南
└── assets/
    └── example-output.html
```

在 SKILL.md 中引用：
```markdown
## 参考
- `references/token-reference.md` — 完整令牌定义
- `references/cli-commands.md` — CLI 命令详解
```

---

## 目录与命名速查

| 项目 | 规则 |
|------|------|
| 技能目录 | `skills/<kebab-case-name>/` |
| SKILL.md | 严格大小写 `SKILL.md`，不可写成 `skill.md` |
| `name` 字段 | 必须匹配目录名 |
| 参考文献 | `references/*.md`，无大小写要求 |
| 资源文件 | `assets/*`，任意格式 |
| 脚本 | `scripts/*`，可执行文件 |

---

## 开发流程

```bash
make new name=my-skill     # 创建技能骨架
# 编辑 skills/my-skill/SKILL.md
make validate              # 验证 frontmatter + 命名
make dev-link              # 符号链接到全局生效
# 测试后提交
git add skills/my-skill/
git commit -m "feat(skill): add my-skill"
```

---

## 版权

(C) 2026 CGArtLab · CC BY-NC-SA 4.0
