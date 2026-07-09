# flow-light 记忆层(P2 产物)

纯 markdown、手动维护、Codex 原生、零改动 mattpocock 核心。设计依据见 `../设计-记忆层.md`。

## 装到项目(一次性)
1. 装 mattpocock skill(到 `.agents/skills/`),跑 `/setup-matt-pocock-skills`(建它的 docs/agents 配置 + CONTEXT.md 约定)。
2. 把 `skills/flow-init/` 也放进 `.agents/skills/`,跑 `/flow-init`(建我们的记忆层 + 写 AGENTS.md 记忆层节)。
3. 旧项目:`/flow-init` 阶段 2 会读代码反推 constraints/roadmap 初稿,过目确认。

> 前期 setup 和 flow-init **两个都用**(先 setup 后 flow-init),各管各的文件、互不覆盖。用一阵再决定要不要合成一个。

## 文件布局(全在 docs/agents/,规整)
```
项目根/
  AGENTS.md                    # Codex 每会话自读;含"## 项目记忆层"节(读写规则+指针)
  CONTEXT.md                   # mattpocock:术语表(原位)
  docs/adr/                    # mattpocock:架构决策(原位)
  docs/agents/
    PROGRESS.md                # 复位状态(≤70行/5段/整体重写)← 跨会话不失忆
    constraints.md             # 项目约束(技术/架构/风格)← 补 mattpocock 最大的缺
    frontend.md / backend.md   # (可选)大块约束按需拆
    ROADMAP.md                 # 项目蓝图(里程碑→阶段→plan)
    learnings.md               # 教训沉淀
    issue-tracker.md/…         # mattpocock setup 建的(共处一室)
```

## 为什么 Codex 上不用 hook 也能"记住"
`AGENTS.md` 是 Codex 每会话**自动加载**的(`model_instructions_file`)。里面的"读写规则"让 AI 自己在开工时读 `PROGRESS.md` 复位、动手前读 `constraints.md`。这就是 helloagents 在 Codex 上免 hook 读回的真相,我们照做——**无任何脚本/hook**。

## 三层记忆一句话
- **记忆(耐久)**:constraints / CONTEXT / ADR / ROADMAP —— 慢变,塑造"怎么做"
- **状态(易变)**:PROGRESS —— 快变,答"我在哪、下一步",复位靠它
- **追溯(增长)**:learnings —— 追加,稳定的升级成 constraints

## 本目录内容(mattpocock 惯例:SKILL 只放 craft,FORMAT/样板拆成同目录 sibling)
```
skills/
  flow-init/            (user-invoked) 初始化 + 旧项目反推约束
    SKILL.md              craft:Explore→Present→Write→Infer→Confirm
    CONSTRAINTS-FORMAT.md constraints.md 的结构+规则
    ROADMAP-FORMAT.md     ROADMAP.md 的结构+规则
    AGENTS-memory-block.md 写进项目 AGENTS.md 的那一节
  flow-progress/        (model-invoked) 写好复位快照
    SKILL.md              craft:恢复测试
    PROGRESS-FORMAT.md    PROGRESS.md 的结构+规则
  flow-reflect/         (model-invoked) 记教训
    SKILL.md              craft + 一行式格式(内联,太短不拆)
```

## craft 与 FORMAT 各自单一真源(无重复,无独立 templates 目录)
- **PROGRESS**:craft 在 flow-progress/SKILL,格式在 flow-progress/PROGRESS-FORMAT.md(flow-init 建它时指过来)。
- **constraints / ROADMAP**:无专属 maintainer skill,格式随 scaffolder flow-init(它建它们)。
- **learnings**:一行式,内联在 flow-reflect/SKILL(太短,无可 disclose)。
- **AGENTS 块**:flow-init 写的那节,作为它的 seed 随它。只放"每轮必须在场的反射",不重复 craft。
