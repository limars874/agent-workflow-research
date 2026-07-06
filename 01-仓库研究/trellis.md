# trellis

## 基本信息
- **地址**: https://github.com/mindfold-ai/trellis
- **作者**: mindfold-ai 组织（多贡献者，workspace 中可见 bamboo-pan、jdjingdian、kleinhe、taosu 等开发者目录）
- **Stars**: ~11.8k（664 forks），2026-01 创建，增长极快，活跃维护
- **License**: AGPL-3.0
- **形态**: TypeScript CLI（npm 包 `@mindfoldhq/trellis`）+ Python 脚本运行时 + Markdown skills/agents
- **目标 agent host**: 多平台通用 — 宣称支持 16 个平台：Claude Code、Cursor、Codex、OpenCode、Gemini CLI、Kilo、Kiro、iFlow、Antigravity、Qoder、Devin 等。`trellis init --cursor --opencode --codex` 生成各平台适配文件（.claude/、.cursor/、AGENTS.md、.kilocode/、.kiro/ 等）

## 定位与设计哲学
**一句话定位**: 开箱即用的 AI 编码工程框架（自称 "The best agent harness"），把规格（spec）、任务（task）、记忆（memory）持久化进仓库，让任何 coding agent 按你的工程标准工作。

**它认为的核心问题**: AI 每个 session 从零开始 —— 不记得项目约定、团队标准、历史踩坑；CLAUDE.md/AGENTS.md 这类单文件会膨胀成不可维护的巨石。解法是**分层规格 + 任务工件 + hook 强制注入**（"Specifications injected via hook, not recalled from memory"），并把每次任务的学习回写到 spec，形成复利循环。

五条核心原则（workflow.md）：
1. Plan before code
2. 规格靠 hook 注入而非靠模型记忆
3. 所有研究、决策、学习持久化到文件
4. 一次一个任务、增量推进
5. 任务结束做 review，新知识回写 spec

## 核心机制

### 目录结构
```
.trellis/
  workflow.md          # 工作流总纲（阶段/规则/状态机）
  config.yaml / .version / .template-hashes.json
  spec/                # 分层规格：cli/ core/ docs-site/（按包分层）+ guides/（跨项目通用）+ tech/
  tasks/               # 每任务目录：prd.md, design.md, implement.md, implement.jsonl, check.jsonl, 状态
  workspace/           # 每开发者目录（journal/连续性记忆）+ index.md
  scripts/             # Python 运行时：task.py, get_context.py, add_session.py, init_developer.py, hooks/
.claude/
  settings.json        # 3 个 hooks（见下）
  skills/              # 13 个 skill：trellis-brainstorm/-check/-before-dev/-update-spec/-break-loop/-channel/-session-insight/-spec-bootstrap/-meta 等
  agents/              # 3 个 subagent：trellis-implement.md, trellis-check.md, trellis-research.md
  commands/trellis/    # 5 个命令：continue, finish-work, create-manifest, improve-ut, publish-skill
```

### Hook 强制注入（Claude Code 上的关键机制，settings.json）
- **SessionStart**（startup/clear/compact）→ `session-start.py`：会话初始化注入
- **PreToolUse**（Task/Agent 工具）→ `inject-subagent-context.py`：给 subagent 派发时自动注入 spec/manifest 上下文
- **UserPromptSubmit** → `inject-workflow-state.py`：每轮注入工作流状态面包屑

### 三阶段工作流（workflow.md）
1. **Plan**: `task.py create` → trellis-brainstorm 一次一问澄清 → 产出 prd.md（必需）、design.md + implement.md（复杂任务）、implement.jsonl/check.jsonl（上下文清单，供 subagent 派发注入）→ `task.py start` 激活
2. **Execute**: 支持 subagent 的平台派发 `trellis-implement`（写码，禁止 commit）→ `trellis-check`（验证）；inline 平台（Codex/Kilo/Devin）用 `trellis-before-dev` skill 先加载规范再直接编辑
3. **Finish**: 可选 debug 复盘 → `trellis-update-spec` 回写规格（"spec-sync preamble"：commit 前必须先审视有无值得沉淀的模式/坑）→ 批量 commit（未识别的脏文件须用户显式确认）→ `task.py archive`

### 任务系统（task.py，机器状态而非纯 markdown）
```
task.py create/start/finish/archive/list/current
task.py add-context <name> <action> <file> <reason>   # 策划注入清单
get_context.py --mode packages / --mode phase --step <X.Y>
```

### 状态机与面包屑
每轮 UserPromptSubmit 注入 `[workflow-state:no_task|planning|in_progress|completed]` 状态块，告诉模型当前该干什么。关键不变量：任务创建需先征得用户同意（"task-creation consent first"）；创建 ≠ 批准实现；planning gates implementation；阶段可回滚（发现缺陷 → 回 planning）。

## 步骤流覆盖

| 步骤 | 覆盖 | 怎么做 |
|---|---|---|
| 澄清意图 | ✅ 强 | trellis-brainstorm：一次只问一个高价值问题，附推荐答案与 trade-off；**Evidence Rule**：能在代码库里查到的绝不问用户；First Principles 分解模糊需求 |
| 治理上下文 | ✅ 极强 | 分层 spec（按包 + guides）、implement.jsonl/check.jsonl 人工策划注入清单、三个 hook 强制注入、`add-context` 命令显式管理 |
| 写清规格 | ✅ 强 | prd.md 必需（可测试验收标准是质量门槛）；复杂任务加 design.md + implement.md；trellis-update-spec 要求"可执行契约"：签名/契约/错误矩阵/Good-Base-Bad 用例/测试断言点，七段模板 |
| 小步切片 | ✅ 中强 | implement.md 有序 checklist；parent/child 任务结构（父任务持有需求与集成 review，子任务独立可验证）；"one task at a time" |
| 实现功能 | ✅ | trellis-implement subagent：读注入 spec → 按既有模式实现 → 禁止 commit/push/递归派发；崇尚最小可读实现、反过度抽象 |
| 验证证据 | ✅ | trellis-check：git diff 定位改动 → 对照 prd/design/spec → 跑 lint/typecheck/test 并当场修 → 多层改动检查数据流/复用/循环依赖/一致性 → 复跑 |
| 独立审查 | ⚠️ 部分 | trellis-check 是独立 subagent（干净上下文），但仍是同框架内的自查，无强制人工/外部 review 环节；父任务有 integration review |
| 可控发布 | ⚠️ 部分 | 实现阶段禁 commit，Finish 阶段批量 commit + 脏文件显式确认（No silent file inclusion）；无 PR/CI/发布流程编排 |
| 复盘沉淀 | ✅ 极强 | Finish 阶段 spec-sync 是提交前置条件；trellis-update-spec 有触发矩阵与学习分类（design decisions/forbidden patterns/gotchas 等）；trellis-session-insight、workspace journal 补充 |

## 横切能力覆盖

- **Task State 中断恢复**: ✅ 强。任务状态存文件（planning/in_progress/completed），`task.py current --source` + `/trellis:continue` 命令 + 每轮注入 workflow-state 面包屑；`[once]` 步骤幂等跳过；SessionStart hook 覆盖 compact/clear 恢复。
- **Journal-Trace**: ✅ 有。`.trellis/workspace/<developer>/` 每开发者 journal，`add_session.py` 记录会话；finish-work 归档任务并更新 journal。但更偏"开发者连续性记忆"，非逐操作 trace。
- **Safety Guardrails**: ✅ 中强。subagent 禁 commit/push/merge、禁递归派发；task-creation consent；commit 前脏文件白名单确认。无沙箱/权限层面控制（依赖 host）。
- **Tool Compatibility 跨 host**: ✅ 是最大卖点。CLI 从 .trellis/ 单一真源生成 16 个平台的适配文件；对无 subagent/hook 的平台降级为 inline 模式 + skill 手动加载上下文（trellis-before-dev）。代价：Claude Code 上体验最完整（hook 注入），其他平台是降级版。
- **Runtime-Scripts 机器验证下沉**: ✅ 强。task.py/get_context.py 等 Python 脚本把状态管理、上下文发现做成确定性机器操作，而非让 LLM 自由发挥；模板哈希（.template-hashes.json）管理升级。

## 独特亮点
1. **Hook 强制注入而非祈祷模型记住**：SessionStart / UserPromptSubmit / PreToolUse 三层注入，每轮塞状态面包屑、派发 subagent 时自动塞策划好的 spec 清单（implement.jsonl）——把"上下文治理"从约定变成机制。
2. **可执行契约级的 spec 回写闭环**：trellis-update-spec 强制七段模板（签名/契约/错误矩阵/用例/测试断言/Wrong-vs-Correct），且是 commit 的前置步骤，知识沉淀不是可选项。
3. **一套真源多平台编译**：.trellis/ → 16 个 host 的配置产物，并对能力差异做了分级策略（subagent 派发 vs inline），这是同类框架中少见的工程化程度。

## 明显欠缺
- **独立审查弱**：trellis-check 本质是自动化自查，无外部/人工 code review、无多模型交叉审查机制。
- **发布链路止于 commit**：无 branch/PR/CI/回滚编排；README 提 worktree 并行但发布治理浅。
- **依赖 Python 运行时**：脚本层全是 Python，对纯 JS 项目或受限环境有额外依赖；hook 在非 Claude Code 平台不可用，跨平台"一致性"实际打折。
- **重量与仪式感高**：三阶段 + consent + 工件齐备门槛，小改动开销大（虽有 lightweight task 只需 prd.md 的豁免）。
- **AGPL-3.0** 对商业闭源集成不友好。

## 臃肿度与耦合度评价
- **重量级框架**：目录多（spec/tasks/workspace/scripts + 各平台产物）、13 skills + 3 agents + 5 commands + 3 hooks + Python 运行时。学习成本中高（workflow.md 是一份完整状态机文档），但 CLI init 一键生成降低了接入门槛。
- **host 耦合**：设计上刻意解耦（多平台生成），但核心体验（hook 注入、subagent 派发）深度依赖 Claude Code 能力；其他平台是降级模式。可以说"接口跨平台、灵魂在 Claude Code"。
- **适合**：多人团队、长期演进的中大型仓库、需要跨工具统一标准的组织。**不适合**：一次性脚本、快速原型、厌恶流程仪式的个人开发者。

## 关键证据
- 仓库: https://github.com/mindfold-ai/trellis （11,778 stars / 664 forks / AGPL-3.0 / 2026-01-26 创建）
- `README.md`: "An out-of-the-box engineering framework for AI coding"；.trellis/{spec,tasks,workspace}；四阶段 Plan/Implement/Verify/Finish；`npm install -g @mindfoldhq/trellis@latest && trellis init -u <name>`
- `.trellis/workflow.md`: 五原则（"Plan before code"、"Specifications injected via hook, not recalled from memory"）；三阶段；task.py 命令集；关键不变量（task-creation consent、No silent file inclusion）；`[workflow-state:*]` 面包屑
- `.claude/settings.json`: hooks — SessionStart→session-start.py、PreToolUse(Task/Agent)→inject-subagent-context.py、UserPromptSubmit→inject-workflow-state.py
- `.claude/skills/trellis-brainstorm/SKILL.md`: "If a question can be answered by exploring the codebase, explore the codebase instead. This is mandatory."；一次一问 + 推荐答案 + trade-off
- `.claude/skills/trellis-check/SKILL.md`: 六步验证流程；多层改动的数据流/复用/依赖/一致性检查
- `.claude/skills/trellis-update-spec/SKILL.md`: "Executable contracts (not principle-only text)"；七段必填；Code-Spec vs Guide 区分
- `.claude/agents/trellis-implement.md`: `<!-- trellis-hook-injected -->` 标记；禁止 git commit/push/merge、禁止递归派发 subagent
- `.trellis/scripts/`: task.py, get_context.py, add_session.py, init_developer.py, common/, hooks/
- `.claude/commands/trellis/`: continue.md, finish-work.md, create-manifest.md, improve-ut.md, publish-skill.md
- 官网/文档: https://trytrellis.app/ 、https://docs.trytrellis.app/
