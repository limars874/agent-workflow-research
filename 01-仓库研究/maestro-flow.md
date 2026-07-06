# maestro-flow

## 基本信息
- 地址：https://github.com/catlog22/maestro-flow
- 作者：catlog22（个人）
- Stars：约 437（截至 2026-07，仓库创建于 2026-03，成长很快）
- 目标 agent host：以 **Claude Code 为主 host**，通过 CLI broker（delegate）扩展到 Gemini、Codex 等其他 CLI agent；自带 MCP server（stdio）
- 技术栈：TypeScript/ESM + Commander.js CLI，better-sqlite3 + Drizzle + web-tree-sitter 知识图谱，React 19 + Hono 仪表盘
- 体量：约 333 个 TS 源文件 / 8 万行代码，64 个 slash commands、115 个 workflow 定义、45 个 skill 包、23 个 agent 定义、92 个模板；中英双语文档

## 定位与设计哲学
一句话定位：**意图驱动的多 agent 全生命周期编排引擎**——用一个可恢复的状态机（Ralph）把"头脑风暴→蓝图→分析→规划→执行→验证→评审→测试→里程碑"整条链自动串起来，并用自增强知识图谱让"工作流产生知识，知识改进未来工作流"。

它认为 agent 编码的核心问题是两个：
1. **单次任务碎片化**：agent 只做孤立任务，缺乏跨阶段的生命周期治理和位置感知（"我现在处于流程哪一步"）。
2. **知识不沉淀**：每次会话从零开始，项目规范/教训无法自动注入后续执行。

## 核心机制

### 1. Ralph 引擎（`/maestro-ralph`，核心入口）
一个 11 状态 FSM 决策引擎，**只做决策与会话管理，从不亲自执行**（invariant 16）：
- 状态流：`S_PARSE_ROUTE → S_RESOLVE_PHASE → S_INFER（推断生命周期位置）→ S_RESOLVE_SCOPE_VERDICT → S_QUALITY_MODE → S_PLANNING_MODE → S_DECOMPOSE → S_BUILD_CHAIN → S_CREATE_SESSION → S_CONFIRM → S_DISPATCH → S_DECISION_EVAL → S_APPLY_VERDICT`
- 生命周期链：`brainstorm → blueprint → init → analyze → roadmap → plan → execute → verify → review → test → milestone`
- 构链规则（A_BUILD_STEPS）：跳过已有产物的阶段；在质量门后插入 decision node；**每 3 个执行步插入一个 re-grounding 门**校验产出是否偏离原始意图；分解过的目标末尾追加 goal-audit。
- 裁决路由：`proceed` 继续 / `fix` 插入 debug→plan --gaps→re-execute 修复回路 / `escalate` 暂停等人 / `drifted`（置信度≥60）触发 A_REGROUND_HALT 安全熔断（绕过 auto_confirm）。
- 裁决解析失败兜底（invariant 13）：verdict 置为 fix、confidence=0，后续步骤继承 LOW CONFIDENCE 标记。

### 2. 会话状态文件
`.workflow/.maestro/ralph-{时间戳}/status.json`：intent、lifecycle_position、steps[]（含 completion_confirmed/evidence/caveats）、boundary_contract、quality_mode、goal_changelog（目标修订留 before/after 快照+风险评估）。
关键约束：`completion_confirmed=true` **只能由 CLI `maestro ralph complete <idx> --status DONE` 写入**（invariant 6），LLM 不能自证完成。决策日志追加写入 `decisions.ndjson`。

### 3. prompt 组织方式
三层：`.claude/commands/*.md`（64 个薄入口 slash command）→ `workflows/*.md`（115 个厚流程定义，实际的 prompt 主体）→ `.claude/agents/` + `.claude/skills/`（角色与技能包）。命令内容**延迟加载**：构链时只校验 skill 路径（`maestro ralph skills --json`），执行时才由 `maestro ralph next` CLI 载入内容（invariant 9），控制上下文占用。

### 4. 知识系统（MaestroGraph）
- tree-sitter AST 抽取 + SQLite/FTS5 双索引，统一代码结构与项目知识；`maestro kg search|context|callers|callees` 查调用链。
- **Spec 自动注入**：项目规则存为带关键词标签的 `<spec-entry>` 块，经 17 个 hooks 自动注入 agent prompt，agent 无需显式加载。
- 学习闭环：`learn-retro / learn-follow / learn-decompose / learn-investigate` 四工具把模式沉淀为未来知识。

### 5. 多 agent 协作模式
Delegate（CLI broker 异步派发到 Gemini/Codex 等）、Team（coordinator-worker）、Wave（任务拓扑排序并发波次）、Swarm（蚁群式探索）。另有 Odyssey 系列扩展循环（odyssey-debug/planex/improve/review-test-fix/ui）。

### 6. 可视化
`maestro serve` 起 React 仪表盘（Kanban/Gantt/命令派发，WebSocket+SSE），`maestro view` 终端 TUI。

## 步骤流覆盖
| 步骤 | 有无 | 做法 |
|---|---|---|
| 澄清意图 | ✅ 强 | brainstorm.md 五阶段结构化访谈：主题探针问题→角色选择→每角色 3-4 深度问题→冲突消解（每轮≤4 问）→特性分解（≤8 个候选，用户确认）；另有 grill/boundary-grill 压力测试意图 |
| 治理上下文 | ✅ 强 | spec 自动注入（17 hooks）、命令内容延迟加载、re-grounding 门防漂移、`--from analyze:ANL-xxx` 产物引用传递 |
| 写清规格 | ✅ | brainstorm 产出 guidance-specification.md + context-package.json（机器可读）；blueprint/roadmap 阶段；spec-generate/specs-* 命令族 |
| 小步切片 | ✅ | plan.md：反过度切分规则（"一个 feature = 一个 task，即使涉及 3-5 文件"），中型 4-8 个任务，每任务 JSON 必含 read_first / convergence.criteria（必须可 grep/CLI 验证）/ 具体 action；大里程碑 2+1 planner 并行+合成 |
| 实现功能 | ✅ | execute.md + wave 并发调度；tdd.md 可选 |
| 验证证据 | ✅ 极强 | verify.md：禁止"should work"式措辞，要求当条消息内 IDENTIFY→RUN→READ→VERIFY 完整证据链；goal-backward 三层校验（Observable Truths / Artifacts 存在-实质-被接线 / Key Links）+ 技术栈约束扫描 + 反模式扫描 + Nyquist 测试覆盖映射，产出 verification.json |
| 独立审查 | ✅ | review.md：按维度（正确性/安全/性能/架构/可维护/最佳实践）而非按文件的并行独立 agent；quick/standard/deep 三档；Phase 0 先做 spec 符合度证据核查；BLOCK/WARN/PASS 判定 |
| 可控发布 | ⚠️ 部分 | milestone-audit/complete/release 三命令做里程碑收口审计，但没有真正的部署/回滚机制，"发布"止于里程碑关闭 |
| 复盘沉淀 | ✅ 强 | retrospective.md 多视角（技术/流程/质量/决策）并行 post-mortem，指标含返工次数、反模式数、gap 数；洞见路由到 specs / issues.jsonl / learnings.md 三处并自动回流后续规划 |

## 横切能力覆盖
- **Task State 中断恢复**：✅ 很强。status.json 会话清单 + `maestro-ralph continue` 从 active_step_index 恢复，跳过 completion_confirmed 的步骤；决策节点若中断在 running 态会重新 delegate 评估。
- **Journal-Trace**：✅。decisions.ndjson 追加式决策日志、goal_changelog 目标修订审计、`.history/` 归档历史验证产物、每步 completion_evidence 指向证据文件。
- **Safety Guardrails**：✅ 中强。完成态只能由 CLI 写（防 LLM 自我宣称完成）、auto_confirm 只能来自用户 `-y`（invariant 14）、漂移熔断绕过自动确认、verdict 解析失败降级为 fix。但没有针对危险 shell 操作的沙箱/权限护栏（仅 shell-exec-protocol.md 约定层面）。
- **Tool Compatibility 跨 host**：⚠️ 部分。主 host 是 Claude Code（.claude/ 深度绑定、17 hooks）；跨 host 靠 delegate CLI 把子任务丢给 Gemini/Codex，并有 codex 专属变体（`odyssey-base-codex.md`、`issue-gaps-analyze.codex.md`、`.codex/` 目录、codex-instructions.md），是"以 Claude 为脑、其他 CLI 为手"的模式，而非 host 无关设计。
- **Runtime-Scripts 机器验证下沉**：✅。大量判定下沉到 maestro CLI（`maestro ralph next/complete/skills`、kg 查询、BM25 搜索），convergence criteria 强制用 grep/CLI 可机验命令而非主观描述。

## 独特亮点
1. **完成态与决策权的机器托管**：`completion_confirmed` 只能由 CLI 写入、命令内容延迟加载、决策日志 ndjson 化——系统性地把"LLM 说了不算"的原则落到机制层，这是多数 workflow 框架只停留在 prompt 叮嘱的地方。
2. **Re-grounding 漂移熔断**：每 3 个执行步自动插入"产出是否仍对齐原始意图"的检查门，drifted 且高置信时强制暂停（即使用户开了 -y），直接针对长链执行的目标漂移问题。
3. **知识自增强闭环**：retrospective → spec-entry → hooks 自动注入下次执行，形成真正跑得通的"越用越懂项目"回路，且有 KG（AST 级）+ wiki（BM25）双底座。

## 明显欠缺
- **发布环节薄弱**：无部署、灰度、回滚概念，milestone-release 只是流程收口。
- **无硬性安全沙箱**：危险命令防护靠协议文档约定，不是工程强制。
- **跨 host 不对称**：Gemini/Codex 只是被 delegate 的执行器，无法作为一等 host 运行完整 Ralph 循环（有 codex 变体但覆盖零散）。
- **仓库工程卫生一般**：根目录混入 coverage/、.history/、*.tgz 包、截图快照文件，暗示个人项目维护风格。
- **可靠性依赖 LLM 遵循超长 FSM prompt**：Ralph 的 11 状态+16 条 invariant 写在 markdown 里靠模型自律执行，状态机并未完全落在代码里，规模化/弱模型下有失控风险。

## 臃肿度与耦合度评价
- **重量级**：8 万行代码、64 命令、115 workflow、45 skill、外加 KG 数据库和 React 仪表盘。这是一个"平台"而非"技巧集"，学习成本高（官方也提供 76 篇双语指南来对冲）。
- **耦合度**：与 Claude Code 深绑（.claude/commands、hooks、skills 机制），且强依赖自家 `maestro` CLI + SQLite 状态——离开 npm 包和 CLI，slash command 基本不可独立使用。
- **接入成本**：`npm i -g maestro-flow && maestro install` 一键化，起步不难；但要吃到知识图谱/spec 注入/仪表盘的价值，需要项目长期驻留在它的 `.workflow/` 目录结构里，迁出成本不低。
- 总评：适合愿意 all-in 一套流程的重度长期项目；对想抽取单点技巧（如验证纪律、re-grounding 门）的团队，可只借鉴其机制设计而不引入全套。

## 关键证据
- 仓库元数据（GitHub API）：437 stars，默认分支 master，topics 含 workflow-orchestration/knowledge-graph/multi-agent，创建 2026-03-17。
- `README.md`：双支柱架构、"Workflows generate knowledge. Knowledge improves future workflows."、40+ chain types、17 hooks spec 注入、Delegate/Team/Wave/Swarm 四协作模式、技术栈与规模数字。
- `.claude/commands/maestro-ralph.md`：11 状态 FSM 全流程；`.workflow/.maestro/ralph-{ts}/status.json` 结构；invariant 6（completion_confirmed 只能 CLI 写）、9（命令内容延迟加载）、13（verdict 解析失败兜底）、14（auto_confirm 只来自 -y）、16（FSM 独占会话生命周期）；"每 3 个执行步插入 post-reground 决策节点"；A_REGROUND_HALT 熔断。
- `workflows/verify.md`：IDENTIFY→RUN→READ→VERIFY 证据流程；禁语列表（"Should work" 等）；三层 goal-backward（Truths/Artifacts L1-L3/Key Links）；Nyquist 覆盖映射；输出 verification.json / issues.jsonl / .history/ 归档。
- `workflows/plan.md`："one feature = one task (even if 3-5 files); never split a feature into per-file tasks"；任务必含 read_first / convergence.criteria / action；plan-checker 校验覆盖率≥40%、无环依赖；产物路径 `.workflow/scratch/{YYYYMMDD}-plan-.../.task/TASK-{NNN}.json`。
- `workflows/review.md`：按维度并行独立 agent；quick(≤3 文件)/standard/deep(≥20 文件) 三档；Phase 0 spec 符合度 MET/PARTIAL/UNMET 预查；BLOCK/WARN/PASS 判定规则。
- `workflows/brainstorm.md`：五阶段访谈（探针→角色→角色深问→冲突消解→特性分解）；产物 guidance-specification.md、context-package.json，按文件存在性门控推进。
- `workflows/retrospective.md`：洞见三路由（.workflow/specs / issues.jsonl / learnings.md），以 `<spec-entry>` 块沉淀并被 manage-learn 等下游检索。
- `workflows/` 目录清单：存在 `odyssey-base-codex.md`、`issue-gaps-analyze.codex.md`、`codex-instructions.md`、`agy-instructions.md`（跨 host 变体证据）；`shell-exec-protocol.md`（安全约定层面）。
