# CGArtLab Skills

为 CGArtLab 生态系统开发的 AI 代理技能集合。

**授权**: [CC BY-NC-SA 4.0](LICENSE) · **来源**: [github.com/cgartlab/cgartlab-skills](https://github.com/cgartlab/cgartlab-skills)

---

## 概述

本仓库存储、管理和维护所有 CGArtLab 生态系统的 Agent Skills。这些技能编码了开发最佳实践、项目约定和工作流程，让 AI 编码代理（OpenCode、Claude Code、OpenClaw、Codex CLI、GitHub Copilot 等）能够高效地在 CGArtLab 项目中工作。

### CGArtLab 生态系统

```
                    ┌──────────────────────────────────┐
                    │      cgartlab-skills (本仓库)      │
                    │  知识层 — AI 辅助开发的技能编码      │
                    └──────────────────────────────────┘
                                │
         ┌──────────────────────┼──────────────────────┐
         │                      │                      │
    ┌────▼──────────┐    ┌─────▼──────┐    ┌──────────▼──────┐
    │ 品牌 & 内容    │    │  设计系统   │    │  基础设施 & 工具  │
    │ cgartlab      │    │  EDIC      │    │ app-config       │
    │ .github.io    │    │  Design    │    │ SwiftInstall     │
    │ animpoly-com  │    │  System    │    │ goto-github      │
    │ guoxue        │    │            │    │ cgartlab (RSS)   │
    └───────────────┘    └────────────┘    └─────────────────┘
```

## 安装

### 方式一：符号链接（推荐，修改即时生效）

```bash
git clone https://github.com/cgartlab/cgartlab-skills.git
cd cgartlab-skills
make dev-link
```

所有技能立即可被 `~/.claude/skills/` 目录下的任何 Agent 发现使用。

### 方式二：复制安装

```bash
make install
```

### 方式三：curl 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/cgartlab/cgartlab-skills/main/scripts/install.sh | bash
```

### 验证安装

安装后重启你的 AI 代理，然后询问"列出所有可用的技能"来验证。

## 仓库结构

```
cgartlab-skills/
├── skills/             # 技能目录（扁平结构）
│   └── <name>/         # skills/<name>/SKILL.md
│       ├── SKILL.md    # 必需：元数据 + 指令
│       ├── references/ # 可选：深度技术参考
│       └── assets/     # 可选：资源文件
├── templates/          # 技能模板
├── scripts/            # 工具脚本
├── AGENTS.md           # AI 代理开发规范
├── SKILLS_GUIDE.md     # Skill 编写深度指南
├── CONTRIBUTING.md     # 贡献指南
├── Makefile            # 开发命令
└── LICENSE             # CC BY-NC-SA 4.0
```

## 开发

```bash
make new name=<skill-name>  # 创建新技能
make validate               # 验证所有技能
make dev-link               # 符号链接到全局
make info                   # 技能统计
```

详细指南请参见 [SKILLS_GUIDE.md](SKILLS_GUIDE.md) 和 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 关于

(C) 2026 CGArtLab · CC BY-NC-SA 4.0

本仓库遵循 [Agent Skills 开放标准](https://agentskills.io)，所有技能文件与 OpenCode、Claude Code、OpenClaw、Codex CLI、Gemini CLI、GitHub Copilot 等 AI 代理完全兼容。
