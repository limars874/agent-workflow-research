---
name: spec
description: 写清规格(S2)。把共识写成 spec.md,每条验收标准配一条可跑的 verify 命令;它同时是重构回归的"行为清单"。
---

# spec — 写清规格

> 抄自:missions 的验收合同(可机器验的 acceptance)+ spec-kit 的 `/converge`(反向对照)+ trellis 的"规格进仓库"。
> 对抗的失败模式:意图只存在于对话历史,session 一断即失真;验收全靠嘴说。

## 产出:仓库根 `spec.md`

格式(**verify: 行是硬约定,verify.sh 会抽取并逐条执行**):

```markdown
# <任务名>

## 需求
- R1: <一句话需求>
- R2: ...

## 验收标准
- AC1 <人话描述>
  verify: <一条能跑、绿=通过的命令>       # 例:pnpm test src/foo.test.ts
- AC2 <人话描述>
  verify: <命令>

## 明确不做(out of scope)
- <防 agent 手痒多写>
```

## 铁律
1. **每条验收标准必须配一条 `verify:` 命令**,且是端到端的(禁止 import 内部模块绕过真实路径)。写不出可跑命令的验收标准 = 没想清楚,退回 grill。
2. **写"明确不做"**:抄 spec-kit 的 unrequested 分类,专防 agent 多写。
3. **规格是唯一真理源**:实现和对话有出入,以 spec.md 为准;要改需求先改 spec。

## 重构专用(你被坑过的那个)
重构任务里,spec.md 的验收标准 = **重构前的行为清单**。做法:
1. 重构前,先让 agent 通读旧代码,把所有现有行为(尤其 edge case 判断)逐条写成 AC + verify。
2. 人过目补充遗漏。
3. 重构后逐条对照——`verify.sh` 全绿才算"行为没丢"。
特征测试写在**最外层稳定边界**(CLI/API/UI 级),内部架构怎么翻断言都不用动。

## 交接
产出:`spec.md`。下一步交给 `slice`;`verify.sh` 消费它。
