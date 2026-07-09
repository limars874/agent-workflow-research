---
name: flow-init
description: 初始化 flow-light 项目记忆层。新项目建空文件,旧项目读代码反推填充约束/术语/roadmap。在项目开始时、或已跑过 mattpocock setup 后使用。
---

# 初始化项目记忆层

在 `docs/agents/` 建起 flow-light 记忆层,并把读写规则写进 `AGENTS.md`。**幂等**:已存在的文件增量更新,不覆盖用户手改。

前置:建议先跑过 mattpocock 的 `/setup-matt-pocock-skills`(它建 issue-tracker/triage-labels/domain 三个配置文件 + CONTEXT.md 约定)。本 skill 只**追加**我们的记忆层,不动它的东西。

## 阶段 1 · 建骨架(无条件)
1. 建 `docs/agents/` 下四个文件(用 flow-light 模板):`PROGRESS.md`(初始:主线目标="项目初始化",正在做="空闲")、`constraints.md`、`ROADMAP.md`、`learnings.md`。
2. 往项目根 `AGENTS.md` 写入 `## 项目记忆层(flow-light)` 一节(内容见 flow-light 的 `AGENTS-记忆层块.md`)。已有该节→刷新;有 AGENTS.md 无该节→追加;无 AGENTS.md→新建。**不要动 setup 维护的 `## Agent skills` 块。**
3. 确认 `docs/agents/PROGRESS.md` 不入 gitignore 以外的忽略(它要入库,换机器可复位)。

## 阶段 2 · 旧项目反推填充(仅当有实际代码)
读代码库,把 `constraints.md` / `CONTEXT.md`(若 mattpocock 未填)/ `ROADMAP.md` 填出初稿。**扫描按几个焦点分别过一遍(抄 gsd map-codebase),每条结论必须带一处 `反引号文件路径` 为证**:
- **技术选型**:读 `package.json`/`pyproject.toml`/lockfile/配置,列锁定的栈与库 → `constraints.md ## 技术选型`
- **架构**:看目录结构、模块边界、import 方向,推断分层与依赖规矩 → `constraints.md ## 架构约束`
- **风格**:从现有代码看命名/类型/错误处理惯例中"看不出但一致"的约定 → `constraints.md ## 风格规范`
- **领域术语**:反复出现的业务名词 → `CONTEXT.md`(若 setup 已建则补充,不重写)
- **roadmap**:从现有功能/TODO 反推里程碑初稿 → `ROADMAP.md`(拿不准就留框架待用户填)

安全:**只报密钥文件存在,绝不引用其内容**。约束拿不准的标"待确认",别硬编。

## 收尾
- 给用户看一遍填出的 `constraints.md` / `ROADMAP.md` 初稿,请他改/确认(这些是耐久记忆,值得人过目)。
- 更新 `PROGRESS.md`:主线目标恢复到用户真实任务或"空闲"。
