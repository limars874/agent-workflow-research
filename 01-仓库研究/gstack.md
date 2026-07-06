# gstack

## 基本信息

- **地址**: https://github.com/garrytan/gstack
- **作者**: Garry Tan（Y Combinator 总裁兼 CEO），自称"open source software factory that I use every day"
- **发布/热度**: 2026-03-12 开源，数天内 ~20K stars，11 天 39K，六周内 85K（不同报道口径 71K-85K），量级为**数万 stars 的现象级仓库**
- **License**: MIT，无付费层
- **目标 agent host**: 首要为 **Claude Code**（skills 机制），setup 脚本自动检测并部署到 Codex CLI、Cursor、OpenCode、Hermes、Kiro、OpenClaw、Slate、Factory 等（`hosts/` 目录下每个 host 一个 TypeScript adapter：claude.ts / codex.ts / cursor.ts / opencode.ts / hermes.ts / kiro.ts / openclaw.ts / slate.ts / factory.ts / gbrain.ts）
- **安装**: `git clone ... ~/.claude/skills/gstack && ./setup`，支持 team mode（共享仓库安装+自动更新）
- **规模**: 40+ 个 skill 目录（每个 skill 一个目录含 SKILL.md），外加 Bun 编写的浏览器守护进程、脚本库

## 定位与设计哲学

**一句话定位**：把 Claude Code 变成一个"23 人虚拟工程团队 + 软件工厂"的 skill 全家桶，用角色化 slash command 覆盖从产品构思到上线监控的完整 SDLC。

**它认为 agent 编码的核心问题**：不是模型不会写代码，而是**单一 agent 缺乏组织纪律**——没人质疑需求、没人做架构评审、没人独立 QA、没人守发布关口。解法是把一个真实工程组织的角色分工（CEO/PM/设计/工程/安全/QA/发布）编码成 prompt，让每个角色"知道该做什么、什么时候停"。

**ETHOS.md 三条原则**（原文）：
1. **Boil the Ocean** — "When the complete implementation costs minutes more than the shortcut — do the complete thing."（AI 时代工程时间不再稀缺，拒绝走捷径）
2. **Search Before Building** — "The 1000x engineer's first instinct is 'has someone already solved this?'"
3. **User Sovereignty** — "AI models recommend. Users decide. This is the one rule that overrides all others."（人类保留最终决策权，AI 不得自主实施）

## 核心机制

### 文件结构
- 仓库根目录即 skill 集合：每个 slash command 对应一个目录（`office-hours/`、`review/`、`qa/`、`ship/`...），内含 `SKILL.md`（prompt 本体）及辅助脚本/checklist。
- 根级文档：`ETHOS.md`（哲学）、`ARCHITECTURE.md`（浏览器守护进程架构）、`DESIGN.md`、`AGENTS.md`、`CLAUDE.md`、`SKILL.md.tmpl`（模板）。
- **无自有 runtime（prompt 层面）**：所有 skill 是 Markdown，跑在 host 原生 skill 机制上；但配套一个 **Bun 编译的浏览器守护进程**（`/browse`）作为机器执行层。
- **产物目录**：`~/.gstack/projects/$SLUG/` 存设计文档、架构图、测试计划、retros、learnings.jsonl、checkpoints——**产物跨 session、跨 skill 传递是核心机制**。

### 七阶段流水线（Think → Plan → Build → Review → Test → Ship → Reflect）
```
/office-hours（YC 式拷问需求）→ 设计文档
  → /plan-ceo-review（品味/愿景）→ /plan-design-review（80 项设计审计）
  → /plan-eng-review（架构+测试计划）→ /plan-devex-review
  （/autoplan 可把以上评审链自动串行，只把"品味决策"抛给人）
  → 实现 → /review（Claude 偏执审计）+ /codex（OpenAI 跨模型二审）
  → /qa（真实 Chromium 点测 + 自动修 bug + 生成回归测试）
  → /ship（测试过→同步 main→建 PR）→ /document-release（同步文档）
  → /land-and-deploy（合并+部署+健康检查）→ /canary（上线后监控）
  → /retro（周复盘）+ /learn（沉淀模式库）
```

### Prompt 组织方式（以 /review 为例，机制最重的 skill）
- Frontmatter 声明触发词（"review this pr" 等）；preamble 初始化 session state、加载 prior learnings。
- Step 0-1 确定 git base 与 diff；Step 1.5 **scope drift 分析**（实际改动 vs TODOS.md/PR 描述/plan 文件声明的意图，做完成度审计）。
- Step 2 读 `checklist.md`（SQL 安全、竞态、LLM trust boundary、enum 完整性等）。
- Step 4 Critical Pass：每个 finding 必须带 **1-10 置信度分**；低于 7 且非高危则压制；**pre-emit gate 要求引用触发该 finding 的具体代码行**，引用不出来则降为 4-5 并移入附录。
- Step 4.5 **Specialist Dispatch**：并行派发 Testing/Security/Performance/Data Migration/API Contract/Design 等子 agent，按 diff 规模与 scope 信号（SCOPE_AUTH 等）自适应选择，且**按历史命中率 gating**；输出 JSON findings，按 `{path}:{line}:{category}` 指纹去重，多 specialist 命中则升置信度。diff >200 行或有 CRITICAL 时追加 **Red Team 子 agent**。
- **对抗式双模型审查**：Claude 子 agent 永远跑；diff ≥200 行且 Codex 已认证则跑 `codex review`，Codex 发现 P1 时**门禁阻断 ship**，需用户显式 override。
- Step 5 Fix-First：finding 分类为 AUTO-FIX（直接修）/ ASK（合并成一次 AskUserQuestion）。
- 输出 PR Quality Score（0-10），findings 记入 `gstack-review-log` 做遥测与历史压制。

### 浏览器守护进程（ARCHITECTURE.md）
- 三层：编译的 Bun CLI → `Bun.serve` HTTP server → 持久 headless Chromium（CDP）。"an AI agent interacting with a browser needs sub-second latency and persistent state"——首次 ~3s，后续 100-200ms。
- 状态文件 `.gstack/browse.json`（PID/端口/Bearer token），随机高位端口（10000-60000）支持 10+ workspace 并存；二进制 hash 比对自动重启旧版本。
- 安全：仅绑 127.0.0.1 + Bearer token；双 listener（tunnel 侧只暴露 /connect、/command 有限端点）；cookie 只读内存解密；**prompt injection 防御分层**：内容规则 + BERT-small ONNX 分类器 + transcript 分析 + canary token 检测系统 prompt 泄漏。
- SKILL.md 用模板占位符（`{{COMMAND_REFERENCE}}`）在构建时从源码元数据填充——**文档不会与实现漂移**。

## 步骤流覆盖

| 步骤 | 有无 | 怎么做 |
|---|---|---|
| 澄清意图 | ✅ 极强 | `/office-hours`：YC 合伙人式拷问（用户是谁、痛点、现有方案缺陷），产出设计文档才允许往下走；`/plan-ceo-review` 再过一遍品味/愿景 |
| 治理上下文 | ✅ | `/context-save`/`/context-restore` 显式 checkpoint；产物落盘 `~/.gstack/projects/$SLUG/` 跨 session；`/setup-gbrain` 跨机器记忆同步 |
| 写清规格 | ✅ | 设计文档 + `/plan-eng-review` 产出架构图与测试计划（artifact 被 /qa 自动加载）；`/design-consultation` 产出 DESIGN.md 并写入 CLAUDE.md 约束后续所有 session |
| 小步切片 | ⚠️ 弱 | 无显式任务切片/stacked-PR 机制；/qa 会做 atomic fix commits，但没有"把大特性拆成小 PR 序列"的 skill |
| 实现功能 | ⚠️ 有意留白 | Build 阶段就是裸 Claude Code 实现，无专门实现 skill（哲学上认为约束应在前后两端） |
| 验证证据 | ✅ 极强 | `/qa` 真实 Chromium 点击流+截图+console 日志+生成回归测试；`/browse` 守护进程；`/benchmark` Core Web Vitals；`/health` 加权 0-10 质量分 |
| 独立审查 | ✅ 极强 | `/review` 多 pass+specialist 子 agent+Red Team；`/codex` 跨厂商独立二审（overlap=高置信、divergence=盲点）；`/cso` OWASP+STRIDE 安全审计 |
| 可控发布 | ✅ | `/ship`（测试门禁→PR）→ `/document-release` → `/land-and-deploy`（合并+部署+健康检查）→ `/canary` 上线后监控；Eng Review 是 ship 硬前置 |
| 复盘沉淀 | ✅ | `/retro` 基于 commit 历史与测试指标的周复盘；`/learn` 写 `learnings.jsonl` 模式库（带置信分），**其他 skill 推荐前自动查询**并标注"Prior learning applied"；`/skillify` 把 /scrape 原型固化为可复用 skill（含脚本+测试+fixture） |

## 横切能力覆盖

- **Task State 中断恢复**: ✅ `/context-save` 写 `~/.gstack/projects/{SLUG}/checkpoints/{timestamp}-{title}.md`，YAML frontmatter（status/branch/files_modified）+ Summary/Decisions Made/Remaining Work，append-only 不覆盖；`/context-restore` 支持跨 branch 恢复。
- **Journal-Trace**: ✅ 部分。review findings 记 `gstack-review-log`（决策历史+遥测）、learnings.jsonl、retros 目录；但没有统一的全程操作 journal。
- **Safety Guardrails**: ✅ 专门 skill 族：`/careful`（危险命令警告：rm -rf、DROP TABLE、git push --force，白名单如 rm -rf node_modules 放行）、`/freeze`（限制编辑到单目录，/investigate 调试时自动激活）、`/guard`（careful+freeze 组合）、`/unfreeze`。浏览器侧另有 prompt injection 多层防御。
- **Tool Compatibility 跨 host**: ✅ `hosts/` 目录每个 host 一个 adapter（claude/codex/cursor/opencode/hermes/kiro/openclaw/slate/factory），setup 自动检测部署；`/pair-agent` 甚至支持跨厂商 agent 共享浏览器 session（scoped token+tab 隔离）。
- **Runtime-Scripts 机器验证下沉**: ✅ 是同类框架中最重的：Bun 编译二进制浏览器守护进程、CDP 控制、ring buffer 日志、iOS StateServer+Mac daemon（/ios-qa 闭环 find-fix-verify）、/diagram 离线渲染、slop-scan 等。大量验证不靠 LLM 自述而靠真实运行。

## 独特亮点

1. **跨模型对抗审查 + 置信度校准**：/review 的"必须引用代码行否则降置信"pre-emit gate、specialist 按历史命中率 gating、Claude/Codex 双审对比找模型盲点、P1 阻断门禁——是目前见到的 review prompt 中工程化程度最高的设计之一。
2. **真实浏览器验证下沉到守护进程**：持久 Chromium + 100-200ms 命令延迟 + cookie 会话导入 + iOS 真机闭环，把"验证证据"做成了机器事实而非模型口述；SKILL.md 从源码构建生成，文档零漂移。
3. **组织化角色分工 + 产物接力**：设计文档→测试计划→QA 自动加载、DESIGN.md 约束后续 session、learn 模式库被所有 skill 前置查询——上下文以落盘 artifact 而非对话记忆传递，天然抗 session 中断。

## 明显欠缺

- **无小步切片/任务分解机制**：没有 stacked PR、没有把 plan 拆成可独立验证的 task 序列的 skill；从 plan 到 build 之间是一整块，大特性仍靠人肉切。
- **Build 阶段无约束**：实现环节没有 TDD 循环、没有 per-step 验证协议，纪律全压在前置评审和后置 review/qa 上。
- **重、面向 web/iOS 全栈创业场景**：40+ skill、Bun 守护进程、浏览器栈，对纯后端/库/CLI 项目大量 skill 无用；`/office-hours` 的 YC 拷问对企业内部维护性任务不适配。
- **单实例角色切换非真多 agent**：并行要靠外部工具（Conductor 等多 worktree 实例），仓库本身不提供编排器。
- **learnings/telemetry 无治理**：learnings.jsonl 长期膨胀后的检索质量、误学习清理机制未见说明。

## 臃肿度与耦合度评价

- **臃肿度：重。** 40+ skill、浏览器守护进程、iOS 全套、gbrain 记忆同步、PDF/diagram 工具——是"全家桶软件工厂"，不是可挑拣的轻量库。但 prompt 层皆为 Markdown，可以只装用得上的目录。
- **host 耦合：中低。** 核心是 Markdown skill + `hosts/` adapter 层，官方支持 8+ host；但最强能力（/browse 守护进程、/pair-agent、subagent 派发）依赖 Claude Code 的 subagent/工具能力，在其他 host 上会降级。
- **学习/接入成本：中高。** 一条命令安装，单个 skill 即用即会；但完整流水线（七阶段+artifact 目录约定+gbrain）需要按它的方法论重塑工作方式，且默认写 `~/.gstack/`、修改 CLAUDE.md，对已有项目有一定侵入性。

## 关键证据

- 仓库：https://github.com/garrytan/gstack （README.md：七阶段架构、23+ skills、MIT、"I open sourced how I build software"）
- `ETHOS.md`：三原则原文 "Boil the Ocean" / "Search Before Building" / "AI models recommend. Users decide."
- `docs/skills.md`：全 skill 清单、阶段表、数据流图；"Test Plan Handoff: /plan-eng-review writes test strategy to ~/.gstack/projects/. When /qa runs, it auto-loads that artifact." "Every skill queries /learn before recommending."
- `review/SKILL.md`：置信度 1-10、pre-emit gate（"I cannot quote the line" = unverified）、specialist dispatch（SCOPE_AUTH 等信号 + hit-rate gating）、指纹去重 `{path}:{line}:{category}`、Codex P1 门禁 "GATE: PASS/FAIL"。
- `context-save/SKILL.md`：`~/.gstack/projects/{SLUG}/checkpoints/{timestamp}-{title}.md`，append-only，frontmatter 含 branch/status/files_modified。
- `ARCHITECTURE.md`：Bun 三层架构、`.gstack/browse.json` 状态文件、随机端口 10000-60000、BERT-small ONNX prompt injection 分类器、SKILL.md 模板占位符构建时填充。
- `hosts/` 目录：claude.ts、codex.ts、cursor.ts、opencode.ts、hermes.ts、kiro.ts、openclaw.ts、slate.ts、factory.ts、gbrain.ts。
- Safety skill 目录：`careful/`、`freeze/`、`guard/`、`unfreeze/`；docs/skills.md："`rm -rf node_modules` OK, `rm -rf src/` blocked"、"/investigate auto-activates /freeze"。
- Stars 量级来源：搜索结果（Pulumi Blog、SitePoint、Towards AI 等报道：11 天 39K、六周 85K）。
