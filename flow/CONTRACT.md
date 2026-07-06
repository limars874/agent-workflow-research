# CONTRACT — flow 的脊柱(artifact 契约)

> 这是防散架的地基。**所有能力件(prompt)和强制件(script)只通过下面这组文件对话。**
> 每个 skill/脚本顶部都应引用本文件,并声明自己的 `(读, 写)`。

## 铁律

1. **不许自建私有状态。** 要读写状态,只能走下表的 artifact。
2. **新增件先声明 `(读, 写)`。** 对不上本表 = 要散架的信号,先扩表(慎重),不开私有旁路。
3. **完成态只准脚本写。** `state.json` 里 slice 的 `done` 只能由 `verify.sh` 按退出码翻,LLM 永不自写(完成权剥夺,Phase 2 落地)。

## Artifact 表

| artifact | 路径 | 写者 | 读者 | 格式要点 |
|---|---|---|---|---|
| 规格 | `spec.md`(仓库根) | spec(S2) | verify.sh、implement、review、retro | 见 §spec.md 格式;**窄腰** |
| 批准信号 | `.flow/approved` | grill(S1)经 `./flow approve` | implement 前置 | 追加:`<ISO时间> approved: <一句话决议>` |
| 切片 | `.flow/tasks.md` | slice(S3) | implement、run-loop | 每片:`- [ ] T<n>` + `files:` + `verify:` + 可选 `depends:` |
| 状态 | `.flow/state` | **脚本**(`state.sh`/`verify.sh`) | recover、status、人 | 见 §state;行式、**无时间戳**;`done` 只准 verify.sh 写 |
| 记账 | `.flow/summary.md` | implement(S4) | review、retro | 追加:每片 做了/偏差(Rule 几)/遗留 stub |
| 审查 | `.flow/reviews/<sha>.md` | review.sh(S6) | 人、retro | 跨模型二审结论 |
| 沉淀-流水账 | `.flow/learnings.md` | retro(S8)经 `./flow learn` | retro 自己筛 | 本地噪音日志,**不入库** |
| 沉淀-生效层 | `AGENTS.md`(仓库根) | retro 毕业稳定项 | **每个 host 启动自动加载** | 入库;不靠 hook 的自动注入 |

`.flow/` 是运行态,已在 `.gitignore`(不入库),故 `learnings.md`/`approved`/`state`/`evidence` 都是**本地**的。
`spec.md`、`AGENTS.md` **入库**。双层沉淀:噪音留本地 learnings.md,稳定项毕业进入库的 AGENTS.md 才生效。

## spec.md 格式(窄腰,Phase 1 定稿)

```markdown
# <任务名>

## Requirements(可追溯,编号不复用)
- R1: <一句话需求>
- R2: ...

## Seams(测试边界,实现前与人约定)
- <公开边界:CLI/API/UI 级,不测内部实现>

## Acceptance(每条一个可跑命令)
- AC1 (R1) <人话>
  verify: <绿=通过的命令;必须走真实端到端路径,禁 import 内部模块绕过>
- AC2 (R2) <人话>
  verify: <命令>

## Out of scope(防手痒多写)
- <明确不做的>
```

**约定**:`verify:` 行是硬契约,`verify.sh` 抽取并逐条执行。AC 后括号里的 `(R#)` 使"需求→验收"可追溯(抄 spec-kit 编号),供 review/retro 做反向查漏(抄 spec-kit converge)。

## state 格式(`.flow/state`,行式)

```
task: <任务名,对应 spec.md 标题>
step: grill|spec|slice|implement|verify|review|retro|done
updated_by: <最后写它的件名>
slice T1: pending|running|done|blocked
slice T2: ...
```

- **为何行式而非 JSON**:纯 bash 用 grep/sed 就能读写,零依赖(不引 jq/python),更合"轻+可魔改"。这是 Phase 2 的一次**明面契约演进**(state.json → .flow/state),不是私有旁路。
- **刻意无时间戳**(抄 web-dev-skills):状态可由 status 枚举 + tasks 依赖无状态重建,避免时间戳漂移。
- **完成权铁律**:`step: done` 与 `slice X: done` **只准 `verify.sh` 在退出码为 0 时写**。`state.sh` 负责其余状态,且**拒绝**写任何 done。其他任何件、LLM 直接写 done 都视为违约。

## 咬合自检(任何改动后问自己)

- [ ] 我这个件读写的东西,都在上表里吗?
- [ ] 我有没有偷偷发明一个表外的状态文件/字段?
- [ ] 我写 `state.json` 的 `done` 了吗?(除了 verify.sh,谁都不许)
