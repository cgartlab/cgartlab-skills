# CONTRIBUTING.md — 贡献指南

## 前置条件

- `make`（GNU Make）
- `bash` 3.2+
- Git

## 添加新技能

```bash
make new name=<skill-name>
```

此命令会：
1. 创建 `skills/<skill-name>/` 目录
2. 从模板生成 `SKILL.md`
3. 创建 `references/` 子目录

## 编辑技能

1. 修改 `skills/<name>/SKILL.md`
2. 必要时更新 `references/` 中的引用文档
3. 运行 `make validate` 检查 frontmatter 和命名
4. 运行 `make dev-link` 使修改在全局立即生效

## 提交前检查清单

- [ ] `make validate` 通过
- [ ] `name` 字段匹配目录名
- [ ] `description` 包含"做什么"和"何时触发"
- [ ] SKILL.md 不超过 200 行（否则考虑拆分 references/）
- [ ] 遵循 Conventional Commits 格式

## 提交规范

```
<type>(<scope>): <简短描述>
```

| 类型 | 场景 | 示例 |
|------|------|------|
| `feat(skill)` | 新增技能 | `feat(skill): add astro-content-site` |
| `fix(skill)` | 修改技能内容 | `fix(skill): update EDIC token values` |
| `docs(skill)` | 技能文档/注释 | `docs(skill): clarify trigger conditions` |
| `docs(repo)` | 仓库文档 | `docs(repo): update README install steps` |
| `chore(repo)` | 仓库维护 | `chore(repo): update validate.sh script` |

## 安装测试

```bash
make dev-link     # 符号链接到 ~/.claude/skills/
# 重启 AI 代理，测试技能是否被正确加载
```

## 许可

提交即表示您同意您的贡献以 CC BY-NC-SA 4.0 授权。
