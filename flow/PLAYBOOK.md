# PLAYBOOK — 一个任务从头到尾怎么跑

> 诚实说明:这不是全自动流水线,有几处**手动接缝**(标 🖐)。因为走 host 无关路线,skill(prose)和脚本(强制)之间靠约定文件对话,接缝需要你或 agent 显式跑一句命令。

## 一次任务的完整序列

| 步 | 谁做 | 命令 / 动作 | 产出(契约 artifact) |
|---|---|---|---|
| S1 澄清 | skill `grilling` | 拷问对齐到共识 | — |
| 🖐 接缝 | 你 | `./flow approve "用CSV不用xlsx"` | `.flow/approved` |
| S2 规格 | skill `spec` | 写规格 | `spec.md` |
| S3 切片 | skill `slice` | 切竖片 | `.flow/tasks.md` |
| S4 实现(每片) | skill `implement` | `./flow state slice T1 running` → 写码(用 `tdd`/`code-review`) | 代码 |
| 🖐 记账 | implement | `./flow summary "T1: 做了X/偏差Y/stub Z"` | `.flow/summary.md` |
| S5 完成权 | 脚本 | `./flow complete T1` | 全绿才写 `slice T1: done` |
| S6 审查 | 脚本 | push → pre-push 跑 `verify`+`review` | `.flow/reviews/<sha>.md` |
| S8 复盘 | skill `retro` | `./flow learn "..."` → 毕业进 `AGENTS.md` | `.flow/learnings.md`、`AGENTS.md` |

随时 `./flow status` 看 `.flow/state`。断了看 `spec.md`+`tasks.md`+`state` 就能接上。

## 装到你的项目

```bash
cp -r flow /你的项目/           # 或 git submodule
cd /你的项目
./flow/profiles/install.sh standard   # 接 pre-push;light=纯手动;max=全接
# skill:把 flow/skills/ 指给你的 host(Claude Code .claude/skills、Codex AGENTS.md 引用等)
```

## 配 review(否则 S6 是空过)

`review.sh` 默认 **fail-open**——不配就跳过跨模型审(会告警)。要真跑,给一个读 stdin、输出评审、发现问题吐 `BLOCK` 的命令:

```bash
export FLOW_REVIEW_CMD='codex exec "对照下述 spec 审查此 diff,发现缺漏/mock糊弄/范围偏离就输出 BLOCK 并说明"'
```

放进你的 shell profile 或项目 `.envrc`。没有第二个模型的 CLI 时,S6 就只有 pre-push 里的测试门禁,没有跨模型二审——**这一点要心里有数**。

## 服务端(可选但推荐,白得的 L3)

GitHub 给 `main` 开分支保护 + 把测试挂 required check。两分钟,agent 够不着,是本地 hook 之外的最终兜底。

## 手动接缝为什么存在(诚实)

vendored 的 craft skill(grilling 等)是逐字原文,**不知道**我们的 `.flow/` 契约。为不改它们(保真),接缝由你/agent 显式跑 `./flow approve|summary|complete|learn` 来填。这是"host 无关 + 不改 vendored"两个选择的必然代价:换来可移植和保真,付出几处手动命令。
