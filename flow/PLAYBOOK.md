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
cp -r flow /你的项目/           # 或 git submodule。flow/ 必须在项目根
cd /你的项目
echo '.flow/' >> .gitignore
./flow/profiles/install.sh standard   # 接 pre-push;light=纯手动;max=全接
```

## 装能力件(skill)—— 按 host 放进各自的发现目录

SKILL.md 是**开放标准**(Agent Skills),多数 host 会**自动扫描特定目录**发现它、按 description 触发。**不是**写进 AGENTS.md/CLAUDE.md 引用(那是另一层:always-on 项目上下文)。放法按 host:

| host | skill 放哪(自动发现) |
|---|---|
| Claude Code | `.claude/skills/<name>/SKILL.md` |
| Codex | `.agents/skills/<name>/SKILL.md`(仓库级)或 `~/.codex/skills/`(用户级) |
| 跨 host 同步 | 用安装器 `npx skills add ...`,一次投影到多个 host |

最简单:把 `flow/skills/` 下每个目录**软链**到对应位置,例:
```bash
mkdir -p .claude/skills && ln -s ../../flow/skills/* .claude/skills/   # Claude Code
# 或 Codex:mkdir -p .agents/skills && ln -s ../../flow/skills/* .agents/skills/
```

⚠️ **不可移植项(诚实)**:
- `code-review` 用的"并行 fresh subagent(上下文 fork)"是 **Claude Code 独有**,在 Codex 上会退化为同上下文审查(独立性打折)。
- 只有**核心 frontmatter**(name/description)跨 host;工具特有字段(如 Codex 的 openai.yaml、某些 Claude-only 字段)不通用。

⚠️⚠️ **最大的诚实边界**:我**只端到端测过脚本层**(bash 里跑 verify/complete/review 等,16 项回归 + greet 全链)。**skill 被真实 host 自动加载并正确触发/遵循,我没测过。** 纯手动用没问题(skill 就是 prose,你/agent 照着做即可);但"host 自动发现+按 description 隐式调用"这套,得你在自己的 Claude Code/Codex 里实测才算数。

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
