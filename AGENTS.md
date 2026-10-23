# AGENTS.md — cgartlab-skills

> **会话约定**：开始任何工作前，先读根目录 `LESSONS.md`（本仓库从真实失误沉淀的「教训→规则」清单）并遵循其中所有规则；遇到新失误按其 §维护 追加。

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
| 定时 (每周日 06:00 UTC) | 扫描 `cgartlab` 名下所有【公开】仓库，更新 `skills.json` + `README.md` |
| 手动触发 (workflow_dispatch) | 同上 |

> ⚠️ 本仓库**不**提供、监听或消费任何来自其他 skill 仓库的触发 / 工作流 / 复用流程（已移除 `repository_dispatch`，禁用跨仓库控制）。

### 检测规则

```
扫描 cgartlab 名下所有【公开/public】仓库（排除 cgartlab-skills 自身；不索引私有仓库）
  → 仓库根目录必须存在 SKILL.md，否则跳过
  → 解析 SKILL.md YAML frontmatter，必须包含 name、description 与 metadata.kind，
     且 metadata.kind 必须在 {skill, agent, mcp} 中，否则跳过
  → 必须存在 latest GitHub Release（tag_name 作为版本号），无 release 则跳过
  → 写入 skills.json（新增 kind 字段）+ 渲染 README.md（新增 Kind 列）
```

---

## 添加新 Skill

1. 在 cgartlab 账号下创建仓库（名称不限）
2. 仓库根目录放入 `SKILL.md`，frontmatter 必须包含 `name`、`description` 与 `metadata.kind`
   （`kind` 取值：`skill` / `agent` / `mcp`，遵循 Agent Skills 标准）
3. 发布 Release 生成版本号（**必须有 Release**，否则不进入索引）
4. 本目录在下一次自动扫描时按上述契约自动收录

---

## 前置条件

无特殊 secret。自动化使用本仓库工作流的默认 **GITHUB_TOKEN**（`contents: write`，仅用于提交 `skills.json` / `README.md`）。

> 历史遗留的 **SKILL_CATALOG_PAT**（scope: `repo`）已不再需要——本仓库只索引公开仓库、且对其他仓库保持只读，应**删除**该 secret 以消除跨仓库写风险。

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
