# mattpocock/skills 接入点分析：外挂"项目记忆层"该从哪里接

> 目标：陪伴型 AI 编码 workflow（host Codex）= mattpocock skill 骨架 + 自建"项目记忆层"（耐久约束库 / 跨会话复位状态 / 决策追溯 / 项目 roadmap）。
> 方法：全程 `curl` 拉 raw 真身逐字读，非 WebFetch 摘要。仓库快照 SHA `16a2a5c`。

---

## 1. Skill 清单 + 主流程（原文确认）

`ask-matt` 是路由器，它把全部 skill 组织成**一条主流程 + 两个 on-ramp + 底层词汇层**。主流程原文：`grill-with-docs → (prototype 绕道) → to-prd → to-issues → implement(内驱 tdd) → code-review → commit`。

| Skill | 桶 | 调用方 | 一句话职责 |
|---|---|---|---|
| **grill-with-docs** | eng | 用户 | 主流程入口：`/grilling` + `/domain-modeling`，拷问需求**同时**落 `CONTEXT.md`/ADR（有代码库时用它，留纸面痕迹）|
| **grilling** | prod | 模型 | 拷问原语：一次一问、每问带推荐答案、走完决策树才停；`grill-me`/`grill-with-docs` 都调它 |
| **grill-me** | prod | 用户 | 无代码库时的拷问，**无状态**、不落任何文件 |
| **to-prd** | eng | 用户 | 把当前对话**合成**成 PRD（不再访谈），发到 issue tracker，打 `ready-for-agent` 标签 |
| **to-issues** | eng | 用户 | 把 PRD 拆成**垂直切片**（tracer bullet）独立 issue，连 sub-issue + blocking 边 |
| **implement** | eng | 用户 | 按 PRD/issue 实现，内部驱动 `/tdd`，收尾跑 `/code-review`，commit 到当前分支 |
| **tdd** | eng | 模型 | red-green-refactor 参考；seam 必须**事先与用户确认**；反模式清单 |
| **code-review** | eng | 模型 | 两轴审查（Standards + Spec）并行子 agent，对某 fixed point 的 diff |
| **triage** | eng | 用户 | on-ramp：把**别人提的** issue/PR 走状态机、写 agent brief（`to-issues` 产物不 triage）|
| **diagnosing-bugs** | eng | 模型 | on-ramp：硬 bug 诊断 6 阶段，核心是"先建红灯反馈回路" |
| **domain-modeling** | eng | 模型 | **底层词汇层**：主动挑战术语/写 ADR/内联更新 `CONTEXT.md`（读≠此技能，写才是）|
| **codebase-design** | eng | 模型 | 底层词汇层：deep module / seam / adapter 设计词汇 |
| **improve-codebase-architecture** | eng | 用户 | 巡检 codebase 出 HTML 报告找 deepening 机会 → 喂回主流程 |
| **prototype** | eng | 模型 | 一次性代码回答一个设计问题（logic 终端 app / UI 多变体）|
| **research** | eng | 模型 | 后台 agent 查一手源，产出**带引用的 md 文件**落库 |
| **setup-matt-pocock-skills** | eng | 用户 | **他的 init**：一次性配 issue tracker / triage 标签 / 域文档布局（见 §4）|
| **handoff** | prod | 用户 | 把对话压成 handoff 文档，存 **OS 临时目录**（非 workspace），供新会话接手 |
| **teach / writing-great-skills** | prod | 用户 | 教学 / 写 skill 参考（与本题无关）|
| **wayfinder** | in-progress | 模型 | 未发布：把"超一个会话的大活"建成 issue tracker 上的**决策地图**（见 §3、§5，与我们 roadmap 最相关）|
| **loop-me / claude-handoff** | in-progress | 用户 | 未发布：workflow 规格拷问 / 后台 agent 接力 |

> `plugin.json` 只发布 15 eng + 5 prod；**wayfinder / loop-me / claude-handoff 未进 plugin.json**（in-progress，需自行 link）。

---

## 2. 文件/持久化触点地图（核心）

**结论一句话**：他的持久化几乎全部落在 **`docs/agents/*.md`（setup 一次性配置） + `CONTEXT.md`/`docs/adr/`（域模型） + issue tracker（工作状态） + `.out-of-scope/`（拒绝记忆）** 这四类；进度/复位/roadmap 层他几乎不落盘（只有未发布的 wayfinder 把 roadmap 放进 issue tracker）。

| Skill | 读什么 | 写什么持久物 |
|---|---|---|
| **setup** | `git remote`、`AGENTS.md`/`CLAUDE.md`、`CONTEXT.md`/`CONTEXT-MAP.md`、`docs/adr/`、`docs/agents/`、`.scratch/` | ① 在 `CLAUDE.md` **或** `AGENTS.md` 里写/更新 `## Agent skills` 块；② `docs/agents/issue-tracker.md`、`docs/agents/triage-labels.md`、`docs/agents/domain.md` |
| **grill-with-docs** | `CONTEXT.md`、相关 ADR | 内联更新 `CONTEXT.md`；必要时新建 `docs/adr/NNNN-*.md` |
| **domain-modeling** | `CONTEXT.md`/`CONTEXT-MAP.md`、`docs/adr/`、代码 | 内联更新 `CONTEXT.md`（**纯术语表，禁实现细节**）；`docs/adr/NNNN-*.md`（三条全真才写）|
| **to-prd** | 对话 + `CONTEXT.md` 词汇 + ADR | PRD 发到 issue tracker（GitHub issue / `.scratch/<feature>/PRD.md`），打 `ready-for-agent` |
| **to-issues** | 对话或引用的 issue、`CONTEXT.md`、ADR | 每切片一个 issue（GitHub sub-issue+blocking / `.scratch/<feature>/issues/NN-*.md`）|
| **implement** | PRD/issue、`CONTEXT.md` | 代码 + commit（不改 parent issue）|
| **tdd** | `CONTEXT.md`、ADR | 测试代码（seam 先确认）|
| **code-review** | `git diff`、`docs/agents/issue-tracker.md`、commit 里的 issue 引用、`CODING_STANDARDS.md`/`CONTRIBUTING.md`、PRD | 只出报告，**不落盘**（两轴 verbatim）|
| **triage** | issue/PR 全文、`.out-of-scope/*.md`、`CONTEXT.md`、ADR、`docs/agents/triage-labels.md` | issue 上打标签/贴 agent brief 评论/贴 triage notes；**`.out-of-scope/<concept>.md`（仅拒绝的 enhancement）**；`CONTEXT.md`/ADR（grill 时）|
| **diagnosing-bugs** | `CONTEXT.md`、ADR | 回归测试 + commit（含正确假设）；无 seam 则把"缺 seam"作为发现交给 improve-arch |
| **improve-codebase-architecture** | `CONTEXT.md`、`docs/adr/` | HTML 报告写 **OS 临时目录**（不落库）；grill 时内联更新 `CONTEXT.md`/ADR |
| **research** | 一手源 | 一个带引用的 md，落"库里已有 notes 惯例处" |
| **prototype** | — | 一次性代码（就近、标注可删）；答案存 commit/ADR/issue/`NOTES.md` |
| **handoff** | 当前对话 | handoff md → **OS 临时目录**（明确不进 workspace，引用已有 artifact 不重复）|
| **wayfinder**（未发布）| map issue（低分辨率一次性加载）、`docs/agents/issue-tracker.md` 的 "Wayfinding operations" 段 | **map issue**（label `wayfinder:map`，含 Destination/Notes/Decisions-so-far/Not-yet-specified/Out-of-scope）+ 子 issue tickets；本地兜底 `.scratch/<effort>/map.md`+`issues/NN-*.md` |

### 关键持久物 · 谁写谁读

- **`CONTEXT.md`（+ 多上下文时 `CONTEXT-MAP.md`）**：**写**=domain-modeling（经 grill-with-docs / improve-arch / triage-grill 触发）；**读**=几乎所有 eng skill（to-prd/to-issues/tdd/diagnose/code-review 用它的词汇命名）。格式硬约束：**只是术语表**，`_Avoid_` 列同义词，禁实现细节/spec/scratch。
- **ADR `docs/adr/NNNN-slug.md`**：**写**=domain-modeling（"难逆转 + 无上下文会困惑 + 真权衡"三条全真才写，可只一段话）；**读**=to-prd/to-issues/tdd/diagnose/improve-arch（不得 re-litigate，冲突要显式标注 `Contradicts ADR-0007…`）。多上下文时还有 `src/<ctx>/docs/adr/`。
- **`docs/agents/{issue-tracker,triage-labels,domain}.md`**：**写**=**仅 setup**（一次性）；**读**=to-prd/to-issues/triage/code-review/wayfinder。这是他"配置即约定"的核心——skill 假设它们存在（hard-dep skill 会喊 `run /setup…`）。
- **`.out-of-scope/<concept>.md`**：**写**=triage（拒绝的 enhancement，一 concept 一文件，含 Why + Prior requests 列表）；**读**=triage（下次 gather context 时按概念相似度查重）。仓库自身把它当**产品级拒绝决策库**用（见 `.out-of-scope/*.md` 五个真实文件）。
- **issue tracker**（GitHub Issues / `.scratch/` 本地 md / GitLab）：所有"工作单元 + 状态"的家。triage 状态=标签（本地=`Status:` 行）；wayfinder 的 roadmap 也寄生在这里。
- **`AGENTS.md` / `CLAUDE.md`**：setup 只往里写一个 `## Agent skills` 块（三条指向 `docs/agents/*.md` 的**指针**），**不写约束本身**；choose 规则：`CLAUDE.md` 存在就改它，否则 `AGENTS.md`，都没有则问用户，**绝不在已有 CLAUDE.md 时新建 AGENTS.md**。

---

## 3. 他已有的"记忆味"东西 vs 我们要的四样

| 我们要的 | 他有没有 | 到什么程度 / 载体 | 缺口 |
|---|---|---|---|
| **耐久约束库**（前后端/架构/风格/技术约束）| **部分有** | ①约束**理由**→ ADR（架构决定、技术锁定、"不可见约束"如合规/延迟，原文 ADR-FORMAT 明列这些）；②约束**词汇**→ `CONTEXT.md`（但只准放术语表）；③编码风格→ 他**读** `CODING_STANDARDS.md`/`CONTRIBUTING.md` 但从不生成；④哪个 tracker/布局→ `docs/agents/*.md` | 没有一个**统一的、供每步强制加载的"活跃约束清单"**。ADR 是离散历史事件、非"当前生效约束集合"；`CONTEXT.md` 被刻意限死为术语表不能放"前端必须用 X"。 |
| **跨会话复位状态**（进度/我在哪）| **几乎没有** | 只有 `handoff`（一次性、存 OS temp、**用完即弃**、明确不进 repo）；issue tracker 的标签算粗粒度状态；wayfinder 的 map 是**大活规划**级、非日常进度 | **完全没有** repo 内、可复位、跨会话的"当前进度/下一步"文件。他的哲学是"context hygiene"——步骤 1-3 一个不断的 window 内做完，每个 implement 从 issue 全新起，**主动不留会话状态**。 |
| **决策追溯** | **有，且是他强项** | ADR（架构/技术/边界决策，含 why+权衡+被拒选项）+ `.out-of-scope/`（被拒需求 + prior requests）+ triage agent brief + PRD 的 Implementation/Testing Decisions 段 | 追溯是**分散的**（ADR/out-of-scope/issue 各管一摊），无单一时间线索引。 |
| **项目 roadmap** | **仅未发布的 wayfinder 有** | wayfinder 把 roadmap 建成 issue tracker 上的 `wayfinder:map`（Destination + Decisions-so-far 索引 + Not-yet-specified 迷雾 + Out-of-scope），tickets 是子 issue，用**原生 blocking 边**画 frontier | 已发布 skill 里**无 roadmap**。且 wayfinder 是**规划层**（"produce decisions, not deliverables"），非"功能开发进度看板"。 |

---

## 4. setup skill = 他的 init（bootstrap 了什么）

**一次性、prompt 驱动、非脚本**。流程：探测 → 逐条问（一次一个）→ 给草稿让用户改 → 写。bootstrap 三样：

1. **issue tracker**（GitHub 默认 / GitLab / 本地 `.scratch/` md / other 自述）→ 写 `docs/agents/issue-tracker.md`（内含该 tracker 的 CLI 约定 + 各 skill "publish/fetch" 语义 + wayfinding 操作）；GitHub/GitLab 追问"外部 PR 算不算请求面"。
2. **triage 标签词汇**（5 个 canonical role 映射到本仓真实标签字串）→ `docs/agents/triage-labels.md`。
3. **域文档布局**（single-context 一个根 `CONTEXT.md` / multi-context 根 `CONTEXT-MAP.md` 指向多个）→ `docs/agents/domain.md`。
4. 在 `CLAUDE.md`/`AGENTS.md` 写 `## Agent skills` 指针块。

**新旧项目怎么处理**：全靠**探测已有文件**（`git remote`、是否已有 `CONTEXT.md`/`.scratch/`/`docs/agents/`）——已存在就 in-place 更新不覆盖用户手改，不存在按默认提议。**域文档 lazy 创建**：setup **不**预建 `CONTEXT.md`/`docs/adr/`，缺了就静默跳过，等 domain-modeling 在术语/决策真正落地时才建（ADR-0001 明确：hard-dep skill 才喊 setup，soft-dep 只模糊引用、缺了照跑）。可 `--verify`：直接跑 setup 让它"只查不改、报 drift"（`.out-of-scope/setup-skill-verify-mode.md` 拒绝为此加独立 flag/skill）。

> **对我们的含义**：他的 init 只 bootstrap"配置/约定指针"，**不 bootstrap 项目实质约束、不 bootstrap 进度/roadmap**。这正是我们记忆层要补的空档，且他已给了标准接法——**`docs/agents/*.md` + 一个 `## Agent skills` 指针块**。

---

## 5. 接入点结论（最重要）

### A. 项目约束 → 最自然接哪个口子

**接 `docs/agents/`（新增文件）+ setup + `## Agent skills` 指针块，不要塞进 `CONTEXT.md`。**

- 理由：`CONTEXT.md` 被 domain-modeling 硬性限死为**纯术语表**（原文："totally devoid of implementation details … a glossary and nothing else"），"前端必须用 React Query""所有金额走 Money 类型"这类**约束**放进去违反其契约、且会和 domain-modeling 抢写权冲突。
- ADR 承接"**难逆转的架构/技术**约束"最自然（ADR-FORMAT 原文已把"代码里看不见的约束：合规、延迟 SLA"列为 qualifies）——但 ADR 是离散历史，不是"当前生效清单"。
- **最佳落点**：新增 `docs/agents/constraints.md`（耐久约束库），并在 setup 的 `## Agent skills` 块加第 4 条指针 `### Project constraints … See docs/agents/constraints.md`。这样**零冲突复用他的加载惯例**：所有 eng skill 探索时本就会读 `docs/agents/*`。可让 to-prd/to-issues/tdd/code-review 的 Standards 轴额外读它（code-review 已经会读 `docs/agents/issue-tracker.md`，加一行读 constraints 即可）。

### B. 复位状态 / 进度 → 他完全没有，会冲突吗？接在哪几步

- **不会硬冲突，但和他的"context hygiene"哲学有张力**：他刻意主张"每个 implement 从 issue 全新起、不留会话状态"。我们加"复位状态"= 用**盘上文件**替代他丢弃的会话记忆——理念互补（Codex 陪伴型正需要跨会话续上），但**别污染他的一次性 artifact**。
- **落点**：新增 `docs/agents/PROGRESS.md`（或 `.session/state.md`），**独立于** handoff（他的 handoff 存 OS temp、用完即弃，我们的要进 repo、可复位）。
- **接在哪几步**（写入点）：`implement` 收尾时、`code-review` 后、每次 commit 后追加"当前切片/下一步/未决问题"；`to-issues` 产出后写初始进度。**读取点**：每个新会话开工先读它复位。
- **与 wayfinder 的关系**：若采纳 wayfinder，roadmap 归 wayfinder map，**日常进度归 PROGRESS.md**，两者分层不重叠（map=大活决策 frontier，PROGRESS=当前 issue 执行到哪）。

### C. roadmap 层 → 加哪不违和

- 已发布 skill 无 roadmap，**加它不与任何现有 skill 打架**。两条路：
  1. **直接采纳 wayfinder**（in-progress）——它本就是 roadmap 层，寄生 issue tracker，且已定义 `docs/agents/issue-tracker.md` 的 "Wayfinding operations" 契约。代价：它是**规划层**（不 do、只产决策），且未发布需自 link。
  2. **自建 `docs/agents/ROADMAP.md`**——若想要"功能开发进度看板"而非"决策 frontier"，wayfinder 语义不完全匹配，自建更贴。挂在 setup 的指针块第 5 条，`grill-with-docs`/`to-prd` 开工前读它对齐方向（正如 ask-matt 说 research/improve-arch 的产物"喂回 grill-with-docs"）。
- 违和最小的位置：**roadmap 作为 `grill-with-docs` 的上游输入 + `to-issues` 的下游归档**——它天然是"idea 从哪来 / issue 归属哪个大目标"，不侵入 implement/tdd 内环。

### D. 他假设存在、需要我们提供的约定文件

| 文件 | 谁假设 | 缺了会怎样 |
|---|---|---|
| `docs/agents/issue-tracker.md` | to-prd/to-issues/triage/code-review/wayfinder（**hard-dep**）| 明确喊 `run /setup-matt-pocock-skills`；tracker 操作无从下手 |
| `docs/agents/triage-labels.md` | triage | 标签字串对不上，会建重复标签 |
| `docs/agents/domain.md` | 域消费规则 | 不知去哪找 `CONTEXT.md`（单/多上下文）|
| `CONTEXT.md` | 全 eng skill（soft-dep）| 静默跳过，输出只是"不够锐"、不报错 |
| `docs/adr/` | 全 eng skill（soft-dep）| 同上，lazy 创建 |
| `.out-of-scope/` | triage | 无历史拒绝去重，会 re-litigate |
| `CONTEXT-MAP.md`（仅多上下文）| domain-modeling | 无则视为单上下文 |
| **`## Agent skills` 块**（在 `CLAUDE.md`/`AGENTS.md`）| setup 维护、各 skill 隐含 | 我们的记忆层文件**必须挂进这个块**才能被自动加载 |

> **→ 结论**：我们**必须提供** `CONTEXT.md`（术语）、`docs/agents/*.md`（配置，交给他的 setup 生成）；**建议新增**并挂进 `## Agent skills` 块的：`docs/agents/constraints.md`（约束库）、`docs/agents/PROGRESS.md`（复位状态）、`ROADMAP.md` 或 wayfinder map（roadmap）。改动 setup skill 加 3 条指针，改 code-review/to-prd/tdd 各加一行"读 constraints"，即完成接入，**不动他任何核心逻辑**。

---

## 6. 诚实标注

- **原文确认**（逐字 curl 读到）：§1-§5 全部 skill 职责、`CONTEXT.md`/ADR/`.out-of-scope`/`docs/agents/*` 的读写方、setup 五步、ask-matt 主流程、wayfinder map 结构、handoff 存 OS temp、plugin.json 未含 wayfinder/loop-me。
- **推断**（基于原文合理外推，非他明说）：§5 里"新增 `docs/agents/constraints.md`/`PROGRESS.md`/`ROADMAP.md` 并挂 `## Agent skills` 块"是**我们的接入方案**，仓库本身没有这些文件；"复位状态与 context-hygiene 有张力"是对其设计意图的解读；wayfinder 能否直接当 roadmap 用取决于我们要"决策 frontier"还是"进度看板"。
- **未拉到 / 未读全**（对本题非关键，故未展开）：`tdd/tests.md`、`tdd/mocking.md`、`codebase-design/DEEPENING.md`、`DESIGN-IT-TWICE.md`、`prototype/LOGIC.md`、`prototype/UI.md`、`improve-.../HTML-REPORT.md`、`teach/*`、`issue-tracker-gitlab.md`、全部 `.changeset/*`（变更历史）、`deprecated/*`、`scripts/*`。这些不改变持久化触点结论。
- **无限流**：本次 curl 全部一次成功，未触发 raw CDN 限流重试。
