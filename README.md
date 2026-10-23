# CGArtLab Skills Catalog

> 个人 AI Agent Skills 索引目录。
> 本仓库自动扫描 `cgartlab` 名下所有【公开/public】仓库，按 **SKILL.md frontmatter 契约 + Release 硬门槛** 收录，收集类型、摘要、版本和链接。

**授权**: [CC BY-NC-SA 4.0](LICENSE) · **来源**: [github.com/cgartlab/cgartlab-skills](https://github.com/cgartlab/cgartlab-skills)

---

## 📦 Skills

| Skill | Kind | Version | Description | Updated |
|-------|------|---------|-------------|---------|
| [blacklight-weekly](https://github.com/cgartlab/blacklight-weekly) | skill | v0.1.1 | An Agent Skill that automates the first-draft production of Blacklight Weekly. | 2026-10-18 |
| [news-report](https://github.com/cgartlab/news-report) | skill | v0.3.0 | news-report — a modular news-gathering Agent Skill: browse feeds and search articles across pluggable information sources (Miniflux RSS via MCP included). | 2026-10-18 |
| [person-profile](https://github.com/cgartlab/person-profile) | skill | v0.1.1 | 人物档案方法论独立 skill 项目（Skill for Person Profile Creation） | 2026-10-18 |

<sup>最后更新: 2026-10-18 · 收录条件：根目录 SKILL.md 的 frontmatter 含 name / description / metadata.kind（kind ∈ skill, agent, mcp），且仓库已发布 Release</sup>

---

## ➕ 添加新 Skill

只需在 `cgartlab` 账号下创建仓库（**名称不限**），并满足以下契约，本目录会在下次自动扫描时收录。

| 条件 | 说明 |
|------|------|
| 根目录存在 `SKILL.md` | 遵循 [Agent Skills 标准](https://agentskills.io) 的 skill 定义 |
| frontmatter 含 `name` 与 `description` | 技能名与触发描述 |
| frontmatter 含 `metadata.kind` | 取值 `skill` / `agent` / `mcp`，用于索引分类 |
| **已发布 Release** | `tag_name` 作为版本号；**无 Release 不收录** |

`SKILL.md` frontmatter 示例：

```yaml
---
name: my-skill
description: >-
  一句话说明这个 skill 做什么、何时触发。
metadata:
  kind: skill
---
```

其他建议文件：

| 文件 | 说明 |
|------|------|
| `README.md` | 项目的简明介绍 |
| License | 推荐 CC BY-NC-SA 4.0（与母仓库一致） |

## 🔄 更新方式

本仓库通过 GitHub Actions 自动更新（仅本仓调度，不响应也不控制其他仓库）：

- **定时扫描**: 每周一次
- **手动触发**: 前往 Actions → Update Skill Catalog → Run workflow

> 仅索引公开仓库，使用本仓默认 **GITHUB_TOKEN**，无需任何跨仓库 secret。

---

(C) 2026 CGArtLab · CC BY-NC-SA 4.0
