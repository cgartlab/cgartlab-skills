# Changelog

本仓库所有显著变更均记录于此。格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循[语义化版本](https://semver.org/lang/zh-CN/)。

本仓库无版本文件、无 Release Tag——`README.md` 与 `skills.json` 由 `bin/update-catalog.sh` 每次扫描重新生成，不构成对外发布的"版本"。因此本文件按**变更日期**而非版本号组织。

> 因本仓库无 Release Tag，各节标题不使用版本号，也不提供 compare 链接；条目内已有的 commit 短 SHA 即为溯源锚点。

## 2026-10-18（未发布）

> **一句话概括**：收录规则重写为 frontmatter 契约 + Release 硬门槛，扫描全部 cgartlab 仓库而非按 `-skill` 后缀过滤。影响：仓库改名不再影响收录，契约满足即自动收录；旧的硬编码例外列表作废。**你不需要做任何事**（索引自动更新），但若你维护的 skill 仓库尚未发布 Release，将不再被收录。

### Added

- **收录规则改为 frontmatter 契约 + Release 硬门槛**（D 方案）：扫描 `cgartlab` 名下**全部**仓库，不再按 `-skill` 后缀过滤，也不再维护硬编码例外列表（[c6819fa](https://github.com/cgartlab/cgartlab-skills/commit/c6819fa)）
  - 根目录必须存在 `SKILL.md`
  - frontmatter 必须含 `name`、`description`、`metadata.kind`
  - `metadata.kind` 必须在 `{skill, agent, mcp}` 内
  - 必须存在 latest GitHub Release，`tag_name` 作为版本号；**无 Release 不收录**（无回退）
- `skills.json` 新增 `kind` 字段；`README.md` 表格新增 `Kind` 列（[c6819fa](https://github.com/cgartlab/cgartlab-skills/commit/c6819fa)）
- 零依赖测试套件 `tests/`：mock `gh` 夹具 + `run_tests.sh`，6 用例 23 断言，覆盖 `release_ok` / `missing_kind` / `bad_kind` / `no_release` / `no_skill_md` / `api_error`（[975079e](https://github.com/cgartlab/cgartlab-skills/commit/975079e)、[c6819fa](https://github.com/cgartlab/cgartlab-skills/commit/c6819fa)）
- CI 质量门禁 `.github/workflows/ci.yml`：触及 `bin/**`、`tests/**` 时跑测试套件 + shellcheck（[0900c87](https://github.com/cgartlab/cgartlab-skills/commit/0900c87)）

### Changed

- `bin/update-catalog.sh` 改用 `search/repositories` 枚举仓库（[c6819fa](https://github.com/cgartlab/cgartlab-skills/commit/c6819fa)）
  - 原 `/users/<owner>/repos` 会漏私有仓库：实测仅返回 25/47，`blacklight-weekly` 与 `news-report` 被静默漏扫
- `SKILL.md` 改用 `Accept: application/vnd.github.raw` 直取（[c6819fa](https://github.com/cgartlab/cgartlab-skills/commit/c6819fa)）
  - 原 base64 解码在 MSYS 下不可靠，导致所有 SKILL.md 读取失败、收录数为 0
- 移除 `version_source` / `has_skill_md` 字段（[c6819fa](https://github.com/cgartlab/cgartlab-skills/commit/c6819fa)）——被 Release 硬门槛与 frontmatter 契约取代
- `AGENTS.md`「检测规则」与「添加新 Skill」两节同步为新契约（[c6819fa](https://github.com/cgartlab/cgartlab-skills/commit/c6819fa)）

### Fixed

- Windows/MSYS 下 `/repos/...` 被改写成文件路径（`C:/Program Files/Git/repos/...`）导致 API 报错：导出 `MSYS_NO_PATHCONV=1`（[c6819fa](https://github.com/cgartlab/cgartlab-skills/commit/c6819fa)）
- 测试夹具 `gh` mock 丢失可执行位导致 CI 取到真实无 token 的 `gh`：增加 `chmod +x`（[61659f0](https://github.com/cgartlab/cgartlab-skills/commit/61659f0)）
- `skill-catalog.yml` 自动提交无并发保护，并行 run 可能破坏提交历史：增加 `concurrency` guard（[f121018](https://github.com/cgartlab/cgartlab-skills/commit/f121018)）
- `fetch_links.py` 写 JSON 非原子，中断时可能留下半截文件（[f68ab73](https://github.com/cgartlab/cgartlab-skills/commit/f68ab73)，`cgartlab/blacklight-weekly`）

### Removed

- 硬编码例外列表（`news-report`、`person-profile`、`blacklight-weekly`）（[c6819fa](https://github.com/cgartlab/cgartlab-skills/commit/c6819fa)）
  - 取代 [be95087](https://github.com/cgartlab/cgartlab-skills/commit/be95087) 的方案；仓库改名不再影响收录，契约满足即自动收录

---

## 2026-08-02

> **一句话概括**：修复目录扫描漏收 `miniflux-mcp-skill` v0.1.0 的问题。影响：该 skill 重新出现在索引中。**你不需要做任何事**。

### Fixed

- 目录扫描正确收录 `miniflux-mcp-skill` v0.1.0（[29cdd07](https://github.com/cgartlab/cgartlab-skills/commit/29cdd07)）

---

## 2026-07-26 及更早

> **一句话概括**：项目定位调整为 Skill 索引目录（不再存放 SKILL.md），并完善扫描与容错。影响：索引从此由自动扫描生成。**你不需要做任何事**。

### Changed

- 项目定位调整为 Skill 索引目录，不再存放 SKILL.md（[ded761e](https://github.com/cgartlab/cgartlab-skills/commit/ded761e)）

### Added

- 支持 `--paginate` 扫描全部仓库（[08ab2d7](https://github.com/cgartlab/cgartlab-skills/commit/08ab2d7)）
- 收录 `person-profile`（[ec1d19d](https://github.com/cgartlab/cgartlab-skills/commit/ec1d19d)）
- 收录 `news-report`（原 `miniflux-mcp-skill` 更名，[71add99](https://github.com/cgartlab/cgartlab-skills/commit/71add99)）
- 收录 `blacklight-weekly`（原 `blacklight-weekly-skill` 更名，[75351d3](https://github.com/cgartlab/cgartlab-skills/commit/75351d3)）

### Fixed

- 用 search API 检测私有 `-skill` 仓库（[6b2f404](https://github.com/cgartlab/cgartlab-skills/commit/6b2f404)）
- 修正 jq 引号并增加 null 保护（[764ae3c](https://github.com/cgartlab/cgartlab-skills/commit/764ae3c)）
- 容错无 release 的 skill 仓库（[68657ec](https://github.com/cgartlab/cgartlab-skills/commit/68657ec)、[3ed8b64](https://github.com/cgartlab/cgartlab-skills/commit/3ed8b64)）
- 暴露 release 查询失败而非静默跳过（[743cd39](https://github.com/cgartlab/cgartlab-skills/commit/743cd39)）
