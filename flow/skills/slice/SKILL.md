---
name: slice
description: 小步切片(S3)。把 spec 切成 reviewer 能独立批准的竖片,产出 .flow/tasks.md;每片自带验收命令。在 spec 后、实现前使用。
---

# 小步切片

读仓库根 `spec.md`,切成竖片,写进 `.flow/tasks.md`。格式(见 CONTRACT §tasks.md):

```
- [ ] T1 <一句话:端到端一个可 demo 的小功能>
  files: <预计涉及的文件>
  verify: <这片自己的验收命令,绿=通过>
  depends: <可选,依赖的 T 编号,如 T1>
```

切分标准:
- **一片 = reviewer 能独立批准或拒绝的量**,不是按代码行数。
- **竖切不横切**:一片是贯穿到底的小功能(tracer bullet),不是"先写所有 model 再写所有 controller"。
- **有上下界**:太大无法独立验证;太碎反被噪音主导。一个 feature 约 2-5 片。
- **标依赖**:零文件交集、无 `depends` 的片可并行(放跑挡位据此判断)。

每片的 `verify:` 命令要能被 `./flow complete <T>` 直接跑——它就是这片的切片级完成门禁。

交接:`.flow/tasks.md` 交给 implement 逐片实现。
