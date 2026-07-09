# flow-light 记忆层(P2 产物)

纯 markdown、手动维护、Codex 原生、零改动 mattpocock 核心。设计依据见 `../设计-记忆层.md`。

## 装到项目(一次性)
1. 装 mattpocock skill(到 `.agents/skills/`),跑 `/setup-matt-pocock-skills`(建它的 docs/agents 配置 + CONTEXT.md 约定)。
2. 把 `skills/flow-init/` 也放进 `.agents/skills/`,跑 `/flow-init`(建我们的记忆层 + 写 AGENTS.md 记忆层节)。
3. 旧项目:`/flow-init` 阶段 2 会读代码反推 `constraints.md` 草稿；`roadmap.md` 只有用户明确要求才生成草稿。用户确认前两者不具备约束力。

> 前期 setup 和 flow-init **两个都用**(先 setup 后 flow-init),各管各的文件、互不覆盖。用一阵再决定要不要合成一个。

## 文件布局(持续更新的记忆放 docs/,一次性配置留 docs/agents/)
```
项目根/
  AGENTS.md                    # Codex 每会话自读;含"## Project memory (flow-light)"节(读写规则+指针)
  CONTEXT.md                   # mattpocock:术语表(原位;你后续可挪进 docs/)
  docs/
    progress.md                # 复位状态(≤70行/5段/整体重写)← 跨会话不失忆
    constraints.md             # 项目约束(技术/架构/风格; 文件级 Status: draft/confirmed)
    frontend.md / backend.md   # (可选)大块约束按需拆
    roadmap.md                 # 项目蓝图(里程碑→阶段→plan; 文件级 Status: draft/confirmed)
    learnings.md               # 教训沉淀
    journal.md                 # 开发日志(追加式)
    adr/                       # mattpocock:架构决策(原位)
  docs/agents/                 # mattpocock setup 的一次性配置(issue-tracker/triage-labels/domain),不更新,故与我们的持续更新记忆分开
```

> **为何分开**:`docs/agents/` 是 setup 一次性生成、之后不动的静态配置;我们这几个是**持续更新**的项目记忆,放 `docs/` 更规整、人也找得到、git log 不被混淆。

## 为什么 Codex 上不用 hook 也能"记住"
`AGENTS.md` 是 Codex 每会话**自动加载**的(`model_instructions_file`)。里面的"读写规则"让 AI 自己在开工时读 `progress.md` 复位、动手前读 `constraints.md` 并检查其 `Status`。这就是 helloagents 在 Codex 上免 hook 读回的真相,我们照做——**无任何脚本/hook**。

## 三层记忆一句话
- **记忆(耐久)**:constraints / CONTEXT / ADR / roadmap —— 慢变,塑造"怎么做";constraints 和 roadmap 只有 `Status: confirmed` 才生效
- **状态(易变)**:progress —— 快变,答"我在哪、下一步",复位靠它
- **追溯(增长)**:learnings —— 追加,稳定的升级成 constraints

## 本目录内容(mattpocock 惯例:SKILL 只放 craft,FORMAT/样板拆成同目录 sibling)
```
skills/
  flow-init/            (user-invoked) 初始化 + 旧项目反推约束
    SKILL.md              craft:Explore→Present→Write→Infer→Confirm
    CONSTRAINTS-FORMAT.md constraints.md 的结构+规则
    ROADMAP-FORMAT.md     roadmap.md 的结构+规则
    AGENTS-memory-block.md 写进项目 AGENTS.md 的那一节
  flow-progress/        (model-invoked) 写好复位快照
    SKILL.md              craft:恢复测试
    PROGRESS-FORMAT.md    progress.md 的结构+规则
  flow-reflect/         (model-invoked) 记教训
    SKILL.md              craft + 一行式格式(内联,太短不拆)
  flow-journal/         (model-invoked) 记"这次会话干了啥"(追加式,能力非仪式)
    SKILL.md              craft:三条 trace 分工 + 判断驱动
    JOURNAL-FORMAT.md     journal.md 的结构+规则
```

三条 trace 线各管各的(抄 trellis 三 store):**journal**=时间线"发生了什么" · **progress**=快照"现在在哪" · **learnings**=蒸馏教训(升进 constraints)。

## craft 与 FORMAT 各自单一真源(无重复,无独立 templates 目录)
- **progress**:craft 在 flow-progress/SKILL,格式在 flow-progress/PROGRESS-FORMAT.md(flow-init 建它时指过来)。
- **constraints / roadmap**:无专属 maintainer skill,格式随 scaffolder flow-init(它建它们)。
- **learnings**:一行式,内联在 flow-reflect/SKILL(太短,无可 disclose)。
- **AGENTS 块**:flow-init 写的那节,作为它的 seed 随它。只放"每轮必须在场的反射",不重复 craft。
