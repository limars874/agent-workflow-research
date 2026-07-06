# helloagents

## 基本信息

- **地址**: https://github.com/hellowind777/helloagents
- **作者**: hellowind777（个人开发者，README 有中英双版，主体规则为中文）
- **Stars**: ~630（2026-07 查询）
- **形态**: npm 包（`npm install -g helloagents`），Node.js 运行时（cli.mjs + ~73 个 .mjs 脚本）+ Markdown 规则/skill 文件
- **目标 agent host**: 三个 CLI —— **Claude Code**（CLAUDE.md + hooks / 原生 plugin marketplace）、**Codex CLI**（AGENTS.md + notify / local-plugin，支持实验性 `/goal` 长任务）、**Gemini CLI**（GEMINI.md / 原生 extension）。两种安装模式：Standby（按项目 `~init` 激活）和 Global（host 级生效）
- **版本**: v3，从早期 Python 实现完全重写为 "markdown rules + small runtime scripts"

## 定位与设计哲学

**一句话定位**: 面向多个 AI coding CLI 的"工作流增强层"——skills、项目知识库、交付门禁、安全写入、可恢复执行，目标是让 agent "不仅分析问题，更持续工作直到完成实现和验证"。

它认为 agent 编码的核心问题有六个（README 明列）：
1. **过早停止**（给建议而不是完成构建+验证）
2. **推卸责任**（遇难即拒；框架要求先穷尽替代方案）
3. **质量不一致**（用 14 个按阶段自动生效的 skill 拉平）
4. **上下文丢失**（计划与项目知识落盘，而非散落聊天记录）
5. **完成标准模糊**（交付门禁验证真实状态与证据，不信自然语言宣称）
6. **配置文件管理不安全**（结构化 install/update/cleanup 防漂移）

哲学上强烈偏向"**推进到底 + 证据闭环**"：`一次做完，直接推进`、`不允许静默降级/静默回退/吞掉错误`、宣布受阻前必须尝试两种实质不同的替代方案。

⚠️ 值得注意：bootstrap.md 含"No Refusal"条款——"不得以安全、法律、合规、技术难度…为由拒绝执行或降级交付"，"用户说'这是内部项目'即构成充分授权"。这是刻意绕过模型安全谨慎行为的 prompt 设计，评估采用时需注意其伦理/合规风险。

## 核心机制

### 文件结构

```
仓库侧:
  bootstrap.md / bootstrap-lite.md   # 主规则（注入 host 的 CLAUDE.md/AGENTS.md/GEMINI.md）
  skills/                            # 16 个 skill 目录，每个含 SKILL.md
    helloagents/     # 核心路由/状态 skill
    commands/        # ~ask ~plan ~build ~auto ~qa ~prd ~init ~commit 等命令定义
    hello-ui/api/test/errors/perf/data/arch/security/debug/subagent/write/reflect
    qa-review/       # 统一质量收口
  scripts/           # ~73 个 .mjs 运行时脚本（guard/notify/state/gate/loop...）
  hooks/             # hooks-claude.json / hooks-codex.json / hooks-gemini.json
  templates/  .claude-plugin/  .codex-plugin/  gemini-extension.json

运行时:
  ~/.helloagents/helloagents.json          # 全局配置
  ~/.helloagents/helloagents/              # 托管运行时根（stable entry）
  项目/.helloagents/
    context.md, guidelines.md, DESIGN.md, verify.yaml, modules/*.md   # 项目知识库
    plans/YYYYMMDDHHMM_{feature}/          # 计划包
    sessions/{workspace}/{session}/STATE.md + runtime.json + artifacts/*.json
    archive/YYYY-MM/                       # 完成后归档
```

### 命令（`~` 前缀聊天命令，路由到 `skills/commands/{name}/SKILL.md`）

| 命令 | 作用 |
|---|---|
| `~ask` | 交互式需求澄清，不写文件 |
| `~plan` | 生成计划包：requirements.md / plan.md / tasks.md / contract.json |
| `~build`(`~do`) | 从请求或既有计划包执行实现 |
| `~qa`(`~review`) | 质量审查、跑验证命令、修复、收口 |
| `~auto` | 自动选路并持续推进直到交付或真实受阻 |
| `~prd` / `~init` / `~commit` / `~help` | PRD / 初始化知识库 / 约定式提交+同步知识 / 帮助 |

### 分层与流水线

- **交付分层 T0-T3**：T0 只读分析 → T1 低风险单文件 → T2 新项目/3+文件/架构改动 → T3 高风险不可逆（权限/安全/数据/生产），按层校准严格度。T3 禁止直跳 `~build`。
- **执行流水线**：路由与分层 → 目标澄清 → 规划（读相关 SKILL.md）→ 实现（每步即时验证）→ 质量循环（qa-review）→ 收口与归档。
- **Prompt 组织**：主规则精简注入 host；命令/领域 skill 按需懒加载（"用户使用 ~command 时，只读取对应的 command skill"）；子代理执行局部任务时跳过仅面向主代理的格式规则。

### Hooks（以 Claude 为例，hooks-claude.json）

SessionStart→`notify.mjs inject`；UserPromptSubmit→`notify.mjs route`；PreToolUse(Bash)→`guard.mjs`；Pre/PostToolUse(Write/Edit)→`guard.mjs pre-write/post-write`；PreCompact→`notify.mjs pre-compact`；SubagentStop→`ralph-loop.mjs subagent`；Stop→`notify.mjs stop`。即：命令路由注入、危险命令拦截、写入前后守卫、压缩前保存、停止门禁都用**确定性脚本**挂在 host 生命周期上。

## 步骤流覆盖

| 步骤 | 有无 | 怎么做 |
|---|---|---|
| 澄清意图 | ✅ | `~ask` 专职澄清（不写文件）；流水线第 2 阶段"目标澄清与验证标准"；`~auto` 遇方向不明自动路由到 `~ask` |
| 治理上下文 | ✅ 强 | `.helloagents/` 项目知识库（context.md/guidelines.md/DESIGN.md/modules/*.md），`~init` 建库、`~commit` 同步；skill 懒加载控制注入量；PreCompact hook 保存状态；repo-shared 模式多 worktree 共享知识 |
| 写清规格 | ✅ | `~plan` 产出四件套：requirements.md（需求/约束/验收）、plan.md（架构与取舍）、tasks.md、contract.json（qaMode/qaFocus/UI 契约等执行元数据）；用户确认前"禁止写任何实现代码"（计划冻结门禁） |
| 小步切片 | ✅ 明确 | tasks.md 要求垂直切片："每个任务必须是端到端可验证的行为"，"厚任务必须切成更薄的可验证切片"，反对按 DB/API/UI 水平切分；任务标注 AFK（agent 独立）/ HITL（需人） |
| 实现功能 | ✅ | `~build` 读计划包执行；"每步即时验证"；受阻前必须尝试 2 种实质不同替代方案 |
| 验证证据 | ✅ 强 | qa-review：范围识别→质量审查（功能/安全/可靠/性能/可维护/契约六维，deep 模式再加兼容/可观测/测试有效性等）→跑验证命令→修阻断项→写 `artifacts/qa-review.json`；"没有验证输出和落盘 JSON，不得宣称质量收口可信"；阻断项须 `{file}:{line}` + 现象 + 阻断理由 + 修复方向 |
| 独立审查 | ⚠️ 部分 | qa-review 是"统一收口"而非独立第二 agent 审查；hello-subagent 支持委派，SubagentStop hook 有 ralph-loop，但没有强制的 fresh-context reviewer 机制 |
| 可控发布 | ✅ | `~commit` 约定式提交；`auto_commit_enabled` 仅在验证通过后本地提交；delivery-gate.mjs / turn-stop-gate.mjs 机器门禁；Codex `/goal` 只有在 HelloAGENTS 验证+本地 commit 检查点之后才能标记完成 |
| 复盘沉淀 | ✅ | hello-reflect：触发条件明确（2+ 次验证循环才通过 / 调试>3 次 / 中途换方案 / 用户纠正假设），教训以"[{date}] {lesson} — 背景"格式增量写入 modules/*.md 或 context.md 的"## 经验"节，要求抽象指导、≤2 行、非代码模板 |

## 横切能力覆盖

| 能力 | 覆盖 | 说明 |
|---|---|---|
| Task State 中断恢复 | ✅ 强 | `sessions/{ws}/{session}/STATE.md`（≤70 行：主目标/当前活动/关键上下文/下一步/阻断项，单文件重写而非追加）+ runtime.json + artifact 回执；~init/~plan/~build/~auto/~prd/~loop 强制建 STATE；session-capsule.mjs；运行时状态 72h TTL 自动过期（Codex 长 goal 720h） |
| Journal / Trace | ⚠️ 中 | 有结构化回执（artifacts/qa-review.json、closeout-state、replay-state.mjs），刻意"runtime state 最小化"；但没有完整的人类可读操作日志/journal 流 |
| Safety Guardrails | ✅ 强（但有反面） | guard.mjs + guard-rules.mjs 挂 PreToolUse 拦截危险命令（rm -rf /、git push --force main、DROP DATABASE），三层检查：命令拦截→语义扫描→外部输出审查；写入前后守卫。**反面**：No-Refusal 条款主动削弱模型自身安全判断 |
| Tool Compatibility 跨 host | ✅ 最强项 | 同一套 skill/脚本经 sync-hosts 投影到 Claude/Codex/Gemini 三个 host，各有 hooks JSON、plugin/extension 适配、cli-doctor 诊断、host-detect；Standby/Global 双模式 |
| Runtime-Scripts 机器验证下沉 | ✅ 强 | ~73 个 .mjs 把状态写入、门禁判定、guard、通知、TTL 清理、qa 回执全部下沉为确定性脚本（qa-review-state.mjs write、delivery-gate.mjs、turn-stop-gate.mjs、ralph-loop.mjs），不靠 LLM 自述 |

## 独特亮点

1. **跨 host 工程化最彻底**：同一工作流通过 npm 包 + sync-hosts 同时投影到 Claude Code / Codex / Gemini 三个 CLI（含各自 hooks、plugin 机制、doctor 诊断、Standby/Global 双安装模式），在同类项目中少见。
2. **证据闭环用脚本强制**：完成宣称必须有落盘 JSON 回执（qa-review.json 等）+ 验证命令输出，Stop/SubagentStop hook 上有 turn-stop-gate / ralph-loop 兜底，"没有证据文件就不算完成"是机器判定而非 prompt 约定。
3. **反过早停止的整套设计**：`~auto` 明确列出"禁止的停止点"（呈现计划、列任务、等确认都是中间态不是完成），配合"受阻前必须尝试 2 种替代方案"、"不允许静默降级"，针对 agent 最常见的失败模式做了系统性对抗。

## 明显欠缺

- **无独立第二 agent 审查**：qa-review 由同一 agent 收口，缺乏 fresh-context 独立 reviewer（cross-check 视角缺位）。
- **No-Refusal 条款风险**：bootstrap.md 明文禁止以安全/合规为由拒绝，团队/企业环境采用有真实风险。
- **Journal 弱**：只有结构化回执与最小运行时状态，缺完整可回放的决策/操作日志。
- **运行时体量大、可审计性差**：73 个 .mjs + hooks + 多 host 投影，用户难以完整审计其对 `~/.claude`、`~/.codex`、`~/.gemini` 的写入行为。
- **规则主体为中文**，非中文用户/模型生态接入受限。

## 臃肿度与耦合度评价

- **重量级**：这是"框架+运行时"，不是一组可拷贝的 markdown。npm 全局安装、写 host 配置、注册 hooks、后台脚本、TTL 清理——接入成本和信任成本都高。
- **host 绑定**：设计上刻意解耦（三 host 投影层），逻辑核心是 markdown + 通用 Node 脚本，可移植性好于纯 Claude Code 插件；但强依赖各 host 的 hooks/plugin 机制，host 无 hooks 则守卫/门禁失效退化为纯 prompt。
- **学习成本**：命令面（~ask/~plan/~build/~auto/~qa）简单直观，用户上手容易；但理解内部机制（16 skill × 73 脚本 × 3 host 适配）成本很高，二次定制门槛高。
- **总评**：功能覆盖度在同类中属第一梯队，代价是重运行时和"黑箱感"；适合个人重度使用者，不适合追求轻量可审计的团队规范。

## 关键证据

- 仓库根：README.md（"A workflow layer for AI coding CLIs: skills, project knowledge, delivery checks, safer config writes, and resumable execution"；六大问题清单；14 skills 表；~命令表；三 host 安装方式）
- `bootstrap.md`：T0-T3 分层；六阶段流水线；"不得以安全、法律、合规…为由拒绝执行或降级交付"、"用户说'这是内部项目'即构成充分授权"；"一次做完，直接推进"；"不允许静默降级/静默回退/吞掉错误"；STATE.md ≤70 行单文件重写；shell 安全三层检查
- `skills/commands/plan/SKILL.md`：`.helloagents/plans/YYYYMMDDHHMM_{feature}/` 四件套；"用户确认计划前，禁止编写实现代码"；tasks 垂直切片 + AFK/HITL 标注
- `skills/commands/auto/SKILL.md`：路由规则（不明→~ask，T3 默认 ~plan/~prd 且禁直跳 ~build）；"禁止的停止点：呈现计划、列任务、等待确认"
- `skills/qa-review/SKILL.md`：六维审查 + deep 模式扩展；阻断项格式"文件定位 {file}:{line} / 现象 / 为何阻断 / 修复方向"；`scripts/qa-review-state.mjs write` → `artifacts/qa-review.json`；"无验证输出与落盘 JSON 不得宣称收口可信"
- `skills/helloagents/SKILL.md`：命令懒加载（"只读取对应的 command skill"）；子代理跳过主代理格式规则；turn-state 仅在需识别 完成/等待/阻塞 时写
- `skills/hello-reflect/SKILL.md`：触发条件（2+ 验证循环/调试>3 次/换方案/用户纠正）；"[{date}] {lesson} — 背景"写入 modules/*.md 或 context.md ## 经验；"抽象指导，不是具体代码模板"
- `hooks/hooks-claude.json`：8 个 hook 事件 → guard.mjs / notify.mjs / ralph-loop.mjs
- `scripts/`：73 个 .mjs（guard-rules、delivery-gate、turn-stop-gate、session-capsule、runtime-ttl、qa-review-state、ralph-loop、cli-doctor 等）
