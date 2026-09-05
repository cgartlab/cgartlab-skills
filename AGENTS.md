# AGENTS.md — cgartlab-skills

**分层**: 元层 (Meta) — Skill 索引目录

**授权**: CC BY-NC-SA 4.0

---

本仓库是 [CGArtLab](https://github.com/cgartlab) 名下所有个人 AI Agent Skills 的**索引目录**。

本仓库**不存放 SKILL.md 文件**，只维护一个自动更新的 README 页面，汇总所有以 `-skill` 后缀的仓库的摘要、版本和项目链接。

---

## 仓库结构

```
cgartlab-skills/
├── .github/workflows/
│   └── skill-catalog.yml      # GitHub Actions 自动更新工作流
├── bin/
│   └── update-catalog.sh      # 检测 + 生成脚本
├── skills.json                # Skill 元数据缓存（由工作流自动更新）
├── README.md                  # Skill 索引目录（由工作流自动生成）
├── AGENTS.md                  # 本文件
├── LICENSE                    # CC BY-NC-SA 4.0
└── .gitignore
```

---

## 自动化流程

| 事件 | 行为 |
|------|------|
| 定时 (每周日 06:00 UTC) | 扫描所有 `-skill` 仓库，更新 `skills.json` + `README.md` |
| 手动触发 (workflow_dispatch) | 同上 |
| `repository_dispatch` (webhook) | 可配置从 skill 仓库的 release/push 触发更新 |

### 检测规则

```
扫描 cgartlab 名下所有仓库
  → 筛选名称以 -skill 结尾，或命中显式例外 news-report
     （例外理由：原 miniflux-mcp-skill 已更名 cgartlab/news-report，
      更名后不再以 -skill 结尾，但仍属官方 skill 仓库，需继续收录）
  → 排除 cgartlab-skills 自身
  → 对每个仓库获取 description + latest release version
  → 写入 skills.json + 渲染 README.md
```

---

## 添加新 Skill

1. 在 cgartlab 账号下创建仓库，名称以 `-skill` 结尾
2. 建议包含 `SKILL.md`（遵循 Agent Skills 标准）
3. 发布 Release 以生成版本号
4. 本目录在下一次自动扫描时收录

---

## 前置条件

仓库 Secret **SKILL_CATALOG_PAT**（GitHub Personal Access Token, scope: `repo`），用于从私有仓库读取元数据。

---

## Git 提交规范

```
<type>(<scope>): <description>
```

例：
- `chore(catalog): auto-update skill registry` — 自动化生成的更新
- `feat(catalog): add <skill-name>` — 手动添加条目
- `chore(repo): update AGENTS.md` — 仓库维护

---

(C) 2026 CGArtLab · CC BY-NC-SA 4.0
