# tests/ — update-catalog.sh 测试套件

零依赖纯 bash 测试（无需 bats / 无需安装任何东西，Linux CI 与 Windows Git Bash 均可运行）。

## 运行

```bash
bash tests/run_tests.sh
```

退出码 0 = 全部通过；非 0 = 有失败（失败用例逐条打印）。

## 原理

`update-catalog.sh` 通过 PATH 上的 `gh` 和 `jq` 与外界交互。测试夹具（`tests/fixtures/`）提供一个 **mock `gh`**：读取环境变量 `MOCK_MODE` 决定返回什么。真实依赖只有 `jq`（脚本本体已声明 `Requires: gh, jq`，mock 掉 gh 后 jq 仍走真实二进制，覆盖脚本里的全部 jq 表达式）。

## 用例

| 用例 | 场景 | 覆盖的回归 |
|---|---|---|
| `release_ok` | 仓库有 release | 版本来自 tag_name（v0.3.0），version_source=release |
| `fallback_skill_md` | 无 release（404）、SKILL.md 有 metadata.version | 回退读 frontmatter，version_source=skill-md（2026-10 PR #22 修的崩溃点） |
| `no_skill_md` | 无 release、无 SKILL.md | version 为空、README 显示 —，不崩溃 |
| `api_error_survives` | search API 报错 | 脚本以非 0 退出并打印错误（fail-visible，不静默） |
| `version_pick_priority` | SKILL.md 有两行 version | frontmatter 语义：取第一个（顶部） |
