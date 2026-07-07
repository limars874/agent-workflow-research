# GSD 框架研究：旧项目 init（map-codebase）与 ROADMAP.md 形态

> 目的：为 flow-light 的"项目记忆层"抄两块——① 旧项目扫码反推记忆（map-codebase）② 项目 ROADMAP 文件形态。只要纯 markdown 思路，剥掉 SDK/脚本。

## 0. 仓库确认（确认）

| 仓库 | 状态 | 默认分支 | 说明 |
|---|---|---|---|
| `gsd-build/get-shit-done` | **已归档** | `main` | 原作者(TÂCHES) |
| `open-gsd/gsd-core` | **活跃**（当天还在推） | **`next`** | 本报告主要读它 |

两仓 map-codebase / roadmap 的**提示词与模板逐字相同**，差别只在 SDK 调用外壳（archived 用 `gsd-sdk query`，fork 用 `gsd-tools.cjs` shim）。以下引用均来自 `gsd-core@next`。

## 1. `.planning/` 结构（确认，简述）

GSD 项目记忆全落在仓库根 `.planning/`：

| 文件 | 装什么 |
|---|---|
| `STATE.md` | **活记忆**。frontmatter 存进度数字(total/completed phases&plans、percent)，正文存当前位置、速度指标、累积决策/待办/阻塞。每次干完活更新。 |
| `ROADMAP.md` | **计划+进度**。里程碑→阶段→plan 层级 + 底部进度表（见 §3）。 |
| `REQUIREMENTS.md` | 可勾选需求清单(`[CAT]-NN`)，分 v1/v2/Out-of-Scope + 需求↔阶段追溯表。 |
| `PROJECT.md` | 愿景/核心价值/关键决策(roadmap 引用它)。 |
| `codebase/*.md` | **旧项目扫码产物**(7 份，见 §2)。 |
| `phases/XX-name/` | 阶段级 `CONTEXT.md`(实现决策)、`{p}-{plan}-PLAN.md`、`{p}-{plan}-SUMMARY.md`(完成小结，带 coverage 元数据)。 |
| `onboarding/SUMMARY.md` | 旧项目 onboarding 收尾报告(尾产物)。 |

> 注：`CONTEXT.md` 在 gsd-core 是**阶段级**文件，非项目根。

## 2. 旧项目 init / map-codebase（核心）★

### 2.1 入口与整体流程（确认）

旧项目（brownfield）用 **`/gsd:onboard`** 一条命令引导，它是个**路由器**，按仓库状态决定先跑哪个原子命令（依赖图，非喜好）：

```
brownfield 有代码但 .planning/codebase/ 不全  → 先跑 /gsd:map-codebase   ← 扫码反推
有 ADR/PRD/SPEC/RFC 文档且还没 PROJECT.md      → /gsd:ingest-docs
否则                                           → /gsd:new-project        ← 生成 ROADMAP 等
```
（来源：`workflows/onboard.md`、`docs/adr/1990-existing-code-onboarding.md`）

**关键点：扫码(map-codebase)必须先于建计划(new-project)** —— 先有代码地图，规划才有上下文。

### 2.2 map-codebase 具体怎么扫（核心，可直接抄）

`/gsd:map-codebase`（`commands/gsd/map-codebase.md` + `workflows/map-codebase.md` + `agents/gsd-codebase-mapper.md`）逻辑：

1. **检查** `.planning/codebase/` 是否已存在 → 存在则问 Refresh/Update/Skip。
2. **建目录** `mkdir -p .planning/codebase`。
3. **并行 spawn 4 个 `gsd-codebase-mapper` 子代理**（每个 fresh context，互不污染），各管一个 focus，**直接写文件**，只回传确认+行数（省 orchestrator 上下文）：

   | focus | 扫什么 | 产出文件 |
   |---|---|---|
   | **tech** | 包清单(package.json/Cargo.toml…)、配置、SDK/API import | `STACK.md` `INTEGRATIONS.md` |
   | **arch** | 目录树、入口文件、import 关系推断分层 | `ARCHITECTURE.md` `STRUCTURE.md` |
   | **quality** | lint/format 配置、测试文件、抽样源码看约定 | `CONVENTIONS.md` `TESTING.md` |
   | **concerns** | grep TODO/FIXME/HACK、大文件(wc -l 排序)、空实现桩 | `CONCERNS.md` |

4. **orchestrator 收确认** → 校验 7 份都在 → commit → 提示下一步。

**mapper 子代理的实际扫描提示词逻辑**（抄自 `gsd-codebase-mapper.md`，这是精华）：

- **tech**：`ls package.json requirements.txt Cargo.toml go.mod pyproject.toml`；`cat package.json | head`；`ls *.config.* tsconfig.json`；`ls .env*`（**只记存在，绝不读内容**）；`grep -r "import.*stripe\|supabase\|aws\|@" src/` 抓外部依赖。
- **arch**：`find . -type d -not -path '*/node_modules/*'`；`ls src/index.* main.* app.* server.*` 找入口；`grep -r "^import" src/` 理解分层。
- **quality**：`ls .eslintrc* .prettierrc* biome.json`；`find . -name "*.test.*"`；抽样 `src/**/*.ts` 看命名/风格。
- **concerns**：`grep -rn "TODO\|FIXME\|HACK\|XXX" src/`；`find src -name "*.ts" | xargs wc -l | sort -rn | head` 找复杂大文件；`grep "return null\|return \[\]\|return {}"` 找桩。

**反推出什么、写进哪**：每份文档是**填模板**（模板在 mapper agent 里内联，见 §2.3），核心铁律：
- **必带文件路径**（`` `src/services/user.ts` `` 反引号），因为下游 plan/execute 要直接跳转。
- **写"现状"不写"曾经"**，**开处方式**（"用 X 模式" 而非 "用了 X 模式"）。
- **安全**：`.env`/`*.key`/`credentials.*` 等只报存在、绝不引用内容（产物会进 git）。
- 找不到就写 "Not detected"。

**增量重扫（可选，值得借鉴）**：`--paths a,b` 只扫指定子树；写入时把 `last_mapped_commit: <HEAD sha>` 盖进 frontmatter，用于"代码漂移"检测（execute 后自动触发重扫变更目录）。

### 2.3 7 份文档地图 + 下游怎么用（确认）

产物 = `.planning/codebase/` 下 7 份大写 md。下游按阶段类型**只加载 2–3 份**（`references/scout-codebase.md` 有阶段类型→文档映射表，避免灌爆上下文），内容骨架：

- `STACK.md`：语言/运行时/框架/关键依赖/配置/平台要求
- `INTEGRATIONS.md`：外部 API、DB、存储、Auth、监控、CI/CD、webhook、必需 env 变量
- `ARCHITECTURE.md`：ASCII 分层图、组件职责表、模式、数据流(带 file:line)、抽象、入口、**反模式**、错误处理
- `STRUCTURE.md`：目录树+用途、关键文件位置、命名约定、**"新代码放哪"**
- `CONVENTIONS.md`：命名/风格/import 组织/错误处理/日志/注释/函数与模块设计
- `TESTING.md`：测试框架/运行命令/组织/结构样例/mock/fixture/覆盖率
- `CONCERNS.md`：技术债/已知 bug/安全/性能瓶颈/脆弱区/扩展上限/风险依赖/覆盖缺口(**可能变成未来阶段**)

> 借鉴要点：**4-focus 并行 + 直接写文件 + 填模板 + 必带路径 + 只读不引用密钥 + 下游按需加载**。纯 markdown+子代理思路，不依赖 SDK。

## 3. ROADMAP.md 形态（核心）★

来源：`templates/roadmap.md`（模板），由 **`gsd-roadmapper`** 子代理生成（`/gsd:new-project` spawn，从 REQUIREMENTS 反推阶段）。**计划与进度写在同一个文件**。

### 3.1 层级：里程碑 Milestone → 阶段 Phase → Plan（三层）

- **Phase 编号**：整数(1,2,3)=计划里程碑工作；小数(2.1)=紧急插入（标 `INSERTED`），按数字序插在整数之间。
- **Plan 命名**：`{phase}-{plan}`（如 `01-02`），对应 `01-02-PLAN.md`。>3 任务或多子系统就拆成多 plan。
- **无时间估算**（"这不是企业 PM"）。

### 3.2 真实结构（抄自模板，greenfield v1.0）

```markdown
# Roadmap: [Project Name]

## Overview
[一段话：从起点到终点的旅程]

## Phases
- [ ] **Phase 1: [Name]** - [一句话]
- [ ] **Phase 2: [Name]** - [一句话]

## Phase Details
### Phase 1: [Name]
**Goal**: [本阶段交付什么]
**Depends on**: Nothing (first phase)
**Requirements**: [REQ-01, REQ-02]        <!-- 关联需求 -->
**Success Criteria** (what must be TRUE):  <!-- 2–5 条可观察行为，用户视角 -->
  1. [User can ...]
  2. [... works/exists]
**Plans**: [N plans 或 TBD]

Plans:
- [ ] 01-01: [首个 plan 简述]
- [ ] 01-02: [第二个 plan 简述]

### Phase 2.1: Critical Fix (INSERTED)   <!-- 小数=紧急插入 -->
**Goal**: [插在阶段之间的紧急活]
**Depends on**: Phase 2
...

## Progress
**Execution Order:** 2 → 2.1 → 2.2 → 3 → 3.1 → 4   <!-- 数字序 -->

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. [Name] | 0/3 | Not started | - |
| 2. [Name] | 0/2 | Not started | - |
```

**进度组织方式**：
- **两处勾选**：Plans 列表用 `- [ ]`/`- [x]`；底部 **Progress 表**记 `Plans Complete`(n/m) + `Status` + 完成日期。表由 execute workflow 自动更新。
- **Status 取值**：`Not started` / `In progress` / `Complete`(带日期) / `Deferred`(带原因)。

### 3.3 里程碑分组（v1.0 ship 之后重组）

首个里程碑完成后，ROADMAP **重组为里程碑分组**：顶部 `## Milestones` 用 emoji（✅ shipped / 🚧 进行中 / 📋 计划），**已完成里程碑折叠进 `<details>`**（保持可读），当前/未来里程碑展开。**阶段编号连续永不重置**（01–99）。Progress 表加一列 `Milestone`。

```markdown
## Milestones
- ✅ **v1.0 MVP** - Phases 1-4 (shipped YYYY-MM-DD)
- 🚧 **v1.1 [Name]** - Phases 5-6 (in progress)
- 📋 **v2.0 [Name]** - Phases 7-10 (planned)

## Phases
<details><summary>✅ v1.0 MVP (Phases 1-4) - SHIPPED</summary>
### Phase 1 ... (Plans 全 [x])
</details>

### 🚧 v1.1 [Name] (In Progress)
#### Phase 5: [Name] ...
```

> 无 wave 概念（GSD 只有 milestone/phase/plan 三层）；但 tests 里出现 `roadmap-wave-deps` 字样，推断"wave=同里程碑内可并行阶段的依赖分组"，**未在模板确认**。

## 4. 靠 SDK/脚本的部分（要剥掉，标出）★

| 机制 | 依赖 | flow-light 对策 |
|---|---|---|
| `INIT=$(gsd_run query init.map-codebase)` 取 mapper_model/date/has_maps 等 | **gsd-tools.cjs / gsd-sdk**（Node CLI） | 剥掉。用固定约定：模型自选、date 用系统日期、has_maps 直接 `ls .planning/codebase/` |
| `workflows/map-codebase.md` 里那段超长 `GSD_TOOLS` shim 定位符 | Node 运行时 | 整段删 |
| `/gsd:onboard` 的路由决策（brownfield 检测/gate 排序/幂等） | `onboard-projection.cjs`（纯投影模块，单测覆盖） | 剥掉投影；用 markdown 里的 if 描述 §2.1 那张路由表即可（弱一点但够用） |
| `--query`（codebase intelligence：query/status/diff/refresh，需 `intel.enabled`） | SDK intel 索引 | 直接不要，flow-light 不需要 |
| 代码漂移门 `last_mapped_commit` + `bin/lib/drift.cjs:writeMappedCommit` | Node 脚本 | 想要可保留"记 commit sha 到 frontmatter"这个**思路**，手动重扫即可 |
| STATE.md frontmatter 的 `syncStateFrontmatter`、进度表自动回填 | SDK | 剥掉；改成代理手动改 markdown |
| `Agent` 工具 spawn 并行 mapper | 需 runtime 支持子代理 | 有子代理就并行；没有则 workflow 里明确 fallback 到 `sequential_mapping`（GSD 自带这个降级步骤，可抄） |

**纯 markdown 可直接抄的**：mapper 4-focus 的**扫描命令清单**、7 份文档**模板**、ROADMAP **模板与层级**、scout-codebase **按阶段选文档表**、mapper 的**安全铁律/必带路径铁律**、onboard 的**路由依赖表**。

## 5. 诚实标注

- **确认（读到实际文件逐字核对）**：§0 仓库状态；§1 各文件用途（读了 state/context/requirements/summary 模板 + STATE frontmatter）；§2 map-codebase 全流程、4-focus 扫描命令、7 文档模板、安全铁律（读了 command+workflow+mapper agent 三份）；§3 ROADMAP 两种形态与进度表（读了 roadmap.md 模板全文 + roadmapper agent 头部）；§4 SDK 依赖点（读了 workflow 里的 shim 与 ADR-1990）。
- **推断（未逐字确认）**：§3.3 "wave" 的确切含义（仅从测试文件名 `enh-2447-roadmap-wave-deps` 推断，模板无 wave）；STATE.md 进度表由 execute 自动更新的**具体机制**（模板注释说"由 execute workflow 更新"，未读 execute 源码）。
- **没拉到 / 未深读**：`new-project.md`/`ingest-docs` 完整工作流（只确认了它们是 ROADMAP/文档的生成入口，未逐行读）；`bin/lib/*.cjs` 全部 SDK 实现（按任务要求刻意跳过，只需 markdown 思路）；roadmapper agent 90 行之后的覆盖率校验细节。
