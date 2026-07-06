# superpowers

## 基本信息

| 项 | 内容 |
|---|---|
| 地址 | https://github.com/obra/superpowers |
| 作者 | Jesse Vincent (obra，Perl RT / K-9 Mail 作者，资深工程师) |
| Stars | ~246k（GitHub API 2026-07 数据：stargazers 246,544 / forks ~21.9k），该领域现象级头部项目 |
| 创建时间 | 2025-10 |
| 目标 host | **多 host 通用**：Claude Code（一等公民）+ Codex CLI/App、Cursor、Antigravity、Kimi Code、GitHub Copilot CLI、Factory Droid、OpenCode、Pi、Gemini。仓库根目录有 `.claude-plugin/`、`.codex-plugin/`、`.cursor-plugin/`、`.kimi-plugin/`、`.opencode/`、`.pi/`、`gemini-extension.json` 等各 host 适配层 |
| 描述 | "An agentic skills framework & software development methodology that works." |

## 定位与设计哲学

**一句话定位**：一套"可组合技能（skills）+ 强制性开发流程（methodology）"的 agent 编码框架——不是工具集，而是把资深工程师的软件工程纪律（TDD、根因调试、设计先行、独立评审）编码成 agent 必须遵守的流程。

**它认为 agent 编码的核心问题是**：
1. **Agent 会直接跳到写代码**——未澄清需求、未验证设计就动手，靠"合理化借口"（"太简单不用测试"、"先实现再优化"）绕过纪律。
2. **上下文污染**——长会话中 controller 积累无关上下文，导致质量下降。解法是每个任务派发全新 subagent，只给最小必要上下文。
3. **Agent 会撒谎式声明完成**——没跑验证命令就说 "Done!"。解法是 verification-before-completion 的 "Iron Law"。

哲学口号："Write tests first, always"、系统化流程 > 临时发挥、简单性优先、"Evidence before claims, always"。

## 核心机制

### 文件结构
```
skills/                    # 14 个技能，每个是目录 + SKILL.md（YAML frontmatter + markdown 正文）
  brainstorming/ writing-plans/ executing-plans/ subagent-driven-development/
  test-driven-development/ systematic-debugging/ verification-before-completion/
  requesting-code-review/ receiving-code-review/ dispatching-parallel-agents/
  using-git-worktrees/ finishing-a-development-branch/ using-superpowers/ writing-skills/
hooks/                     # session-start 注入脚本、hooks.json、hooks-cursor.json、run-hook.cmd(Windows)
scripts/                   # task-brief / review-package 等机器脚本 + 打包同步脚本
.claude-plugin/ .codex-plugin/ ... # 各 host 的薄适配层
docs/porting-to-a-new-harness.md   # 跨 host 移植规范
tests/                     # 用 subagent 测试 skills 本身
```

### 触发机制（invoke-first 原则）
- session 启动时通过 hook/插件把 `using-superpowers/SKILL.md` 包在 `<EXTREMELY_IMPORTANT>` 标签里注入上下文，教模型"回答任何问题之前先检查是否有 skill 适用"。
- 强制规则："If a skill applies to your task, you do NOT have a choice."（skill 适用则必须调用）；优先级：用户指令 > skill > 默认行为；流程类 skill（brainstorming、systematic-debugging）先于实现类 skill。
- 验收测试标准：新会话中说 "Let's make a react todo list"，必须先自动触发 brainstorming 而不是写代码。

### 六阶段主工作流
1. **Brainstorming** — 一次一个问题地澄清意图，提出 2-3 个方案+权衡，产出设计文档到 `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`；**硬门禁**：用户批准设计前禁止任何实现动作。
2. **Git Worktrees** — 建隔离分支 worktree，先验证测试基线为绿。
3. **Writing Plans** — 把 spec 分解成 2-5 分钟粒度的任务，每步含**完整可运行代码**（禁止 "TBD"、"add validation"、"similar to Task N" 等占位语言），存 `docs/superpowers/plans/`。
4. **Subagent-Driven Development** — controller 逐任务派发全新 subagent（经 `scripts/task-brief` 提取任务简报 + 最小接口上下文 + 全局约束原文），实现者自审并提交。
5. **两级评审** — controller 用 `scripts/review-package BASE HEAD` 生成 diff 包，派发 reviewer subagent 做 spec 合规 + 代码质量双裁决；有 Critical/Important 发现则派 fix subagent 修复后重审；全部任务完成后由最强模型做**整分支终审**（`review-package MERGE_BASE HEAD`）。
6. **Finalization** — finishing-a-development-branch 处理合并/清理决策。

### 状态与恢复
- 进度台账持久化在 `.superpowers/sdd/progress.md`，格式如 "Task N: complete (commits <base7>..<head7>, review clean)"；恢复时 controller 读台账跳过已完成任务。
- git commit 是恢复锚点——"even after context compaction, `git log` reveals the work"。
- 执行纪律：任务间不停下来找人确认，连续执行直到阻塞/真歧义/全部完成，叙述最少化（"the ledger and the tool results carry the record"）。

### Prompt 组织方式
每个 SKILL.md 是自足的行为规范，典型结构：核心原则（常有 "Iron Law" 式绝对规则）+ 分步流程 + **"合理化借口反驳表"**（Rationalizations Debunked，逐条驳斥 agent 常见偷懒话术）+ **红旗信号**（出现即回滚重来）。这是对 LLM 心理的对抗性 prompt 工程——附带 `persuasion-principles.md` 说明如何写有说服力的 skill。

## 步骤流覆盖

| 步骤 | 有无 | 怎么做 |
|---|---|---|
| 澄清意图 | ✅ 强 | brainstorming：一次一问、2-3 方案对比、YAGNI、设计文档 + 用户批准硬门禁 |
| 治理上下文 | ✅ 强 | subagent 隔离（不继承 controller 会话历史）、task-brief 只给最小接口上下文、pi 适配层有 compaction-aware 重注入 |
| 写清规格 | ✅ 强 | 设计文档 + spec 自审（查占位符/矛盾/歧义/范围）+ 计划中"每个 spec 需求映射到任务"的核查 |
| 小步切片 | ✅ 强 | 2-5 分钟任务粒度、原子 commit、任务大小以"reviewer 可独立批准/拒绝"为标准 |
| 实现功能 | ✅ | subagent-driven（默认）或 executing-plans（inline 批量+检查点）两条路径 |
| 验证证据 | ✅ 极强 | TDD 强制 RED-GREEN-REFACTOR（必须亲眼看到测试失败）+ verification-before-completion 的 Gate Function（跑命令→读完整输出和 exit code→才能声明） |
| 独立审查 | ✅ 强 | 每任务 reviewer subagent 双裁决 + 修复循环 + 最强模型整分支终审；另有 requesting/receiving-code-review 两个技能 |
| 可控发布 | ⚠️ 中 | finishing-a-development-branch 处理合并决策 + worktree 清理，但无部署/发布/回滚层面内容 |
| 复盘沉淀 | ⚠️ 弱 | writing-skills 支持把经验固化成新 skill（含用 subagent 测试 skill 的方法论），但无自动化的会话后复盘/记忆机制 |

## 横切能力覆盖

| 能力 | 评价 |
|---|---|
| Task State 中断恢复 | ✅ `.superpowers/sdd/progress.md` 台账 + git commit 锚点，明确支持 compaction 后恢复 |
| Journal-Trace | ⚠️ 部分。进度台账 + 各 subagent 写 report file + 设计/计划文档留痕，但无统一结构化 trace/journal 系统 |
| Safety Guardrails | ⚠️ 侧重流程护栏（禁止跳过设计批准、禁止无测试写码、"If you lie, you'll be replaced"），几乎没有破坏性操作/权限层面的安全护栏 |
| Tool Compatibility 跨 host | ✅ 业内标杆。skill 正文"命名动作不命名工具"，每 host 一份 tool-mapping；三种注入形态（Shell Hook / In-Process Plugin / Instructions File）；`docs/porting-to-a-new-harness.md` 是完整移植规范；`.version-bump.json` 管多 host 版本同步 |
| Runtime-Scripts 机器验证下沉 | ✅ 中强。`scripts/task-brief`（提取任务简报）、`scripts/review-package`（生成评审 diff 包）把易错的机械步骤下沉到脚本；TDD/验证靠项目自身测试命令 |

## 独特亮点

1. **对抗性 prompt 工程**：每个 skill 都预判并逐条驳斥 agent 的合理化借口（Rationalizations 表 + Red Flags），把"沉没成本谬误"、"太简单不用测"这类 LLM 典型偷懒模式明文封杀。这是它区别于普通 workflow 文档的核心——它是写给会偷懒的 LLM 的，不是写给人的。
2. **跨 host 架构**：skill 内容与 host 完全解耦（"Skills name actions, not tools. Do not edit skill bodies to fit your harness."），10 个 host 各配薄适配层，且写了正式移植规范和版本同步自动化。多数同类项目只绑 Claude Code。
3. **Subagent 隔离 + 两级评审的闭环**：全新 subagent/任务 + 每任务 reviewer 门禁 + fix 循环 + 最强模型终审 + progress 台账，形成完整的"实现-验证-审查-记录-恢复"闭环，可长时间无人值守跑完整计划。

## 明显欠缺

- **发布/部署环节缺失**：止于分支合并，无 CI/CD、发布策略、回滚。
- **复盘沉淀弱**：writing-skills 是手动的元能力，没有自动从失败/评审发现中沉淀经验或记忆的机制。
- **安全护栏薄**：不涉及危险命令拦截、权限最小化、生产环境保护（依赖 host 自身权限系统）。
- **流程重、仪式感强**：小改动也要走 brainstorming 硬门禁 + 设计文档 + 计划文档，token 与时间成本高；官方立场是"简单任务更需要"，但对快速迭代场景不友好。
- **计划要求"每步含完整代码"**：计划阶段就写全部实现代码，对大型/探索性任务可能不现实，且计划代码与实际实现容易漂移。

## 臃肿度与耦合度评价

- **臃肿度：中等偏重**。仅 14 个 skill、纯 markdown+shell 脚本，代码本体轻；但**运行时开销重**——每会话强制注入 bootstrap，主流程走完需大量 subagent 派发与文档产出，token 消耗显著。
- **耦合度：低**。设计上刻意与 host 解耦，适配层各自独立；skill 之间通过显式名字引用（brainstorming → writing-plans → sdd/executing-plans），链条清晰。
- **接入成本：低**。各 host 官方 marketplace 一键安装；自动注入是硬性要求（"per-session opt-in disqualifies a harness"），装完即生效。
- **学习成本：低-中**。用户几乎不用学（agent 自动走流程），但要理解/定制流程需读全部 SKILL.md；写新 skill 有 writing-skills + 测试方法论支持。

## 关键证据

- README.md：六阶段工作流、多 host 安装、"Write tests first, always"。
- `skills/using-superpowers/SKILL.md`："If a skill applies to your task, you do NOT have a choice."；invoke-first、优先级层级。
- `skills/brainstorming/SKILL.md`：硬门禁原文 "Do NOT invoke any implementation skill... until you have presented a design and the user has approved it."；设计文档路径 `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`。
- `skills/writing-plans/SKILL.md`：2-5 分钟任务、禁 "TBD" 占位、计划存 `docs/superpowers/plans/`、两条执行路径。
- `skills/subagent-driven-development/SKILL.md`：`scripts/task-brief`、`scripts/review-package BASE HEAD`、`.superpowers/sdd/progress.md` 台账、"Do not pause to check in with your human partner between tasks."、最强模型整分支终审。
- `skills/test-driven-development/SKILL.md`："If you didn't watch the test fail, you don't know if it tests the right thing."、Rationalizations 表、Red Flags 删码重来。
- `skills/verification-before-completion/SKILL.md`：Iron Law、Gate Function 五步、"Evidence before claims, always."、"If you lie, you'll be replaced."。
- `skills/systematic-debugging/SKILL.md`：四阶段（根因→模式→假设→实现）、"NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST"、3 次失败即质疑架构。
- `docs/porting-to-a-new-harness.md`："Skills name actions, not tools."、三种注入形态 A/B/C、各 host 对照表、`<EXTREMELY_IMPORTANT>` 包裹注入、验收测试（react todo list 必须触发 brainstorming）。
- 仓库根目录：`.claude-plugin/ .codex-plugin/ .cursor-plugin/ .kimi-plugin/ .opencode/ .pi/ gemini-extension.json hooks/ scripts/ tests/ .version-bump.json`（GitHub contents API 实测）。
- GitHub API：stars 246,544、forks 21,869、created 2025-10-09、topics 含 subagent-driven-development。
