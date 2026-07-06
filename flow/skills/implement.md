---
name: implement
description: 实现功能(S4)。带偏差协议的受控执行——能自动修的修,架构级变更必须停下问人,3 次尝试上限,全程记账。
---

# implement — 受控执行

> 抄自:gsd 的偏差四规则 + helloagents 的"受阻先试 2 种替代方案" + superpowers 的最小 task-brief。
> 对抗的失败模式:执行偏离计划无人察觉;遇阻静默降级/缩范围;污染上下文。

## 开工前置(硬门)
1. **检查 `.flow/approved` 存在**,否则停下——没经过 grill 对齐不许写实现代码。
2. 读 `spec.md` + `tasks.md`,认领一片(一个未打勾的 T)。

## 偏差协议(核心,抄 gsd Rule 1-4)
执行中遇到计划没覆盖的情况:
- **Rule 1-3(可自修)**:仅限**当前这片改动直接引起**的问题——就地修,记入 summary。
- **Rule 4(必须停):架构级变更、跨子系统影响、要装新依赖 → 停下问人。** 不许自作主张。
- **3 次上限**:同一个坑试 3 次没通 → 停下,先试 2 种**实质不同**的替代方案,仍不行则求助,不许无限死磕。
- **禁止静默缩范围**:做不到就说做不到,不许把"支持并发"偷偷降级成 TODO 然后宣布完成。

## 记账(每片必做)
```bash
mkdir -p .flow
cat >> .flow/summary.md <<EOF
## $(date -u +%FT%TZ) T<n>
- 做了: ...
- 偏差: <每条对应原因,Rule 几>
- 遗留 stub/TODO: <诚实列出>
EOF
```

## 收工(交给强制层,不自证完成)
1. 跑本片的 verify 命令,自己先看绿。
2. **不要口头宣布"完成"** —— 完成与否由 `verify.sh`(push 时)判定。
3. 提交,让 pre-push 的 verify + 跨模型 review 兜底。

## 交接
产出:代码 + `.flow/summary.md`。push 时 `verify.sh`/`review.sh` 把关。
