# flow 实现 Roadmap(脊柱优先,防散架)

> 目标:吸取各家优点**合成**一个更好的,而不是抄一个或拼一堆。
> 防散架的机制:**先立一根脊柱(artifact 契约),每一格合成都对着它做,阶段间设咬合检查点。**
> 可随时停:每个 Phase 结束都是"系统仍然合得上"的完整停靠点。

---

## Phase 0 — 立脊柱:artifact 契约(必须最先,是防散架的地基)

**唯一真相源 = 一组约定文件。所有能力件(prompt)和强制件(script)只通过这些文件对话。**

| artifact | 谁写 | 谁读 | 作用 |
|---|---|---|---|
| `spec.md`(仓库根) | spec(S2) | verify.sh、implement、review、retro | 规格唯一真相源;**窄腰**,一切咬合在此 |
| `.flow/approved` | grill(S1) | implement 开工前置 | 对齐门:没批准不许写实现 |
| `.flow/tasks.md` | slice(S3) | implement、run-loop | 切片与依赖 |
| `.flow/state.json` | 脚本(**非 LLM**) | recover、status | "现在在哪";完成态只准脚本写 |
| `.flow/summary.md` | implement(S4) | review、retro | "当时为什么这么做" |
| `.flow/reviews/<sha>.md` | review.sh(S6) | 人、retro | 独立审查留痕 |
| `.flow/learnings.md` → 毕业进 `AGENTS.md` | retro(S8) | 下个 session 自动加载 | 复盘双环 |

**铁律(这条就是防散架本身)**:
> **任何件都不许自建私有状态。** 要读写状态,只能走上表。需要新状态?先在这张表里加一行(慎重),绝不开私有旁路。
> 新增任何 skill/脚本,第一步是声明它的 `(读, 写)`——对不上这张表,就是要散架的信号。

- [x] 把上表定稿为 `flow/CONTRACT.md`(单独成文,后续每件顶部引用它)
- [x] 定 `state.json` 字段:`{task, step, slices:[{id,status}], updated_by}`,**无时间戳**(抄 web-dev-skills,便于无状态重建)

---

## Phase 1 — keystone:S2 规格合成 + 让 verify.sh 读它(先做这个,它同时解集成缺口)

**为什么先做**:`spec.md` 是窄腰。定了它,能力件和强制件就咬上了;不定,后面全是空中楼阁。

**从谁吸取什么(合成,非抄)**:
- spec-kit → 需求编号(可追溯)+ `/converge` 式"实现后反查 missing/unrequested"
- missions → 每条验收写成**机器可跑**形式 + "端到端禁 import 内部模块绕过"
- mattpocock → seam 先与人约定
- **合成出的新物**:一份 spec 同时是①人读的规格 ②`verify.sh` 直接能跑的门禁 ③可反向查漏的清单

- [x] 定稿 `spec.md` 格式(需求编号 + Seams + 每条 AC 带 `verify:` 命令 + out-of-scope 段)→ CONTRACT §spec.md
- [x] `flow/lib/verify.sh` 读该格式(per-AC 证据落盘 `.flow/evidence/ac-N.log`)
- [x] 写 `flow/skills/spec/SKILL.md` + `EXAMPLE.md`(**flow-native,综合自 spec-kit/missions/mattpocock**)
- [x] ✅ **咬合检查点已过**:真 spec 跑通 `verify.sh`,拦截路径退出 1、修好退出 0、每条 AC 证据落盘

> 停靠点 A:到这里,"写规格→机器验收"闭环可用,已经比裸用任何一家强。

---

## Phase 2 — 完成权接线(C5,flow-native 合成)

**从谁吸取**:consensus-rnd(只认退出码 + sentinel,日志文本不算)+ maestro(完成态只准 CLI 写)。
**合成出的新物**:host 无关的轻量版——`state.json` 的 `slices[].status=done` **只准 verify.sh 按退出码翻**,LLM 永远不能自己写 done。

- [x] `lib/state.sh` 单一写者(pending/running/blocked/step),**拒绝写任何 done**
- [x] `verify.sh --complete[-slice]`:全绿时才写 `done`(任务级/切片级),是 done 的唯一入口
- [x] `flow complete [slice-id]` 派发;`flow status`/`state` 读写 `.flow/state`
- [x] pre-push 适配层:非全绿则退出 1、push 被拦、state 不动(沿用现有 verify)
- [x] ✅ **咬合检查点已过**:①state.sh 写 done 被拒(退出2)②验收失败 complete 后 state 无 done ③全绿后仅 verify.sh 写 done ④代码审查确认全仓只有 verify.sh 全绿分支写 done

> 停靠点 B:完成权从 LLM 手里剥夺,机器说了算。

---

## Phase 3 — retro 双环(S8,只能自组:源是 AGPL/无许可)

**从谁吸取**:trellis(回写作 commit 前置)+ maestro(洞见自动注入)。二者各做一半且**都不能抄**。
**合成出的新物**:host 无关双环——回写 `.flow/learnings.md`,稳定项**毕业进 `AGENTS.md`**(每个 host 启动自动加载 = 不靠 hook 的注入)。

- [x] 写 `flow/skills/retro/SKILL.md`(flow-native,合成 trellis+maestro)
- [x] 薄接线件 `lib/record.sh`:`./flow approve`(写 .flow/approved)、`./flow learn`(追加 learnings.md)
- [x] 定"毕业"规则:learnings.md 本地流水账(不入库),AGENTS.md 入库+自动加载=注入层
- [x] ✅ **咬合检查点已过**:approve/learn 写对契约文件;`git check-ignore` 确认 learnings.md 忽略、AGENTS.md 可入库(两层分明)

---

## Phase 4 — 采用 mattpocock craft 件,接线到契约(不重写,只接 I/O)

这些**单一源已是天花板**,不合成、不改写,只把它们的输入输出接到契约上。

- [x] 逐字 vendored:grilling / to-prd / to-issues / implement / tdd / code-review / diagnosing-bugs(MIT + 署名)
- [ ] 补齐限流未拉的附属:`tdd/tests.md`、`tdd/mocking.md`;建立 `CONTEXT.md`/ADR 约定
- [ ] 写薄接线说明(**不改 skill 本身**):grilling 达成共识后 → `./flow approve` 写 `.flow/approved`;implement 收工 → 交 verify.sh
- [ ] 决策:to-prd(产 tracker PRD)与我们的 spec.md 二选一或做一次转换(Phase 1 定了 spec.md 后回填)
- ✅ **咬合检查点**:每个 vendored skill 的产出都被接进契约 artifact,没有游离在外的

---

## Phase 5 — 端到端验证(一个真实小任务走完)

- [ ] 挑一个真实小需求,走 grill→spec→slice→implement→verify→review→retro
- [ ] 确认 7 个 artifact 按契约流转、门禁按预期触发/拦截
- [ ] 记录真实痛点 → 回头只加疼的那一个机制(痛点驱动,不追完备)

---

## 进度总览

- [x] Phase 4 部分:7 个 craft 件 vendored
- [x] Phase 0:立脊柱 `CONTRACT.md`(artifact 契约 + state.json 字段)
- [x] Phase 1:S2 规格合成 + verify 咬合(keystone)——**咬合检查点已过**
- [x] Phase 2:完成权接线(state.sh 拒写 done + verify.sh 唯一 done 写者)——**咬合检查点已过**
- [x] Phase 3:retro 双环(回写 learnings + 毕业进 AGENTS.md)——**咬合检查点已过**
- [x] 接线欠账:补 slice(产 tasks.md)+ implement(flow-native,查 approved/记 summary/经 complete)+ 切片级 verify(修 --complete-slice 跑本片 verify)+ summary 接线件 + tdd 附属 + PLAYBOOK
- [x] 门禁自测 `flow/test/smoke.sh`:16 项回归(secret/verify/完成权/切片边界/review mock 管路/接线件),全绿
- [x] review 管路已用 mock 验证(喂对 spec+diff、识别 BLOCK、落盘、拦截);**判断质量**才需真模型
- [x] **Phase 5:端到端实测已过** ← greet 真任务从 grill 走到 retro,7 个 artifact 按契约流转、门禁全触发、status 全程跟得上(修了 2 个实测暴露的 bug:derive 的 grep-c 退出码、smoke 的 cwd+token字面量)
- [x] step 推进洞已修:改为**据 artifact 推导**(state.sh derive),不靠命令驱动,漏跑也不错
- [ ] 仍欠(非阻塞):CONTEXT.md/ADR 约定;放跑挡位;recover;改断言防护;review 判断质量需真模型

**做一点是一点的原则**:按 Phase 顺序走,每个停靠点系统都合得上;跳着做会撞穿脊柱契约,别跳。

## 实测结论(2026-07-06)

**骨架 + 三处合成 + craft 采用 + 契约接线,端到端实测跑通。** greet 小任务全链无报错,16 项回归全绿。
仍是"可用骨架"而非成品:review 判断质量要配真模型、有几处手动接缝、CONTEXT/ADR/放跑/recover 未做——但**核心流程从"理论通"变成了"实测通"**。
