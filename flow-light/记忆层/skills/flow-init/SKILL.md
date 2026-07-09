---
name: flow-init
description: 初始化 flow-light 项目记忆层——建 docs/agents/ 文件并接好 AGENTS.md。跑一次,在 mattpocock 的 setup 之后。
disable-model-invocation: true
---

# 初始化记忆层

在 `docs/agents/` 立起项目记忆,并让 host 知道去读它。幂等:已存在的文件就地更新,保留人的手改。

在 `/setup-matt-pocock-skills` 之后跑:setup 的文件(issue-tracker/triage/domain + CONTEXT.md)归 setup,本 skill 只碰记忆层。

## 阶段 1 — 骨架(无条件)
1. 在 `docs/agents/` 建:`PROGRESS.md`(主线目标="初始化",正在做="空闲")、`constraints.md`、`ROADMAP.md`、`learnings.md`——用 flow-light 模板。
   - 收尾:四个文件都在。
2. 往项目根 `AGENTS.md` 加一节 `## 项目记忆层(flow-light)`(内容见 flow-light 的 `AGENTS-记忆层块.md`)。有该节→刷新;有 AGENTS.md→追加;无→新建。setup 的 `## Agent skills` 块保持原样。
   - 收尾:该节在 AGENTS.md 里,Codex 会加载它。
3. 让 `docs/agents/PROGRESS.md` 入 git(入库=换机器可复位)。

## 阶段 2 — 读代码反推(仅当仓库已有代码)
读代码库,把 `constraints.md`(以及 setup 未填的 `CONTEXT.md`/`ROADMAP.md`)填出初稿。分焦点几遍扫,**每条结论都带一处 `文件/路径` 为证**:
- **技术选型** — 读 package.json / pyproject / lockfile / 配置 → 锁定的栈与库 → constraints `## 技术选型`。
- **架构** — 目录结构、模块边界、import 方向 → 分层规矩 → constraints `## 架构约束`。
- **风格** — 代码里一致遵守、却从代码看不出的约定 → constraints `## 风格规范`。
- **术语** — 反复出现的业务名词 → CONTEXT.md(术语归 domain-modeling,规则才归 constraints,按此路由)。
- **roadmap** — 现有功能与 TODO → ROADMAP.md 里程碑,或留框架给用户填。
安全:只报告密钥文件存在,其值绝不读取。拿不准的标"待确认"。
   - 收尾:每条约束都带路径,或标了"待确认"。

## 收尾
把填出的 `constraints.md` 与 `ROADMAP.md` 给用户过目改正——耐久记忆值得人过一遍。再把 `PROGRESS.md` 设成用户的真实任务或"空闲"。
   - 收尾:用户看过初稿,PROGRESS 反映真实起点。
