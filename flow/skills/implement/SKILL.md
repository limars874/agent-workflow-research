---
name: implement
description: 受控执行(S4)。带偏差协议地实现一个切片:能自动修的修,架构级变更必须停下问人,遇阻先试两种替代,全程记账。在 approved 后使用。
---

# 受控执行

## 开工前置(硬前置)
1. 确认 `.flow/approved` 存在(grill 已对齐)。没有就先 grill + `./flow approve`。
2. 读 `spec.md` + `.flow/tasks.md`,认领一片未打勾的 `T`。`./flow state slice T<n> running`。

## 做的过程
- craft 委托给 vendored 件:在预先约定的 seam 用 `tdd`,收尾用 `code-review`(见 skills/tdd、skills/code-review)。
- **偏差协议**(遇到计划没覆盖的情况):
  - 当前这片改动**直接引起**的小问题 → 就地修,记进 summary。
  - **架构级变更 / 跨子系统 / 要装新依赖 → 停下问人**,不许自作主张。
  - 同一个坑试 3 次不通 → 先试**两种实质不同**的替代方案,仍不行则求助,不许无限死磕。
  - **禁止静默缩范围**:做不到就说做不到,不许把"支持并发"偷偷降级成 TODO 又宣布完成。

## 记账(每片必做)
```
./flow summary "T<n>: 做了X / 偏差:Y(架构级已问人)/ 遗留 stub:Z"
```
写进 `.flow/summary.md`,供 review 和 retro 读。

## 收工(不自证完成)
1. **不要口头宣布"完成"**。跑 `./flow complete T<n>` —— 由 verify.sh 按这片的 verify 退出码决定,全绿才翻 `done`。
2. 全绿后交给 `code-review` + push(pre-push 会再跑 verify + 跨模型审)。

交接:代码 + `.flow/summary.md`;完成权由 `./flow complete` 把关。
