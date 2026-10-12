# CGArtLab Skills Catalog

> 个人 AI Agent Skills 索引目录。
> 本仓库自动扫描 `cgartlab` 名下以 `-skill` 结尾的仓库，并显式收录 `cgartlab/news-report`（由原 miniflux-mcp-skill 更名而来）与 `cgartlab/person-profile`（早于 -skill 命名约定的 skill 仓），收集摘要、版本和链接。

**授权**: [CC BY-NC-SA 4.0](LICENSE) · **来源**: [github.com/cgartlab/cgartlab-skills](https://github.com/cgartlab/cgartlab-skills)

---

## 📦 Skills

| Skill | Version | Description | Updated |
|-------|---------|-------------|---------|
| [news-report](https://github.com/cgartlab/news-report) | v0.3.0 | news-report — a modular news-gathering Agent Skill: browse feeds and search articles across pluggable information sources (Miniflux RSS via MCP included). | 2026-09-19 |
| [person-profile](https://github.com/cgartlab/person-profile) | 0.1.1 | 人物档案方法论独立 skill 项目（Skill for Person Profile Creation） | 2026-10-05 |

<sup>最后更新: 2026-10-12 · 自动检测以 `-skill` 结尾的仓库及显式收录的 `news-report`、`person-profile`</sup>

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
