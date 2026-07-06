# mattpocock/skills

## 基本信息

| 项 | 内容 |
|---|---|
| 地址 | https://github.com/mattpocock/skills |
| 作者 | Matt Pocock（Total TypeScript / AI Hero 作者，TS 教育领域头部 KOL） |
| Stars | ~157k（GitHub API 2026-07-05：stars 157,261 / forks 13,519），2026-06 报道为 135k+，增速极快，属现象级项目 |
| 创建时间 | 2026-02-03，持续高频活跃（pushed 2026-07-05，.changeset/ 有 18 条待发布变更） |
| 目标 host | 名义上"works with any model/agent"（`npx skills@latest add mattpocock/skills` 安装，另有社区 MCP server 暴露 38 skills），但实质以 Claude Code 为一等公民：`.claude-plugin/plugin.json`、hooks 安装写 `.claude/`、招牌护栏 skill 直接叫 `git-guardrails-claude-code` |
| 描述 | "Skills for Real Engineers. Straight from my .claude directory." |

## 定位与设计哲学

**一句话定位**：一位资深工程师的**个人 .claude 目录直出**——一组小而可组合的"工程判断力" skill（提问、建模、TDD、调试、评审），刻意**反框架**：不接管流程、不建状态机，把控制权留给人。

**它认为 agent 编码的四大失败模式**（README 明文）：
1. **Misalignment**（错位）—— agent 误解需求 → 解法是 grilling（拷问式对齐）；
2. **Verbosity**（啰嗦/词汇混乱）—— 缺项目语境与领域语言 → 解法是 CONTEXT.md 共享词汇表；
3. **Non-functional code**（跑不起来）—— 无反馈回路 → 解法是 TDD、静态类型、结构化调试；
4. **Architectural decay**（架构腐化）—— AI 加速复杂度增长 → 解法是贯穿始终的有意设计（domain-modeling / codebase-design / ADR）。

**明确的反面立场**：作者公开表示 GSD、BMAD、Spec-Kit 这类框架"通过接管流程来帮你，但夺走了你的控制权，且流程里的 bug 难以修复"。因此本仓库哲学是 **"Small, easy to adapt, and composable"**——每个 skill 独立可用，不强制串成流水线。

## 核心机制

### 文件结构
```
skills/
  engineering/     # 16 个核心工程 skill（tdd/code-review/diagnosing-bugs/
                   #   domain-modeling/grill-with-docs/to-prd/to-issues/triage/
                   #   implement/prototype/research/codebase-design/ask-matt/...）
  productivity/    # grilling/grill-me/handoff/teach/writing-great-skills
  misc/ personal/ in-progress/ deprecated/   # 非公开推广桶（wayfinder/loop-me 等在孵化）
docs/engineering|productivity/  # 每个推广 skill 一页人类文档（同步发布到 aihero.dev）
.changeset/ CHANGELOG.md .github/workflows/release.yml  # 用 changesets 像 npm 包一样做版本发布
CONTEXT.md  CLAUDE.md  .agents/  .out-of-scope/   # 仓库自身吃自己狗粮
scripts/link-skills.sh  # symlink 同步到本地 harness
```

### 两类调用模型（本仓库的核心工程化贡献之一）
- **User-invoked**（`disable-model-invocation: true`）：用户显式敲的编排入口（/grill-me、/triage、/to-prd、/implement），零上下文税；
- **Model-invoked**：agent 可自主触发的可复用纪律（grilling、tdd、diagnosing-bugs、code-review、domain-modeling）。
- writing-great-skills 把这套取舍讲成方法论："predictability is the root virtue"、description 前置触发词、信息按"步骤→内嵌参考→外部参考"三级阶梯做 progressive disclosure、"仅当获得调用独立性或防过早完成时才拆分 skill"。

### 松散的隐含流程（可各自单用）
grilling/grill-me（拷问对齐）→ to-prd（PRD + `ready-for-agent` 标签）→ to-issues（垂直切片发 issue）→ implement（薄模板：TDD at seams + 常跑 typecheck + 末尾全量测试）→ code-review（双轴并行 subagent）→ commit。triage 用五态标签状态机（needs-triage → needs-info/ready-for-agent/ready-for-human/wontfix）把 issue tracker 变成任务状态源；setup skill 把 tracker/标签/文档布局三项配置落盘到 `docs/agents/*.md` 并写入 CLAUDE.md/AGENTS.md。

### 招牌深度技艺（"偏科"的那一科）
- **grilling**：一次一问 + **每问附推荐答案** + 依赖树顺序推进 + "能查代码库回答的绝不问用户" + 双方确认共识前 hold implementation。
- **tdd**：核心概念是 **seam**（"测试所在的公共边界"），只在**预先与人约定的 seam** 写测试；反三种反模式——实现耦合测试、**同义反复测试**（期望值不得用与实现相同的方式重算）、横向切片（先写全部测试=对真实变化不敏感）；refactor 移出红绿循环、归入 code review。
- **diagnosing-bugs**："tight feedback loop 是唯一关键技能"，十级递进构造回路（失败测试→fuzzing→differential testing）；铁律"在回路命令存在前读代码建理论 = 停"；非确定性 bug 目标是复现率提到 50%+。
- **domain-modeling**：设计过程中主动挑战模糊词（"account 是 Customer 还是 User？"）、场景压力测试、代码与口述矛盾即时揭发、术语实时回写 CONTEXT.md（"它是词汇表，仅此而已"）；ADR 三条件高门槛（难逆转 ∧ 无语境会惊讶 ∧ 真权衡）缺一不写。
- **code-review**：双轴（Standards / Spec）**并行 fresh subagent** 防上下文污染；先 pin fixed point（`git diff <fp>...HEAD` 非空校验）；Standards 轴带 Fowler 式代码异味基线且"repo 规范覆盖基线"；两报告分列不合并不重排。

### 机器强制成分（很少）
- `git-guardrails-claude-code`：PreToolUse hook shell 脚本拦截 force push / reset --hard / clean / 删分支等，exit code 2 + BLOCKED——全仓唯一真正的机器强制，且是**可选安装**的独立 skill。
- diagnosing-bugs 附 `hitl-loop.template.sh` 模板；此外无状态脚本、无 Stop hook、无 CLI 独占写权。
- 状态托管给 issue tracker 原生机制（labels、assign、blocking 关系）——"借力外部系统"而非自建 FSM。

## 步骤流覆盖

| 步骤 | 有无 | 怎么做 |
|---|---|---|
| 澄清意图 | ✅ 极强（招牌科目） | grilling 一次一问+推荐答案+Evidence 优先查代码+实现前共识确认；grill-with-docs 结合文档；domain-modeling 实时消歧术语。但门禁纯 prompt |
| 写清规格 | ✅ 中强 | to-prd：探码→testing seams 极小化并与用户确认→结构化 PRD（user stories/实现决策/测试决策/scope）→打 ready-for-agent 标签；无需求编号/覆盖矩阵 |
| 小步切片 | ✅ 中 | to-issues：垂直切片（tracer bullet）、每片独立可 demo、依赖顺序发 issue、granularity 反问用户；无 DAG/粒度机校验 |
| 实现功能 | ⚠️ 弱 | implement 只是薄清单（TDD at seams、常跑 typecheck、末尾全量测试、然后 /code-review + commit）；无偏差协议、无 subagent 隔离执行 |
| 验证证据 | ✅ 方法论强、强制为零 | tdd 的 seam/反 tautological/红绿循环 + diagnosing-bugs 的 feedback-loop-first 是全生态最深的**验证方法论**之一；但无证据落盘门禁、无"跑命令读输出才许宣称"式 gate |
| 独立审查 | ✅ 中强 | code-review 双轴并行 fresh subagent + smell 基线 + spec 对照 + scope creep 检查；无阻断门禁、结果不落盘、单模型 |
| 可控发布 | ❌ 无 | 止于 commit 到当前分支；triage 处理 PR 但属入口管理非发布 |
| 复盘沉淀 | ⚠️ 部分 | CONTEXT.md 术语实时回写 + ADR + `.out-of-scope/` 记录拒绝先例（triage 前置查询它）+ 仓库自身用 changesets 沉淀 skill 演化；但回写靠模型自觉、无 hook 自动注入，"双环"不完整 |

## 横切能力覆盖

| 能力 | 评价 |
|---|---|
| 任务状态 | ⚠️ 外包给 issue tracker：五态标签状态机 + assign=claim（wayfinder）；跨 session 可恢复但无本地状态文件/校验 |
| 上下文治理 | ⚠️ 有意识但轻：CONTEXT.md 单一词汇表、code-review 并行 subagent 防污染、writing-great-skills 的 progressive disclosure、handoff 压缩交接；无 hook 注入、无上下文预算 |
| 记录与追溯 | ⚠️ ADR + issue/PR 评论留痕 + 强制 AI 署名（"This was generated by AI during triage"）；无结构化 journal |
| 安全护栏 | ⚠️ 有一个真 L3 组件（PreToolUse 拦截危险 git），但可选安装、仅覆盖 git、仅 Claude Code |
| 完成权剥夺 | ❌ 纯 prompt（grilling 的 hold、implement 的"末尾跑全量"），无 Stop hook/回执/sentinel |
| 跨 host | ⚠️ SKILL.md 标准格式 + npx skills 安装器理论上多 host；实际 hooks/plugin/设置全是 Claude Code 语义，无适配层与移植规范 |
| 机器下沉 | ❌ 接近零：全仓 3 个 shell 脚本，其一还是仓库维护用；FSM（triage 五态）写在 markdown 靠自律 |
| 无人值守/并行 | ⚠️ 孵化中：wayfinder（in-progress）用 tracker 原生 assign 做认领锁、"一 ticket 一 session"、Fog 区管未知；loop-me 亦在孵化；均未正式推广 |

## 独特亮点

1. **偏科偏在 S1+人机对齐，且做到生态最深**：grilling 的"一次一问+推荐答案+依赖树推进+能查代码绝不问人"，加上 domain-modeling 的实时术语消歧与代码-口述矛盾揭发，是所有仓库里最精细的"对齐工艺"。它赌的是：错位是四大失败模式之首，对齐做好了后面全省。
2. **验证的"方法论深度"而非"机制强度"**：tdd 的 seam 概念、反 tautological 测试、反横向切片，diagnosing-bugs 的"feedback loop 优先于一切、读代码建理论前先停"——这些是教科书级的工程判断编码，多数框架只有"必须跑测试"的口号，没有"什么样的测试才算数"的鉴别力。
3. **skill 工程本身被产品化**：writing-great-skills 给出 user-invoked vs model-invoked 的上下文税/认知税权衡、描述触发词工艺、信息阶梯、拆分判据；仓库用 changesets+CHANGELOG 像 npm 包一样管理 skill 版本，`.changeset/` 里 18 条待发布变更证明高频迭代；六桶晋升制（in-progress→engineering/productivity→deprecated）+ `.out-of-scope/` 记录"为什么不做"。这是**把 skill 当软件维护**的范本。
4. **反框架立场的清醒**：不建自有状态机，状态外包给 issue tracker 原生机制（labels/assign/blocking）——规避了 missions/maestro 式"markdown FSM 靠自律"的陷阱，代价是能力上限受 tracker 制约。

## 明显欠缺

- **几乎没有机器强制**：除可选的 git 护栏 hook 外，全部纪律靠 prompt 自律；没有完成权剥夺、没有证据落盘门禁、没有状态校验脚本。弱模型或长会话下执行走样无兜底。
- **执行与编排是薄弱环节**：implement 极薄，无偏差协议、无 re-grounding、无 subagent 驱动执行；无人值守与并行（wayfinder/loop-me）还在孵化桶。
- **发布环节缺失**：止于 commit，无 PR 门禁、部署、回滚。
- **跨 host 名不副实**：宣称通用，实际 hook/插件/配置全绑 Claude Code，无移植规范。
- **复盘无闭环**：CONTEXT.md/ADR/.out-of-scope 有回写，但注入靠模型主动读取，非 hook 强制。
- **star 数需打折看待**：157k star 很大程度是作者 KOL 影响力与"窥看名人 .claude 目录"效应；搜索到的报道多为描述性正面（explainx.ai、aitoolly 等），缺少严肃批评性评测。

## 臃肿度与耦合度评价

- **臃肿度：轻**。全生态最轻量级之一：纯 markdown + 3 个 shell 脚本，无守护进程、无强制注入、无仪式化流水线；单 skill 可独立取用，不用的部分零成本。
- **耦合度：低（skill 间）/ 中（对外部系统）**。skill 之间仅显式名字引用（implement→tdd→code-review），可自由拆用；但任务状态深依赖 issue tracker（gh/glab CLI），护栏深依赖 Claude Code hook。
- **接入成本：低**。`npx skills@latest add mattpocock/skills` + `/setup-matt-pocock-skills` 三问配置即用；护栏需额外手动安装。
- **学习成本：低-中**。单 skill 即读即用；但因为不接管流程，**产出质量高度依赖用户自己会编排**——它是给"real engineers"的工具箱，不是给新手的自动驾驶。

## 关键证据

- GitHub API：stars 157,261 / forks 13,519、created 2026-02-03、pushed 2026-07-05；描述 "Skills for Real Engineers. Straight from my .claude directory."
- README.md：四大失败模式（Misalignment/Verbosity/Non-functional/Architectural decay）与对应解法；"Small, easy to adapt, and composable"；user-invoked vs model-invoked 双清单。
- 作者立场（explainx.ai 报道）：GSD/BMAD/Spec-Kit "own the process… take away your control and make bugs in the process hard to resolve"。
- `skills/productivity/grilling/SKILL.md`：一次一问、每问附推荐答案、依赖树推进、能查代码绝不问用户、共识确认前 hold implementation。
- `skills/engineering/tdd/SKILL.md`（+tests.md/mocking.md）："A seam is the public boundary you test at"、测试只写在预先约定的 seam、反 tautological（期望值须独立来源）、反横向切片、refactor 归入 code review。
- `skills/engineering/diagnosing-bugs/SKILL.md`："If you catch yourself reading code to build a theory before this command exists, stop."、十级反馈回路、非确定 bug 目标复现率 50%+、`scripts/hitl-loop.template.sh`。
- `skills/engineering/code-review/SKILL.md`：双轴（Standards/Spec）并行 general-purpose subagent、pin fixed point 非空 diff 校验、Fowler 异味基线且 repo 规范覆盖之、两报告不合并。
- `skills/engineering/domain-modeling/SKILL.md`：CONTEXT.md "is a glossary and nothing else"、术语即时回写、ADR 三条件缺一不写。
- `skills/engineering/triage/SKILL.md` + setup skill：五态标签状态机、`.out-of-scope/` 先例查询、"This was generated by AI during triage" 强制署名、配置落盘 `docs/agents/*.md`。
- `skills/misc/git-guardrails-claude-code/`：PreToolUse hook + block-dangerous-git.sh，exit 2 BLOCKED，可选安装、可自定义拦截清单。
- `skills/in-progress/wayfinder/SKILL.md`：map issue（destination/决策索引/Fog 区）、`wayfinder:<type>` 子票、claim=assign、tracker 原生 blocking、一 ticket 一 session。
- CLAUDE.md：六桶晋升制、推广 skill 须进 README+plugin.json+docs 页+aihero.dev；`.changeset/`（18 条）+ `.github/workflows/release.yml`：changesets 式版本管理。
- `skills/productivity/writing-great-skills/SKILL.md`："predictability is the root virtue"、model-invoked 的上下文税 vs user-invoked 的认知税、信息三级阶梯、拆分双判据。

## 16 维评分建议

> 口径：L0 缺失 / L1 prompt 自律 / L2 状态落盘 / L3 机器强制；判级看最弱链。

| 维度 | 评级 | 一句证据 |
|---|---|---|
| S1 澄清意图 | **L1+** | grilling 工艺全生态最深（一次一问+推荐答案+查码优先），但"共识前 hold implementation"纯 prompt，批准信号不落盘无门禁 |
| S2 写清规格 | **L2-** | to-prd 结构化 PRD 落盘 tracker + ready-for-agent 标签 + CONTEXT.md 词汇表，但无需求编号/覆盖矩阵/格式校验 |
| S3 小步切片 | **L2-** | to-issues 垂直切片按依赖序发 issue（tracker 落盘），粒度靠 quiz 用户，无 DAG/阈值机校验 |
| S4 实现功能 | **L1** | implement 仅薄清单（TDD at seams+常跑 typecheck），无偏差协议、无执行隔离 |
| S5 验证证据 | **L1+** | tdd/diagnosing-bugs 方法论极深（seam、反 tautological、feedback-loop-first），但零证据落盘门禁，宣称完成无 gate |
| S6 独立审查 | **L1+** | 双轴并行 fresh subagent + 异味基线 + spec 对照实现了"独立"，但发现不落盘、无阻断门禁、单模型 |
| S7 可控发布 | **L0** | 止于 commit 到当前分支，无 PR 门禁/部署/回滚 |
| S8 复盘沉淀 | **L1+** | CONTEXT.md/ADR/.out-of-scope 有回写且被后续 skill 前置查询，但注入靠模型自觉读取，非 hook 强制（双环不全） |
| C1 任务状态 | **L2** | 状态外包 issue tracker：五态标签状态机 + assign 认领，跨 session 可恢复；无本地校验/修复 |
| C2 上下文治理 | **L1+** | CONTEXT.md 单一词汇源 + review 并行 subagent 防污染 + progressive disclosure 方法论；无 hook 注入、无预算 |
| C3 记录与追溯 | **L2-** | ADR 三条件 + tracker 评论留痕 + AI 强制署名；无结构化 journal，写入全靠 LLM |
| C4 安全护栏 | **L2+** | 唯一真 L3 组件（PreToolUse 拦截危险 git，exit 2），但可选安装、仅 git、仅 Claude Code——覆盖面即最弱链 |
| C5 完成权剥夺 | **L1** | 仅 prompt 级 hold/末尾全量测试；无 Stop hook、无回执、无 CLI 独占写 |
| C6 跨host可移植 | **L1+** | 标准 SKILL.md + npx skills 安装器理论多 host；实际 hook/plugin/配置全绑 Claude Code，无适配层与移植规范 |
| C7 机器下沉 | **L1** | 全仓 3 个 shell 脚本；triage 五态 FSM 写在 markdown 靠自律 |
| C8 无人值守/并行 | **L1?** | wayfinder（tracker 原生 claim 锁+一票一 session）与 loop-me 均在 in-progress 孵化桶，未正式发布（证据不足） |
