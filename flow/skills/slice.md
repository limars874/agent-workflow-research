---
name: slice
description: 小步切片(S3)。把 spec 切成"reviewer 能独立批准"的竖片,每片自带验收;切片有上下界,不是越碎越好。
---

# slice — 小步切片

> 抄自:superpowers 的切分标准("reviewer 能否独立批准这一片")+ gsd 的竖切(vertical slices over horizontal layers)+ maestro 的反过度切分。
> 对抗的失败模式:一次改一大片,无法独立验证/审查/回滚;长任务中途 context rot 崩塌。

## 产出:仓库根 `tasks.md`

```markdown
# tasks(来自 spec.md)

- [ ] T1 <竖片:端到端一个可 demo 的小功能>
  - files: <预计涉及的文件>
  - verify: <这片自己的验收命令>
- [ ] T2 ...
  - depends: T1        # 有依赖就写,无依赖的可并行(放跑挡位用)
```

## 铁律
1. **切分标准 = "reviewer 能独立批准或拒绝这一片"**,不是按代码行数。
2. **竖切不横切**:一片是"贯穿到底的一个小功能"(tracer bullet),不是"先写所有 model 再写所有 controller"。
3. **有上下界**:太大→无法独立验证;太碎→反被 mock 主导、对真实变化不敏感。一个 feature 约 2-5 片,一片约几十分钟能完成并验证。
4. **标依赖**:零文件交集的片可并行(放跑挡位按此判定能否并发)。

## 交接
产出:`tasks.md`。逐片交给 `implement`。
