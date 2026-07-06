# skills — 能力件(抄各 repo 流程的 SKILL.md)

> 这些是**提示词文件**(靠 prompt、可移植),教 agent 怎么走流程。
> 另一半是 `../lib/` 的**强制件**(靠 git、不可绕),负责拦截。两者咬合,见下。

## 8 步 × 两类件的分工

| 步骤 | 能力件(prompt) | 强制件(script) | 抄自 |
|---|---|---|---|
| S1 澄清意图 | `grill.md` | grill 写 `.flow/approved` → implement 检查 | mattpocock grilling |
| S2 写清规格 | `spec.md` | 产出 `spec.md` → `verify.sh` 读它 | missions / spec-kit |
| S3 小步切片 | `slice.md` | 产出 `tasks.md` | superpowers / gsd |
| S4 实现功能 | `implement.md` | 偏差协议;`.flow/approved` 缺则拒开工 | gsd Rule 1-4 |
| S5 验证证据 | (在 implement 收工) | **`lib/verify.sh`** 跑 spec 的 verify 行 | consensus-rnd |
| S6 独立审查 | (无需 prompt) | **`lib/review.sh`** 跨模型审 | gstack /codex |
| S7 可控发布 | (无需 prompt) | 服务端分支保护 + required checks | consensus-rnd |
| S8 复盘沉淀 | `retro.md` | learnings 毕业进 AGENTS.md | trellis / maestro |

**咬合的精髓**:能力件产出的**文件**正是强制件消费的输入。
`spec` 写的 `spec.md` → `verify.sh` 抽 verify 行来跑;`grill` 写的 `.flow/approved` → `implement` 开工前检查。提示词负责"教怎么做",脚本负责"没做到就拦"——提示词漂移了,脚本兜底。

## 怎么用(host 无关)
这些是普通 markdown。放进你 host 的 skill 目录(Claude Code `.claude/skills/`、Codex `AGENTS.md` 引用皆可),或直接在对话里 `@` 引用。它们不依赖任何 host 私有机制。

## 现状
- ✅ grill / spec / slice / implement / retro(第二批能力件)
- ⏳ 放跑挡位 `run-loop`、断点 `recover`、断言防护(第三/四批)
