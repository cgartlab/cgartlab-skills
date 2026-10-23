# LESSONS — cgartlab-skills

> CGArtLab Skill 索引目录（GitHub Actions 自动扫描 `-skill` 仓库，按 SKILL.md frontmatter + Release 硬门槛收录）。
> 本仓库从真实失误沉淀的「教训→规则」清单。**会话开始先全文阅读并遵循其中所有规则**；出现新失误按 §维护 追加。
> 权威依据：Anthropic Claude Code memory/best practices（<200 行、具体可验证、第二次犯同样错即写入）；社区 lessons.md 惯例（Boris Cherny，Anthropic）。
> 来源：本仓库 AGENTS.md / README.md + 已验证 fix 提交；预填为种子，后续由 Agent 在真实工作中增长。

## 维护
- **触发**：用户纠正 / Agent 自查到的失误 / 非显而易见的 gotcha。
- **格式**：`### <主题>` 下，每条 = 失误（具体场景）→ 规则（最小可执行指令），一行可验证。
- **只记项目特有、不可从代码推断的**；通用最佳实践不写；含糊措辞（"小心""注意"）删掉。
- **重复出现** → 升级进 `AGENTS.md` 硬规则；**月度审阅**裁剪过期项；目标 < 200 行。

## 收录契约

### Release 硬门槛
- 失误：Skill 仓库没有 GitHub Release，扫描跳过不收录 → 规则：必须有 Release（`tag_name` 作为版本号），无 Release 不进入索引（见 AGENTS.md「检测规则」）

### frontmatter 必填字段
- 失误：SKILL.md frontmatter 缺 `metadata.kind`，扫描跳过 → 规则：frontmatter 必须含 `name`、`description` 与 `metadata.kind`（`kind` ∈ {skill, agent, mcp}），否则跳过（见 AGENTS.md「检测规则」）

### SKILL.md 必须在根目录
- 失误：SKILL.md 放在子目录，扫描时找不到 → 规则：仓库根目录必须存在 SKILL.md（见 AGENTS.md「检测规则」）

## CI 与自动化

### workflow 并发守卫
- 失误：多次 workflow 同时运行，catalog 重复更新冲突 → 规则：加 concurrency guard 防止并发（commit f121018）

### 跨平台 exec-bit
- 失误：gh mock 在不同平台不可执行，测试失败 → 规则：保持 gh mock 跨平台可执行（commit 61659f0）

### 无 Release 仓库容错
- 失误：扫描到无 Release 的仓库时脚本崩溃 → 规则：容忍无 Release 的仓库，跳过而非报错（commit 68657ec）

### release 查找失败需暴露
- 失误：release 查找失败被静默跳过，用户不知道哪些仓库被排除 → 规则：surface release lookup failures（commit 743cd39）

## 数据一致性

### dead-link 检测
- 失误：仓库改名后 skills.json 仍指向旧 URL，产生死链 → 规则：flag repos without SKILL.md as dead-link candidates（commit bd3bf8d）

### README 自动生成
- 失误：手动编辑 README.md，下次自动扫描覆盖手动改动 → 规则：README.md 由工作流自动生成，不要手动编辑（见 AGENTS.md「仓库结构」）

## Git 工作流

### 开 PR 前先对【当前】origin/main 做净 diff
- 失误：立正巡检时，分支相对会话开始时的 main 有净差异（如 2 个文件），于是计划开 PR；但 origin/main 在巡检过程中被 fetch 更新（或远端 tracking 本就比本地新），实际 main 已通过别的 PR 合入同等工作、并主动删除了那 2 个文件 → 分支已被 main 完全取代，开 PR 等于推翻 main 的删除决定，白干 → 规则：开 PR 前用 `git diff origin/main..HEAD`（必要时先 `git fetch`）取【当前】origin/main 的净差异；若净差异恰好是 main 最近一个 commit 故意删除的内容，废弃该分支而非开 PR。

### 本机跑 attention 的 bash 脚本需剥离 MSYS 路径转换
- 失误：本机 bash 环境设了 `MSYS2_ARG_CONV_EXCL=*` 与 `MSYS_NO_PATHCONV=1`，attention 的 `scripts/*.sh` 把原生 `git` 调用传 `D:/...` 路径时，关掉转换反而让脚本拿到裸盘符路径、部分 git 子命令静默失败（`grep Aborted`、采集字段缺失） → 规则：调用前 `env -u MSYS2_ARG_CONV_EXCL -u MSYS_NO_PATHCONV bash "<skill>/scripts/x.sh" --repo "D:/repo"`；仓库路径用原生 `D:/...` 正斜杠。
