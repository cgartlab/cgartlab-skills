# CGArtLab Skills Catalog

> 个人 AI Agent Skills 索引目录。
> 本仓库自动扫描 `cgartlab` 名下所有后缀为 `-skill` 的仓库，收集摘要、版本和链接。

**授权**: [CC BY-NC-SA 4.0](LICENSE) · **来源**: [github.com/cgartlab/cgartlab-skills](https://github.com/cgartlab/cgartlab-skills)

---

## 📦 Skills

| Skill | Version | Description | Updated |
|-------|---------|-------------|---------|
| [blacklight-weekly-skill](https://github.com/cgartlab/blacklight-weekly-skill) | v0.1.1 | An Agent Skill that automates the first-draft production of Blacklight Weekly. | 2026-07-08 |
| [miniflux-mcp-skill](https://github.com/cgartlab/miniflux-mcp-skill) | v0.1.0 | Miniflux MCP server integration — browse feeds, search articles, and manage RSS reading from AI conversations. | 2026-07-31 |

<sup>最后更新: 2026-08-16 · 自动检测 `*-skill` 仓库</sup>

---

## ➕ 添加新 Skill

只需在你的 GitHub 账号下创建一个以 `-skill` 结尾的公开或私有仓库，本目录会在下次自动扫描时收录。

建议每个 skill 仓库包含：

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 遵循 [Agent Skills 标准](https://agentskills.io) 的 skill 定义 |
| `README.md` | 项目的简明介绍 |
| License | 推荐 CC BY-NC-SA 4.0（与母仓库一致） |

## 🔄 更新方式

本仓库通过 GitHub Actions 自动更新：

- **定时扫描**: 每周一次
- **手动触发**: 前往 Actions → Update Skill Catalog → Run workflow
- **自动触发**（可选）: skill 仓库 release 时可配置 webhook 触发更新

> 要求仓库设置 **SKILL_CATALOG_PAT** secret（GitHub Personal Access Token，scope: `repo`）。

---

(C) 2026 CGArtLab · CC BY-NC-SA 4.0
