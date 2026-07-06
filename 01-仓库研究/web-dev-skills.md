# web-dev-skills（T-Tools）

## 基本信息
- **地址**: https://github.com/timzaak/web-dev-skills
- **作者**: timzaak（个人项目）
- **Stars**: 约 44（小众早期项目）
- **描述**: "A Claude Code plugin for Rust + React projects. It turns PRD -> Design -> Task -> Development -> Acceptance -> Demo into a reusable workflow"
- **目标 agent host**: 首选 Claude Code（`.claude-plugin/plugin.json` 打包为插件）；官方文档 `human/use-in-other-agents.md` 提供 Codex / ZCode 的"dispatcher skill"适配方式，属"Claude Code 优先、可移植"
- **技术栈定位**: Rust 后端 + React 前端 + 微信小程序 + Playwright E2E（Demo 线），中英双语文档（README.md 中文为主）

## 定位与设计哲学
**一句话定位**: 一个把"决策→调研→PRD→设计→任务→开发→验收→Demo→发布"全生命周期固化为串行、带质量门禁的 Claude Code 插件工作流，面向 Rust+React 全栈项目。

**它认为 agent 编码的核心问题**: AI 自由发挥导致上下文漂移、规则重复定义、状态不可恢复、验收无据可查。其解法被 `human/structure.md` 明确概括为——**"用更多结构换更少自由发挥"**：不追求 AI 一次做完所有事，而是沿"文档→状态→契约→门禁"的轨道推进，让 AI 编程变成可追踪、可恢复、可验收的长期工作流。

## 核心机制

### 四层架构（human/structure.md）
| 层 | 目录 | 职责 |
|---|---|---|
| **Skills** | `skills/t-*/SKILL.md`（约 23 个） | 命令式工作流入口，职责限定为"校验输入、读取上游、调度 agent、写入产物、更新状态"——轻量工作流引擎而非自由生成 |
| **Agents** | `agents/*.md`（16 个） | 按工程角色拆分：backend/frontend/miniapp 各配 dev/test/accept 三角色，另有 demo-dev/demo-accept/demo-diagnose、context-curator、structure-review、html-show 等。强制边界：dev 可改代码、test 只验证、accept 默认只读 |
| **Protocols** | `protocols/*.md`（17 个） | 跨 skill/agent 的单一真相源：状态结构（task-state-contract）、执行顺序（task-phase-execution）、输出契约（agent-task-output-contract）、检查 rubric（prd/design/task-check-rubric）、边界（runtime-boundaries）、派发规则（subagent-dispatch） |
| **Guides** | `guides/{backend,frontend,miniapp,demo,product,core}/` | 领域工程规范（TDD 流程、testid 标准、selector 策略、PRD/用户故事写法等）；agent 文档只讲执行方式，不重复规范，防规则漂移 |

### 命令流（skills）
`t-init`（项目初始化，含脚手架模板）→ `t-decision` → `t-tech-research` → `t-prd` → `t-prd-check` → `t-html-show`（PRD 的 HTML 可视化预览给人看）→ `t-design` → `t-design-check` → `t-task` → `t-task-check` → `t-run`（开发执行）→ `t-demo-run` / `t-demo-run-all` → `t-demo-accept` → `t-prd-publish`（草稿转正式文档）。辅助：`t-dream`（一致性审计）、`t-push`（本地 CI + commit）、`t-release`、`t-doc`。README 强调 **"do not skip check or accept stages"**，且所有 t-* 命令必须人工手动触发，模型绝不自动调用。

### 三层执行模型（Phase → Slot → Item）
- **Phase**: backend → frontend → demo，严格串行（frontend 要求 backend 完成，demo 要求最终交付阶段完成）
- **Slot**: dev → test → accept，slot 定义按"职责闭包"（业务能力/接口契约/用户主流程），非按文件类型切
- **Item**: 最小可执行任务，要求可独立验证、失败可定位、依赖构成无环 DAG
- **调度**: `t-run` 每轮只选一个 `pending|failed` item 派发给子 agent，"任意时刻最多一个 item 处于 running"——明确用可控性换并发速度

### 产物空间分离
`.ai/`（临时工作区：prd 草稿/design/task/preview/quality）与 `docs/`（正式权威文档），通过 `t-prd-publish` 将草稿"回流"为正式文档；`templates/preview-template.html` 支撑 PRD 可视化。

### 配套代码资产
- `scripts/`（26 个 Python 脚本 + lib）：backend-test / demo 启停 / debug-test / 日志清理 / 链接检查 / release 等，接口契约固定、内部实现可按项目调
- `packages/playwright-unified-logger`：TypeScript 包，统一收集 Playwright 测试的 console/network/route 日志，供 demo-diagnose 使用

## 步骤流覆盖

| 步骤 | 覆盖 | 说明 |
|---|---|---|
| 澄清意图 | ✅ 强 | `t-decision`（先评估该不该做）+ `t-prd`（用户故事模板）+ `t-html-show`（HTML 预览让人先确认理解一致）；t-task 中"用户问题未答则阻塞生成" |
| 治理上下文 | ✅ 特色 | `t-dream` 五维审计（上下文健康/结构/可追溯/描述vs现实/深度后端一致性），`context-curator` agent；`.ai/` 与 `docs/` 分离防止事实源污染 |
| 写清规格 | ✅ 强 | PRD → Design 两级文档 + template + 各自 check rubric（prd-check-rubric.md / design-check-rubric.md）质量门禁 |
| 小步切片 | ✅ | `t-task` 的 phase/slot/item 拆分，item 要求独立可验证 + DAG 依赖 + 硬校验（循环依赖/缺字段直接拒写） |
| 实现功能 | ✅ | `t-run` 串行派发 dev agent，注入最小上下文（feature/phase/slot/item_id/文件路径/已完成依赖摘要） |
| 验证证据 | ✅ 强 | test slot 走专用 runner 脚本（backend-test-execution 协议、tests-to-run-contract），Demo 线用 Playwright 验证完整用户路径且不重复单测；unified-logger 收集运行时证据 |
| 独立审查 | ✅ | 每 phase 有独立 accept agent（默认只读），`t-demo-accept` 最终验收；structure-review agent |
| 可控发布 | ✅ | `t-push` 本地 CI（按变更范围触发检查+规范 commit message）、`t-release`、`t-prd-publish` 文档回流 |
| 复盘沉淀 | ⚠️ 部分 | `t-dream` 承担事后一致性治理与 PRD 整合归档（P0-P3 分级+置信度报告），但没有显式的"经验教训→规则更新"的自动沉淀回路 |

## 横切能力覆盖

| 能力 | 覆盖 | 说明 |
|---|---|---|
| Task State 中断恢复 | ✅ 强 | `protocols/task-state-contract.md`：`.ai/task/[feature]/.state.json`，状态枚举 `pending/running/failed/completed/skipped/generated`；刻意**不用任何时间戳**，纯靠 status + 文件存在性 + depends_on 无状态重建执行上下文，天然支持中断续跑 |
| Journal / Trace | ⚠️ 中 | 无独立 journal 文件，但每个 item 成功写 `handoff_summary`、失败写 `last_error`；t-dream 报告落 `.ai/quality/`；Playwright unified-logger 提供运行时 trace。缺主线程级决策日志 |
| Safety Guardrails | ✅ | `protocols/runtime-boundaries.md`：插件路径 vs 项目路径所有权分区；冲突禁止静默覆盖必须显式报告；脚本失败禁止未诊断即绕过；解析优先级链（项目代码→项目约束→项目文档→工作区→插件协议→guides→skills）；accept agent 只读 |
| Tool Compatibility 跨 host | ⚠️ 中 | 有意识设计：`subagent-dispatch.md` 要求显式注入 agent 角色全文（因 Codex/ZCode 不会自动加载 `agents/*.md`）；`use-in-other-agents.md` 提供 dispatcher skill 移植方案。但深度依赖 Claude Code 的 Agent 工具与 `${CLAUDE_PLUGIN_ROOT}`，移植是"能用"而非一等公民 |
| Runtime-Scripts 机器验证下沉 | ✅ 强 | 26 个 Python 脚本把测试执行、demo 环境启停、失败摘要、日志清理、链接检查等下沉为确定性脚本；协议规定"文件名/参数/输出契约固定，内部实现项目可调"，本地脚本优先于插件 fallback |

## 独特亮点
1. **无时间戳的状态契约**：`.state.json` 完全排除时间元数据，用 status 枚举 + 文件存在性 + DAG 聚合规则实现无状态恢复——中断恢复设计干净且不易腐化，是同类框架中少见的明确取舍。
2. **Protocols 作为单一真相源的四层解耦**：Skills 只做调度、Agents 只讲角色、Protocols 定契约、Guides 定规范，显式对抗"规则在多个 prompt 里重复然后漂移"这一 skill 框架通病；`subagent-dispatch.md` 对"子 agent 读不到角色文件"的跨 runtime 坑有清醒认知并给出注入方案。
3. **Demo 独立验证线 + 人类可视化门禁**：Playwright E2E 作为独立于单测的用户路径验证层（配 selector 策略/修复、POM 指南、diagnose agent、unified-logger），加上 `t-html-show` 把 PRD 渲染成 HTML 让人类在写代码前确认理解——"给人看"和"给机器验"两个方向都有实体投入。

## 明显欠缺
- **强绑定技术栈**：guides/scripts/templates 深度假设 Rust 后端 + React 前端 + 微信小程序 + Docker + Playwright，换栈需大量改写，通用性弱。
- **纯串行、无并行**：明确禁止并行 item 执行，大型任务吞吐低；这是有意取舍但缺"可选并行"逃生门。
- **复盘沉淀弱**：无失败模式→规则/guide 自动回写机制，t-dream 偏审计而非学习。
- **流程重、仪式感强**：8+ 阶段全部人工触发、每步有 check，小需求走全流程成本高，缺"轻量快速路径"。
- **无 CI/远程集成**：`t-push` 是"本地 CI"，无 GitHub PR/review/issue 集成。
- **社区规模小**（44 stars），文档以中文为主，外部验证少。

## 臃肿度与耦合度评价
- **体量**: 偏重。23 个 skill、16 个 agent、17 个 protocol、约 40 篇 guide、26 个脚本 + 一个 npm 包，是"全生命周期方法论 + 配套工具链"，不是轻量 prompt 集。
- **host 耦合**: 中等偏深。以 Claude Code 插件形态分发，依赖 Agent 工具、`${CLAUDE_PLUGIN_ROOT}`、slash command；跨 host 靠 dispatcher hack + 手动角色注入，还要求 Context7 MCP。
- **栈耦合**: 深（Rust+React+小程序+Playwright+Docker），这是它最大的接入门槛。
- **学习/接入成本**: 高。需要理解 phase/slot/item 模型、`.ai/` vs `docs/` 语义、17 个协议；`t-init` 提供脚手架缓解，但只对匹配技术栈的新项目友好。适合愿意全盘接受其方法论的 Rust+React 团队，不适合想"挑几个 skill 用"的场景（skills 之间通过 protocols 和 state 强耦合）。

## 关键证据
- 仓库描述与 stars: GitHub API `repos/timzaak/web-dev-skills`（44 stars，topics: ai-coding, skills）
- 设计哲学原文: `human/structure.md` — "用更多结构换更少自由发挥"；"任意时刻最多一个 item 处于 running"
- 状态契约: `protocols/task-state-contract.md` — 状态枚举 pending/running/failed/completed/skipped/generated；明确不使用 generated_at/started_at 等时间字段
- 跨 runtime 注入: `protocols/subagent-dispatch.md` — "子 agent 读不到角色职责、Read Order、验证步骤和 Completion Gate"，故要求把 `agents/*.md` 全文注入子 agent prompt 首段
- 安全边界: `protocols/runtime-boundaries.md` — "若上层事实与下层默认规则冲突，不要静默覆盖；应显式报告冲突"；解析优先级：项目代码/配置 → 项目约束 → 项目文档 → 工作区 → 插件协议 → guides → skills
- 执行调度: `skills/t-run/SKILL.md` — 只执行 pending/failed item、严格串行、成功写 handoff_summary、失败写 last_error、连续 3 次失败升级
- 任务拆分: `skills/t-task/SKILL.md` — slot 按职责闭包定义、item 需独立可验证、DAG 无环硬校验、用户问题未答阻塞生成
- 审计: `skills/t-dream/SKILL.md` — 五维并行审计，P0-P3 + 0-100 置信度报告写入 `.ai/quality/dream-check-[timestamp].md`
- 门禁原则: `README.en.md` — "do not skip check or accept stages"；所有 t-* 命令人工触发
- 跨 host 移植: `human/use-in-other-agents.md` — Codex/ZCode 下建 `~/.agents/skills/t-tool/SKILL.md` dispatcher，路由到 clone 的 skill 文件；需 Context7 MCP
- 验证下沉: `scripts/`（backend-test.py、demo-test-runner.py、demo-failure-summary.py 等 26 个）+ `packages/playwright-unified-logger/`（console/network/route/test-code loggers）
