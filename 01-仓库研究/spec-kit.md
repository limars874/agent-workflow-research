# spec-kit

## 基本信息

| 项 | 内容 |
|---|---|
| 地址 | https://github.com/github/spec-kit |
| 作者 | GitHub 官方（Organization），核心贡献者包括 Den Delimarsky、John Lam 等 |
| Stars | 约 11.8 万（118k，2026-07 数据），是该领域 star 最高的项目之一 |
| License | MIT |
| 主语言 | Python（specify CLI）+ Markdown（命令模板）+ Bash/PowerShell（运行时脚本） |
| 目标 agent host | **通用/跨 host**：官方声称支持 30+ AI 编码 agent（Claude Code、GitHub Copilot、Gemini CLI、Cursor、Windsurf、Qwen、opencode、Codex CLI、Amazon Q 等），通过 `specify init --integration <agent>` 生成对应 host 的命令文件 |
| 安装方式 | `uv tool install specify-cli --from git+https://github.com/github/spec-kit.git`，然后 `specify init my-project --integration copilot` |

## 定位与设计哲学

**一句话定位**：GitHub 官方的 Spec-Driven Development（SDD，规格驱动开发）工具包——用一套标准化的斜杠命令 + 模板 + 脚本，把 AI 编码从"vibe coding 单次 prompt 生成"变成"宪法 → 规格 → 计划 → 任务 → 实现 → 收敛"的多阶段流水线。

**它认为 agent 编码的核心问题是**（见 `spec-driven.md`）：

1. 传统开发中"代码是真理，规格会腐烂"，意图与实现之间的鸿沟无法靠文档和流程弥合；
2. AI 单次 prompt 生成代码是不可控的赌博，缺乏组织级护栏；
3. 因此做**权力反转（fundamental inversion）**：规格成为唯一真理来源（source of truth），代码只是规格的"生成表达"——规格必须"精确、完整、无歧义到足以生成可工作系统"，即 **executable specifications**；
4. 需求变更不再是灾难，而是"重新生成（regeneration）"的常规操作。

## 核心机制

### 1. 双层结构：CLI 脚手架 + 命令模板

- **specify CLI**（Python）：只负责初始化和升级——把模板、脚本、命令文件下载到项目里，并按所选 agent host 的格式落盘（如 Claude Code 的 `.claude/commands/`、Copilot 的 prompt 文件等）。CLI 本身不参与运行时。
- **命令模板**（`templates/commands/*.md`）：真正的核心资产，是写给 LLM 的结构化 prompt，占位符（如 `__SPECKIT_COMMAND_SPECIFY__`）在 init 时按 host 替换。

### 2. 项目文件结构（init 之后）

```
.specify/
├── memory/constitution.md      # 项目宪法（不可变原则）
├── scripts/bash/               # 运行时脚本（另有 PowerShell 版）
│   ├── common.sh (26KB)        # 公共函数：路径解析、分支检测等
│   ├── create-new-feature.sh   # 建分支+spec 目录
│   ├── setup-plan.sh / setup-tasks.sh
│   └── check-prerequisites.sh  # 阶段前置校验，输出 JSON
├── templates/                  # spec/plan/tasks/checklist/constitution 模板
├── extensions/ presets/        # 扩展与预设
└── extensions.yml              # hook 配置

specs/001-feature-name/         # 每个 feature 一个编号目录
├── spec.md  plan.md  tasks.md
├── data-model.md  research.md  quickstart.md
├── contracts/                  # API 契约
└── checklists/requirements.md  # 规格质量检查清单
```

### 3. 命令集（10 个，`/speckit.` 前缀）

| 命令 | 作用 | 机制要点 |
|---|---|---|
| `constitution` | 建立项目治理原则 | 写入 `memory/constitution.md`，后续所有阶段以此为最高权威 |
| `specify` | 需求→规格 | 生成 2-4 词短名，建编号目录（sequential `NNN-` 或 timestamp），复制模板填充；`[NEEDS CLARIFICATION]` 标记**最多 3 个**，按 scope>安全>UX 排序；自动生成 `checklists/requirements.md` 质量清单并最多迭代 3 轮自校验 |
| `clarify` | 结构化澄清 | 9 类歧义扫描（功能边界/数据模型/UX/非功能/集成/边界失败/约束/术语/完成信号），每类标 Clear/Partial/Missing，按 Impact×Uncertainty 排队，**最多 5 问、一次一问**，多选题带推荐项；每答一题立即原子化写回 spec 的 `## Clarifications` session 记录 + 相关章节 |
| `plan` | 技术实现计划 | 选定技术栈，产出 plan.md/data-model.md/contracts/research.md |
| `tasks` | 生成任务清单 | **按 user story（P1/P2/P3）组织而非按组件**；阶段：Setup→Foundational→逐 story→Polish；格式 `- [ ] T001 [P] [US1] 描述 + 精确文件路径`，`[P]` 标可并行，显式依赖声明，每 story 可独立测试（US1 即 MVP） |
| `analyze` | 跨工件一致性审查 | **只读**，6 类检测（重复/歧义/欠规格/宪法对齐/覆盖缺口/不一致），4 级严重度（宪法违反自动 CRITICAL），输出 findings 表 + 需求-任务覆盖矩阵；修复须用户批准 |
| `checklist` | 生成领域检查清单 | 针对特定质量维度生成 checklist |
| `implement` | 逐阶段执行任务 | 先跑 `check-prerequisites.sh` 拿 JSON 上下文；若 checklist 有未完成项则**暂停询问用户**；按 phase 顺序执行、尊重依赖与 `[P]`、TDD 先测后码；完成一个任务即在 tasks.md 标 `[X]`；非并行任务失败即停 |
| `converge` | 实现后差距收敛 | 建"意图清单"（FR-###/SC-###/验收场景/宪法义务），对照代码分类 missing/partial/contradicts/unrequested，按严重度**只追加** `## Phase N: Convergence` 任务到 tasks.md，全收敛则报 "✅ Converged" 不动文件 |
| `taskstoissues` | 任务转 GitHub Issues | 与 GitHub 平台打通 |

### 4. Constitution（宪法）机制

`spec-driven.md` 给出九条示范条款：Library-First（每个功能先做成独立库）、CLI Mandate（一切功能暴露文本接口以便观测）、Test-First（无失败测试不写代码）、Simplicity（初始最多 3 个 project）、Anti-Abstraction（直接用框架不做包装）、Integration-First（用真库真服务而非 mock）等。宪法在 analyze/converge 中是"不可协商的权威"——冲突只能改工件，不能稀释原则。

### 5. 扩展体系（较新版本）

Extensions（新命令/新阶段）、Presets（改造既有工作流以符合组织规范）、Bundles（按角色打包）；优先级栈：项目本地 overrides > presets > extensions > core 默认。`extensions.yml` 定义各命令的 before/after hooks（enabled/mandatory/condition 字段），命令 prompt 内置 hook 解析逻辑。

## 步骤流覆盖

| 步骤 | 覆盖 | 说明 |
|---|---|---|
| 澄清意图 | ✅ 强 | 独立 `/clarify` 命令：9 类歧义分类学 + 最多 5 问逐问 + 答案原子写回 spec；specify 阶段另有最多 3 个 `[NEEDS CLARIFICATION]` 标记机制 |
| 治理上下文 | ✅ 强 | constitution 作为跨会话持久记忆（`memory/constitution.md`）；每命令按需加载 spec/plan/data-model 等，`check-prerequisites.sh` 输出 JSON 路径清单让 agent 精准加载 |
| 写清规格 | ✅ 极强（核心卖点） | spec-template 强制 WHAT/WHY 不写 HOW、可测试 FR、技术无关的可度量成功标准；自动生成 requirements checklist 并自校验最多 3 轮 |
| 小步切片 | ✅ 强 | tasks 按 user story 优先级切片，每 story 独立可测、US1=MVP；`[P]` 并行标记 + 显式依赖 |
| 实现功能 | ✅ | `/implement` 分 phase 顺序执行，TDD、依赖尊重、逐任务打 `[X]` |
| 验证证据 | ⚠️ 中 | 依赖 TDD 与 checklist（进入 implement 前校验 checklist 完成度并暂停询问），但没有强制"跑测试出证据"的独立机制，验证质量取决于 agent 自觉 |
| 独立审查 | ⚠️ 中偏弱 | `/analyze` 是工件层（spec/plan/tasks）一致性审查而非代码审查；`/converge` 算实现后的代码-意图差距审查，但都是同一 agent 自审，无独立第二 agent 视角 |
| 可控发布 | ⚠️ 弱 | 有 git 分支纪律（每 feature 一分支）和 `taskstoissues`，但无 PR/发布/回滚流程 |
| 复盘沉淀 | ❌ 基本缺失 | 方法论文档提"生产反馈回流规格"，但无具体命令；clarify 的 session 记录算轻量沉淀，无经验教训库机制 |

## 横切能力覆盖

| 能力 | 覆盖 | 说明 |
|---|---|---|
| Task State 中断恢复 | ✅ 好 | 一切状态落盘为 markdown：tasks.md 的 `[X]` 逐任务持久化、clarify 每答即写、`.specify/feature.json` 记路径——新会话可从文件恢复；但无显式 "resume" 命令 |
| Journal-Trace | ⚠️ 部分 | Clarifications session 记录、FR-###/SC-### 编号使需求-任务-代码可追溯（converge 靠此工作）；无运行日志/决策日志机制 |
| Safety Guardrails | ⚠️ 部分 | analyze 严格只读、converge 只追加不改写、implement 前 checklist 门禁需用户确认；但无破坏性操作防护、无权限模型 |
| Tool Compatibility 跨 host | ✅ 极强（业界标杆） | 单一模板源 + 占位符替换，init 时生成 30+ 种 host 的命令文件；脚本双实现（bash + PowerShell）覆盖跨 OS |
| Runtime-Scripts 机器验证下沉 | ✅ 强 | 分支创建、目录编号、前置校验等确定性工作全部下沉到 shell 脚本（common.sh 26KB），脚本输出 JSON 供 agent 消费，避免 LLM 做易错的文件系统操作 |

## 独特亮点

1. **`/clarify` 的歧义分类学**：9 大类结构化覆盖扫描 + Impact×Uncertainty 优先级排序 + 每题多选带推荐 + 答案原子化写回——是所有同类框架中最工程化的"澄清意图"实现，且硬上限（5 问）防止审问式体验。
2. **需求可追溯闭环（analyze + converge）**：FR/SC 编号 → 任务 `[US#]` 标签 → 覆盖矩阵 → 实现后 converge 反向对照代码分类差距（missing/partial/contradicts/unrequested）并只追加修复任务，形成"意图必达"的闭环，这是多数框架没有的实现后校验阶段。
3. **跨 host 分发架构**：模板占位符 + CLI 按 integration 编译落盘 + bash/PowerShell 双脚本，一套内容服务 30+ agent，接入成本被 CLI 完全吸收。

## 明显欠缺

- **无独立审查者**：analyze/converge 都是自审，没有第二 agent/对抗性 code review 机制；也不审代码质量本身（只审"是否符合规格"）。
- **验证证据薄弱**：没有强制"运行测试并出示输出"的机器化验证环节，TDD 靠 prompt 约束。
- **无复盘沉淀**：没有 retrospective/lessons-learned 命令，宪法也不会从项目经验中自动演化。
- **重前期、brownfield 弱**：流程假设从规格出发，对已有大型代码库的理解/摸底阶段支持有限（converge 是补丁而非方案）。
- **流程仪式感重**：小改动也要走 spec→plan→tasks 全流程，官方虽称支持增量，但缺"轻量模式"。
- **无发布/回滚**：止步于 implement/converge，CI/PR/部署不在范围内。

## 臃肿度与耦合度评价

- **重量级**：完整流程 6-9 个阶段、每 feature 产出 5+ 个文档，模板 + 脚本 + 扩展体系总量可观（common.sh 一个脚本 26KB）。适合中大型 feature，对小任务是明显 overhead。
- **host 耦合极低**：这是它最大的架构优点——核心资产是纯 markdown prompt + shell 脚本，不依赖任何 host 私有 API；CLI 做适配层。换 agent 只需 re-init。
- **学习成本中等**：命令语义直观（specify/plan/tasks/implement 自解释），README 和 spec-driven.md 文档完善；但要用好 constitution/extensions/presets 优先级栈需要额外投入。
- **接入成本低**：一条 `uv tool install` + `specify init` 即可；对已有项目也可 init（brownfield 模式）。
- **锁定风险低**：所有产物是项目内的 markdown，随时可退出框架继续手工维护。

## 关键证据

- `README.md`：命令表（constitution/specify/clarify/plan/analyze/tasks/taskstoissues/implement/converge）、30+ agent 集成、`.specify/` 目录结构、extensions/presets/bundles 优先级栈。
- `spec-driven.md`：方法论宣言——"specifications become the source of truth, and code becomes their generated expression"；宪法九条（Library-First / CLI Mandate / Test-First / Simplicity / Anti-Abstraction / Integration-First）；"12+ 小时文档工作 15 分钟完成"。
- `templates/commands/specify.md`：短名生成规则、`NNN-`/timestamp 编号方案、`[NEEDS CLARIFICATION: ...]` 最多 3 个、`checklists/requirements.md` 自校验最多 3 轮、hooks.before/after_specify。
- `templates/commands/clarify.md`：9 类歧义分类、Clear/Partial/Missing 标记、最多 5 问、`## Clarifications / ### Session YYYY-MM-DD` 写回格式。
- `templates/commands/tasks.md`：`- [ ] T001 [P] [US1] Create User model in src/models/user.py` 格式、按 story 分 phase、US1=MVP。
- `templates/commands/analyze.md`：6 类检测、CRITICAL/HIGH/MEDIUM/LOW、只读约束、"never principle dilution"（宪法权威）。
- `templates/commands/implement.md`：checklist 门禁暂停询问、逐任务 `[X]`、非并行失败即停/并行失败继续报告。
- `templates/commands/converge.md`：意图清单（FR-###/SC-###）、gap 分类 missing/partial/contradicts/unrequested、只追加 `## Phase N: Convergence`。
- `scripts/bash/`：common.sh(26KB)、create-new-feature.sh、check-prerequisites.sh、setup-plan.sh、setup-tasks.sh（另有 PowerShell 镜像）。
- GitHub API：stars ≈ 118k，MIT，owner=github（Organization）。
