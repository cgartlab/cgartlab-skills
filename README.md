# CGArtLab Skills Catalog

> 这里汇集了 CGArtLab 名下所有**公开**的 AI Agent Skills，自动扫描、自动更新。

**授权**: [CC BY-NC-SA 4.0](LICENSE) · **仓库**: [github.com/cgartlab/cgartlab-skills](https://github.com/cgartlab/cgartlab-skills)

---

## 这是什么？

**Skill（技能）** 是一段让 AI 助手学会做某件事的说明包：它用一份 `SKILL.md` 告诉 AI 这个技能做什么、什么时候用、具体怎么做。你平时用到的各种自动化能力，大多就是一个个 skill。

本仓库是一个**索引目录**——它不存放技能本身，只负责：

- 扫描 `cgartlab` 名下所有**公开仓库**
- 检查每个仓库是否符合收录标准（见下文）
- 把通过的技能整理成下面的列表，附上类型、版本和链接

> 为什么只收公开仓库？因为索引目录只读取公开信息，不碰私有仓库，也不代替你控制任何技能仓库。

## 📦 Skills

| Skill | Kind | Version | Description | Updated |
|-------|------|---------|-------------|---------|
| [news-report](https://github.com/cgartlab/news-report) | skill | v0.3.0 | news-report — a modular news-gathering Agent Skill: browse feeds and search articles across pluggable information sources (Miniflux RSS via MCP included). | 2026-10-23 |
| [person-profile](https://github.com/cgartlab/person-profile) | skill | v0.2.2 | 人物档案方法论独立 skill 项目（Skill for Person Profile Creation） | 2026-10-23 |

<sup>最后更新: 2026-10-25 · 收录条件：仓库根目录的 `SKILL.md` frontmatter 含 `name` / `description` / `metadata.kind`（kind 为 `skill`、`agent` 或 `mcp`），且已发布 Release</sup>

> **Kind 是什么？** 它标明了技能的类别：`skill`（普通技能）/ `agent`（可自主跑一段任务的代理）/ `mcp`（对接某个 MCP 服务的技能）。

---

## ➕ 怎么让我的 Skill 出现在这里？

只要满足下面四条，本目录**下一次自动扫描时就会自动收录你**，不用提交 PR：

| 条件 | 说明 |
|------|------|
| 仓库根目录有 `SKILL.md` | 按 [Agent Skills 标准](https://agentskills.io) 写好这份说明 |
| frontmatter 含 `name` 与 `description` | 技能的**名字**和**一句话说明**（什么时候该用） |
| frontmatter 含 `metadata.kind` | 填 `skill` / `agent` / `mcp`，用于分类 |
| **已发布 Release** | Release 的 `tag` 就是版本号；**没发 Release 不会被收录** |

`SKILL.md` 开头这样写就行：

```yaml
---
name: my-skill
description: >-
  一句话说明这个 skill 做什么、何时触发。
metadata:
  kind: skill
---
```

另外建议顺便准备的：

| 文件 | 说明 |
|------|------|
| `README.md` | 给使用者看的简明介绍 |
| License | 推荐 CC BY-NC-SA 4.0（和本仓库一致） |

## 🔄 目录怎么保持最新？

完全自动，不需要你手动维护：

- **定时扫描**：每周一次，自动检查并更新
- **手动触发**：随时可去仓库的 Actions → Update Skill Catalog → Run workflow 立即更新

> 整个过程只用本仓库自己的 **GITHUB_TOKEN**，不依赖任何跨仓库的密钥，也不会改动你其他的技能仓库。

---

(C) 2026 CGArtLab · CC BY-NC-SA 4.0
