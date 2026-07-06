# gsd (Get Shit Done)

## 基本信息

- **原始仓库**: github.com/gsd-build/get-shit-done —— 已 **Archived**（约 64.6K stars，MIT，作者 TÂCHES / Lex Christopherson "glittercowboy"）
- **社区延续仓库（当前活跃）**: github.com/open-gsd/gsd-core（原始维护者 2026 年 5 月失联并牵涉 $GSD Solana 代币 rug-pull 争议后，由协作者接手社区版）
- **安装**: `npx get-shit-done-cc@latest`（原始）/ `npx @opengsd/gsd-core@latest`（社区版），强制走 Node 安装器，不支持直接拷贝 agents/commands 文件
- **目标 host**: 以 Claude Code 为核心，社区版宣称支持 13+ runtime：Claude Code、OpenCode、Gemini CLI、Kimi CLI、Codex、Copilot、Cursor、Windsurf、Kilo 等
- **规模**: 巅峰 59.6K+ stars、138 贡献者、2100+ commits，是 Claude Code 生态最火的 workflow 框架之一

## 定位与设计哲学

**一句话定位**：一个"元提示 + 上下文工程 + 规格驱动开发"系统，把项目拆成原子计划，每个计划在全新 200K 上下文的 subagent 中执行，用 git 提交和结构化文档缝合结果。

**它认为 agent 编码的核心问题是 "context rot"（上下文腐烂）**：agent 随着上下文窗口被填满，输出质量逐渐降解、失去连贯性。GSD 的答案是把上下文窗口当作**受管资源**：
- 主会话只做编排，保持在 30-40% 上下文占用
- 重活分发到 fresh-context subagent
- 跨会话记忆靠持久化结构文档（`.planning/` 目录）而非上下文本身
- Planner 明确规则："Plans should complete within ~50% context (not 80%). No context anxiety, quality maintained start to finish."

## 核心机制

### 文件结构（`.planning/` = 项目外置记忆）

```
.planning/
  PROJECT.md        # 项目整体语境
  REQUIREMENTS.md   # 范围化需求
  ROADMAP.md        # 阶段化路线图
  STATE.md          # 项目记忆与当前位置（跨会话恢复的锚点）
  CONTEXT.md        # 讨论阶段的决策记录
  config.json       # 用户偏好与 workflow 设置（如 auto_advance）
  research/         # 自动研究产出
  <phase>/PLAN.md   # XML 格式的原子任务计划
  <phase>/SUMMARY.md# 执行审计报告
  <phase>-UAT.md    # 验收测试记录
```

### 命令与 agent 体系

- **~70 个 slash 命令**（commands/gsd/，如 new-project、discuss-phase、plan-phase、execute-phase、verify-work、map-codebase、quick、debug、pause-work、resume-work、ship、audit-milestone、code-review、security phase 等）
- **34 个专职 subagent**（agents/，如 gsd-planner、gsd-executor、gsd-verifier、gsd-debugger、gsd-code-reviewer、gsd-security-auditor、gsd-roadmapper、gsd-phase-researcher、gsd-codebase-mapper 等）
- 另有 `gsd-tools` SDK（query handler 形式）供 agent 结构化读写 STATE.md/ROADMAP.md：`state.advance-plan`、`state.record-metric`、`roadmap.update-plan-progress`、`requirements.mark-complete` 等

### 五步阶段循环（Phase Loop）

1. **Discuss**（/gsd:discuss-phase）— 提前锁定实现决策（编号 D-01、D-02…，planner 规定 "User decisions are locked… must be implemented exactly as specified"）
2. **Plan**（/gsd:plan-phase）— 研究 + 分解为 XML PLAN.md
3. **Execute**（/gsd:execute-phase）— subagent 按 wave 并行执行，逐任务原子提交
4. **Verify**（/gsd:verify-work）— 对话式 UAT，逐特性验证，失败自动诊断根因并生成修复计划回灌 execute
5. **Ship**（/gsd:ship）— 建 PR、归档阶段、进入下一阶段

### PLAN.md 结构（可执行 XML 而非散文）

每计划 2-3 个任务，每任务含 `<files>`（精确路径）、`<action>`（指令，禁止内嵌代码块）、`<verify>`（<60 秒可自动执行的验证命令，"Manual-only checks are forbidden"）、`<done>`（可度量验收标准）。任务按 **wave** 分配依赖并行：同 wave 且零文件交集的计划并行执行。倾向 "vertical slices over horizontal layers"。

### 执行纪律（gsd-executor）

- 逐任务 execute → verify → commit；`tdd="true"` 强制 RED→GREEN→REFACTOR
- **偏差四规则**：Rule 1 自动修 bug；Rule 2 自动补关键缺失（校验/错误处理/安全）；Rule 3 自动修阻塞问题；Rule 4 架构级变更必须问人。每任务 3 次自动修复上限，超限记入 SUMMARY 继续走
- 提交规范：只 `git add <file>` 逐个加、禁止 `add .`；消息格式 `{type}({phase}-{plan}): {description}`
- worktree 安全：断言 cwd 未漂移、HEAD 必须在 `worktree-agent-*` 分支（deny-list main/master/develop）；**禁止** `git clean/stash/reset --hard/checkout -- .` 及向保护分支 force-push
- 不自动装包：包合法性存疑触发 `checkpoint:human-verify gate="blocking-human"`

## 步骤流覆盖

| 步骤 | 覆盖 | 做法 |
|---|---|---|
| 澄清意图 | ✅ 强 | new-project 四阶段（Questioning→Research→Requirements→Roadmap）深挖目标/范围/约束；discuss-phase 每阶段前锁定编号决策 D-xx |
| 治理上下文 | ✅ 极强（招牌能力） | fresh-context subagent + 50% 上下文预算 + `.planning/` 外置记忆 + 主会话保持精简；brownfield 用 /gsd:map-codebase 建立代码库地图 |
| 写清规格 | ✅ 强 | REQUIREMENTS.md + XML PLAN.md（files/action/verify/done 四要素）+ goal-backward must-haves 推导（从结果倒推 observable truths→artifacts→wiring→critical links）|
| 小步切片 | ✅ 强 | 每计划 2-3 任务、每任务提交原子化、>5 文件或跨子系统即拆分、wave 依赖图并行、垂直切片原则 |
| 实现功能 | ✅ | gsd-executor 按计划执行，偏差规则 1-4 分级处理，TDD 可选强制 |
| 验证证据 | ✅ 强 | 每任务 `<verify>` 强制自动化命令（禁纯手工验证，无测试则 Wave 0 先补）；SUMMARY.md 记录 commit hash、deviations、threat flags、known stubs、self-check |
| 独立审查 | ✅ 中强 | 专职 gsd-verifier / gsd-code-reviewer / gsd-security-auditor / gsd-plan-checker subagent；plan-review-convergence、audit-milestone 命令；但更多是同框架内的角色分离而非真正独立第三方 |
| 可控发布 | ✅ 中 | /gsd:ship 建 PR + 归档阶段；worktree 分支隔离 + 保护分支 deny-list；无部署/回滚/灰度概念（面向开发流程而非交付流水线）|
| 复盘沉淀 | ✅ 中 | SUMMARY.md 审计轨迹、extract-learnings、mempalace-capture/recall（记忆宫殿）、milestone-summary、stats；但沉淀主要留在 `.planning/`，反哺规则库的闭环较弱 |

## 横切能力覆盖

- **Task State 中断恢复**: ✅ 强。STATE.md 为唯一事实源，SDK 查询结构化推进（state.advance-plan 等）；专门的 /gsd:pause-work、/gsd:resume-work、/gsd:progress、/gsd:next 命令；SUMMARY frontmatter 记 status/duration。
- **Journal-Trace**: ✅ 强。每计划 SUMMARY.md（deviations + commit hash 逐条对应）、decisions 记入 STATE、UAT.md 测试轨迹、原子 commit 即天然 trace。
- **Safety Guardrails**: ✅ 强且具体。禁破坏性 git 命令清单、worktree 边界断言、分支 deny/allow-list、逐文件 staging、包安装人工门禁、架构变更必须问人（Rule 4）、auto 模式下 `gate="blocking-human"` 不可跳过。
- **Tool Compatibility 跨 host**: ⚠️ 中。社区版宣称 13+ runtime，靠 Node 安装器按 runtime 生成适配文件；但 prompt 深度依赖 Claude Code 语义（subagent/Task、Write 工具、slash command、200K 窗口假设），其他 host 上体验打折。
- **Runtime-Scripts 机器验证下沉**: ⚠️ 部分。`<verify>` 强制自动化命令是机器验证；有 gsd-tools SDK 把状态读写下沉为结构化查询；但大量编排逻辑仍在长 prompt 里由 LLM 执行，非确定性脚本。

## 独特亮点

1. **上下文预算工程做到量化级别**：不只是"开 subagent"，而是给出任务复杂度→上下文占比表（CRUD 10-15%、auth 20-30%、迁移 30-40%）、50% 硬预算、拆分信号清单——把 context rot 从口号变成可执行纪律。
2. **可执行 XML 计划 + goal-backward 验证**：PLAN.md 的 files/action/verify/done 四要素强制每个任务自带机器验证；must-haves 从目标倒推可观察事实，防止"做了很多但没达成目标"。
3. **执行器的工程化偏差协议**：Rule 1-4 分级自动修复/人工门禁 + 3 次上限 + deviations 全部记入 SUMMARY 带 commit hash——比"agent 自由发挥"或"事事问人"都更可运营。

## 明显欠缺

- **极重、token 消耗大**：用户报告编排:代码 token 比高达 4:1，官方推荐 Max 订阅；70 命令 + 34 agent 的学习曲线陡峭，小任务只能靠 /gsd:quick 兜底。
- **命令面膨胀/边界模糊**：mempalace、ns-* 系列、graphify、forensics、ai-integration-phase 等大量功能堆叠，社区接手后进一步膨胀，内聚性下降。
- **治理风险已成现实**：原维护者失联 + 代币 rug-pull，原仓库锁定归档，生态分裂为 open-gsd/gsd-core 与 jnuyens/gsd-plugin 等多个延续版本，选型需谨慎。
- **发布与复盘闭环弱**：ship 止于 PR，无 CI/部署/回滚集成；learnings 沉淀不自动反哺项目规则（如 CLAUDE.md）。
- **确定性不足**：编排主要靠长 prompt 而非脚本状态机，跨 host 时行为一致性无保证。

## 臃肿度与耦合度评价

- **臃肿度：重**。自称 "light-weight" 但实际是全家桶：强制 Node 安装器、70 命令、34 agent、SDK、hooks、多语言 README。全流程走完的 token/时间成本显著，适合中大型 greenfield 项目，不适合轻量修补。
- **耦合度：与 Claude Code 深绑定**。核心机制（subagent fresh context、Write 工具指令、slash command、`.claude-plugin/`）都是 Claude Code 语义；多 runtime 支持是安装器层适配，非架构层抽象。
- **接入成本：中高**。安装一条命令即可跑，但要用好需理解五步循环、`.planning/` 文档体系和 discuss/plan 的决策纪律；brownfield 必须先 map-codebase。

## 关键证据

- gsd-build/get-shit-done（GitHub API）：64,664 stars、MIT、archived: true，描述 "A light-weight and powerful meta-prompting, context engineering and spec-driven development system for Claude Code by TÂCHES"
- 原仓库 README：指向社区延续 https://github.com/open-gsd/gsd-core
- `open-gsd/gsd-core/README.md`："Heavy work runs in fresh subagents, structured artifacts survive session boundaries, and the verify step walks through what was built"
- `commands/gsd/`（101 文件 / ~70 命令）与 `agents/`（34 个 agent 定义），经 GitHub contents API 列出
- `agents/gsd-planner.md`："Plans should complete within ~50% context (not 80%)"；`<verify>` 必须 automated、<60s；"Prefer vertical slices over horizontal layers"；"No silent scope reduction… return ## PHASE SPLIT RECOMMENDED"
- `agents/gsd-executor.md`：Rule 1-4 偏差协议；"Only auto-fix issues DIRECTLY caused by the current task's changes"；禁 `git clean/stash/reset --hard`；`worktree-agent-*` 分支白名单；`checkpoint:human-verify gate="blocking-human"`（包合法性）
- `commands/gsd/new-project.md`：Questioning→Research→Requirements→Roadmap 四阶段，产出 PROJECT/REQUIREMENTS/ROADMAP/STATE/config
- `commands/gsd/verify-work.md`："Confirm what Claude built actually works from user's perspective"，失败自动诊断并生成修复计划回 execute-phase
- 背景报道：augmentcode.com（58.9K stars 报道）、hoangyell.com/get-shit-done-explained/（context rot、30-40% 主会话占用、4:1 token 比）
