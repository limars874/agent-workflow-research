# consensus-rnd

## 基本信息
- 地址：https://github.com/ChronoAIProject/consensus-rnd
- 作者：ChronoAIProject 组织
- Stars：约 23（小众早期项目），Fork 4，MIT License，默认分支 `dev`
- 语言：Python（skill 脚本 + 大量 pytest 契约测试），创建于 2026-05，持续活跃（最近更新 2026-07-03）
- 目标 agent host：**通用/跨 host**。仓库自述："通用共识式研发 skills 库 — 可被任意 host 注入的多角度共识构建引擎"。提供 `.claude-plugin`（Claude Code marketplace）、`.codex-plugin`、`.cursor-plugin`、`gemini-extension.json`（Gemini，入口 GEMINI.md）四套平台清单，全部指向同一 `skills/` 树；也可直接把 `skills/<name>/` 复制进 agent 本地 skills 目录。

## 定位与设计哲学
**一句话定位**：一个以"多角度有偏共识（biased independent multi-angle convergence）"为核心的自治研发引擎——多个持不同先验的独立 solver 各自出方案，meta-judge 收敛为一个具体计划，再经独立三方审查真值表把关合并与发布。

它认为 agent 编码的核心问题是：**单一 LLM 视角不可靠，且"跑几遍投票"也不够**。解法是结构化的对抗性共识：
1. solver/reviewer 从不同先验出发（minimal 最小改动、structural 结构完整、delete 删除压力；architecture/quality/tests）；
2. "同轮同级互相不可见"（same-round peers must not read one another's output before sealing their own verdicts），防止上下文污染与从众；
3. 分歧收敛到固定出口：consensus / converge（继续收敛轮）/ 真僵持则上报 meta 层；
4. controller 是纯编排器，只路由/提交/推送，一切实现与修复委托给隔离 worker。

另一个隐含哲学：**GitHub 是唯一持久事实面（single display）**——所有状态通过 labels、issue comments、PR body + 哨兵标记 `⟦AI:AUTO-LOOP⟧` 呈现；本地 `.refactor-loop/` 只是 cache/logs，"never a durable ledger"。

## 核心机制

### 目录结构
```
skills/
  consensus-loop/        # 重型自治循环
    SKILL.md             # 合约文档（主入口）
    host.env.example     # 宿主注入变量矩阵（~45 个变量）
    prompts/             # 25 个角色 prompt（见下）
    scripts/             # consensus-rnd-cli + ghwrap + codex_refactor_loop + ~100 个契约测试
    authorizations/ migrations/
  sshx/                  # 轻量内联共识
    SKILL.md
.claude-plugin/ .codex-plugin/ .cursor-plugin/ gemini-extension.json
AGENTS.md CLAUDE.md GEMINI.md   # 各 host 入口文档
```

### skill 一：consensus-loop（重型自治循环）
处理仓库自身 issue/PR 的完整自治研发系统：设计共识 → 实现 → 审查 → 合并 → 发布。

- **设计共识阶段**：三个独立 solver（`solver-minimal.md` / `solver-structural.md` / `solver-delete.md`）+ 一个 `meta-judge.md`。solver 只提案不写码不动 GitHub，输出 markdown artifact（framing、具体计划含文件/LOC 增量/测试/治理修改、风险清单、reasoning trace），最后发唯一 `SOLVER_DONE:` marker（五种允许结局：propose / abstain / escalate:gpg-ratification / escalate:no-plan / false-positive）。
- **meta-judge 真值表**：consensus 条件 = "3/3 propose AND framings agree (same boundary, ≤30% LOC variance)"，或"greenfield 例外：2 propose + 1 delete abstain"。否则 converge 出收敛问题继续下一轮；≥3 轮无进展由 router 转 stalled reflector。判官"不得发明第 4 种混合方案"，只输出 `META_JUDGE_DONE:consensus:...` 或 `META_JUDGE_DONE:converge:round-N:<question>`。
- **实现与审查**：worker 在隔离 worktree 实现（`implement.md`）；三个 reviewer（architect/quality/tests）独立审查，**合并真值表**：`reject==0 && approve>=1 && 所有必需 reviewer 到场 && 所有 final-sentinel 评论 head == 当前 PR head`。同 head 重复审查触发 `repeated_review_blocker`。
- **结构化消费边界**：controller 只读 worker 产物的 clean-exit marker 和 frontmatter，"never raw prose"——日志文本仅供诊断，路由完全由结构化字段驱动（防止 prose 注入劫持编排）。
- **prompt 组织**：25 个角色 prompt，含共享片段（`_github-post-rules.md`、`_reasoning-discipline.md`）与专用角色（audit、verify、test-add、rebase-resolve、remote-ci-fix、review-fix、patrol-analysis、triage-external-issue、meta-reflector-stalled 等）。prompt 中用占位符 `${HOST_BUILD_CMD}`、`${HOST_COMMENT_RULE}` 在构建时从 host.env 注入。
- **host.env 注入**：宿主项目通过 `CONSENSUS_RND_HOST_ENV` 指向 host.env，约 45 个变量：REPO_ROOT、GH_REPO_SLUG、BUILD_CMD、TEST_CMD、INTEGRATION_BRANCH、RELEASE_AUTO_ENABLE、CODEX_FLOOR（并发下限，默认 5）、HOST_WORK_LANGUAGE（对外产物 en/zh，源码 English-only）等；**缺失一律 fail-closed**。
- **守护进程群**：约 6 个 GitHub 轮询 daemon（phase9-router、patrol-inspector、comment-monitor、concurrency-monitor 等），controller 周期 wakeup 读 `daemon-status --json`，stale 就 `restart-daemons`；可选 cron/launchd 做外层 keepalive。
- **命名运行时例外**（编号如 issue 引用）：Release Gate (#56)、Release Publisher (#322，exact-SHA required-checks 全绿才发布)、Rollup Autonomous Merge、Default Issue Intake (#623，cap/cooldown 准入)、Wakeup-Runner (#396)、Patrol Inspector (#541，按 fingerprint 发窄的 managed design issue)、RuntimeRetention (#437，日志压缩与 worktree 清理需 safety proof 字段)。

### skill 二：sshx（轻量内联共识）
面向单个高风险决策，"无守护进程、无控制平面、禁用 GitHub/git/标签/版本"。7 阶段：`intake → choose_worker_mode → thinking_triplet_workers → meta_judge → implementation_worker → review_triplet_workers → fix_or_done`。
- **WorkerMode 三级降级**：codex-cli（默认，须先做非变异能力检查）→ isolated-token-subagent → abstain（两者不可用时**禁止在调用者上下文自行做**）。
- **纯 prompt 级契约**：GoalArtifact（不可变 5 字段决策记录）、SshxResultEnvelope（仅 `conclusion` + `log_ref`，不含推理）、SshxWorkerFlightRecord（flight_id、状态、重试预算）。
- **完成认定只看机器信号**：进程退出码 0 + result_ref 可解析 + completion_sentinel 存在 + verdict 在允许集合内；"stdout/stderr/日志文本绝不参与完成检测"。
- **美学纪律**：每个 worker 必须援引成熟工程原则、指出每个候选方案的具体丑陋缺陷（抽象泄露/重复真值源/特殊情况），未验证假设标 `ASSUMED-UNVERIFIED`。

## 步骤流覆盖
| 步骤 | 覆盖 | 怎么做 |
|---|---|---|
| 澄清意图 | ✅ 部分 | sshx 的 intake 产 GoalArtifact（规范化目标、约束、成功标准、迭代问题）；consensus-loop 侧有 `triage-external-issue.md` 与 issue 分解，但主要面向 issue 已存在的场景，缺人机对话式澄清 |
| 治理上下文 | ✅ 强 | 同轮 worker 互相不可见；controller 只消费 frontmatter/marker 不读 prose；sshx "no context pollution"——调用者只带 conclusion + log_ref |
| 写清规格 | ✅ | solver 产出结构化方案 artifact（文件、LOC 增量、测试、风险、escalation 条件）；meta-judge 收敛后输出结构化 implementation plan；设计过程整体沉淀在 design issue（design-issue-body/reply prompt） |
| 小步切片 | ⚠️ 弱 | minimal solver 施加最小改动偏好、LOC variance ≤30% 约束隐含小改动倾向，但没有显式的"任务切片成多个小 PR"机制；有 issue decomposition 测试暗示存在分解逻辑 |
| 实现功能 | ✅ | 隔离 worktree 中的 implementation worker，按共识计划执行；spawn lock（#490 原子锁）防重复派发 |
| 验证证据 | ✅ 强 | BUILD_CMD/TEST_CMD 机器验证、`verify.md`/`test-add.md` prompt、完成认定只认退出码+sentinel+可解析 envelope，日志文本无效 |
| 独立审查 | ✅ 极强 | 三个有偏 reviewer（architecture/quality/tests）+ 固定合并真值表 + review head 必须等于 live PR head；"即使方向明显也必须过关" |
| 可控发布 | ✅ | Release Gate opt-in（RELEASE_AUTO_ENABLE）、dry-run/dispatch 双模、exact-SHA required-checks 全绿才发布、rollup PR squash-merge 需 CI 通过；注意：发布不回滚，"废弃标签由下个版本替代" |
| 复盘沉淀 | ⚠️ 部分 | meta-reflector-stalled / meta-reflector-repository-stalled 处理僵局反思；patrol inspector 把 worker 故障 fingerprint 化发 design issue（故障→新工作项闭环）；但无面向人的 retro/经验库机制 |

## 横切能力覆盖
| 能力 | 覆盖 | 说明 |
|---|---|---|
| Task State 中断恢复 | ✅ 强（独特实现） | 状态全部持久在 GitHub（labels/comments/PR body + 哨兵标记），本地 `.refactor-loop/` 仅 cache——任何设备/会话崩溃后可从 GitHub 重建；ActiveControllerLease (#191) 保证跨设备恰好一个 controller；daemon 靠 DaemonLaunchFingerprint 检测 stale 自动 reload |
| Journal / Trace | ✅ | 每次决策在 GitHub 留痕（design issue、solver artifact、reviewer verdict、AI sentinel 标记 AI 产物）；solver 要求 reasoning trace；RuntimeRetention 管日志压缩 |
| Safety Guardrails | ✅ 强 | 全面 fail-closed（缺 host.env、缺变量、共识缺 solver、真值表不满足 → 全部拒绝动作）；"No public lifecycle CLI" —— merge/close/label 只能经证据验证后的 controller 内部路径；solver 禁写码禁 GitHub 变更；sshx 禁止调用者自行修复；README 大篇幅风险告知（自治写入、API 消耗）+ 显式 opt-in |
| Tool Compatibility 跨 host | ✅ 名义上强，实际有限 | 四平台 manifest 指向同一 skill 树是真跨 host；但 consensus-loop 运行时深度依赖 Codex worker 派发、Claude Code statusLine、gh CLI、cron/launchd，实际是"Claude Code 做 controller + Codex 做 worker"的特定组合；sshx 才是真正 host 无关的部分 |
| Runtime-Scripts 机器验证下沉 | ✅ 极强 | scripts/ 下 `consensus-rnd-cli`、ghwrap（gh 调用包装含预算/退避/参数校验）+ 上百个 pytest 契约测试（marker 发射契约、prompt 语言契约、真值表、并发监控、release pipeline……）——连 prompt 本身都被测试锁定（test_prompt_contracts.py、test_marker_only_prompts_gh_ban.py、test_no_new_prose_detection.py） |

## 独特亮点
1. **有偏三方共识 + 固定真值表**：不是投票，是设计好的对抗先验（minimal/structural/delete；architecture/quality/tests）+ 同轮互盲 + 机械化收敛规则（3/3 propose、LOC variance ≤30%、reject==0 && approve>=1 && head 一致）。把"多视角"从玄学变成了可测试的契约。
2. **GitHub 即数据库 + 结构化消费边界**：所有持久状态上 GitHub，本地零权威；controller 只读 marker/frontmatter 从不读 prose——同时解决了中断恢复、多设备协同、审计留痕和 prose-injection 安全三个问题。
3. **prompt 被测试锁死**：用上百个 pytest 把 prompt 的 marker 发射、语言、禁令（如 prompt 内禁直接调 gh）、真值表都变成回归测试，这是极少见的"prompt 工程可测试化"实践。

## 明显欠缺
- **前端缺失**：几乎没有"人向 agent 澄清意图"的交互环节——假设 issue 已写好；意图澄清、需求访谈弱。
- **切片弱**：没有显式的小步 PR 切片方法论，工作单元粒度基本 = 一个 issue。
- **无回滚**：发布"不回滚，废弃标签由下个版本替代"；自治 merge/发布出事后的恢复路径薄。
- **复盘偏机器**：stalled reflector / patrol 是给循环自愈用的，没有面向团队的知识沉淀。
- **成本失控风险**：6 个轮询 daemon + 持续 Codex 派发，README 自己承认会持续吃 quota/token/算力；小团队日常使用门槛高。
- **实验性**：作者自述非生产保证，stars 少、生态验证不足。

## 臃肿度与耦合度评价
- **consensus-loop：重。** ~45 个 host.env 变量、6 daemon、25 prompt、上百测试、ActiveControllerLease/spawn lock/patrol/retention 等一整套控制平面。学习成本高（SKILL.md 本身就是一份复杂系统合约），接入需要配 host.env + statusLine + cron。虽宣称任意 host 可注入，实际运行时与 **Codex CLI（worker）+ Claude Code（controller/statusline）+ gh CLI + GitHub 平台**耦合很深——离开 GitHub 整个状态模型即失效。
- **sshx：轻。** 纯 prompt 级契约、单决策内联、无守护进程，可近乎零成本移植到任意 host，是该仓库真正"通用"的部分。
- 总体：这是一个"引擎级"框架而非"清单级"skill 集，适合想做全自治仓库研发的人整体采纳，不适合按需抽取（除 sshx 外模块间耦合紧）。

## 关键证据
- 仓库元信息：GitHub API `repos/ChronoAIProject/consensus-rnd`（23 stars，默认分支 dev，MIT，Python，描述"通用共识式研发 skills 库 — 可被任意 host 注入的多角度共识构建引擎"）。
- `README.md`：共识引擎定义（"biased independent solvers produce candidate plans, a meta-judge converges them"）、同轮互盲、纯编排 controller、四平台安装方式、风险告知（自治写入/自动发布/不回滚/API 消耗）、授权边界（不做任意 GitHub 管理）。
- `skills/consensus-loop/SKILL.md`：GitHub single display + `⟦AI:AUTO-LOOP⟧` 哨兵、`.refactor-loop/` 仅 cache、结构化消费边界、审查真值表 `reject==0 && approve>=1 && ... head equal live PR head`、ActiveControllerLease (#191)、Spawn Claim 原子锁 (#490)、命名例外（#56/#322/#623/#396/#541/#437）、fail-closed 清单、"No public lifecycle CLI"。
- `skills/consensus-loop/prompts/`：25 个文件（solver-minimal/structural/delete、meta-judge、reviewer-architect/quality/tests、_reasoning-discipline、meta-reflector-* 等）。
- `prompts/solver-minimal.md`：五种终态 marker、禁写码禁 GitHub 变更、artifact 结构（framing/计划/风险/escalation/reasoning trace）。
- `prompts/meta-judge.md`：consensus 条件 "3/3 propose AND framings agree (same boundary, ≤30% LOC variance)"、greenfield 例外、禁发明第 4 方案、`META_JUDGE_DONE:consensus|converge` marker。
- `skills/consensus-loop/host.env.example`：REPO_ROOT/GH_REPO_SLUG/BUILD_CMD/TEST_CMD/INTEGRATION_BRANCH/RELEASE_AUTO_ENABLE/CODEX_FLOOR/HOST_WORK_LANGUAGE 等分组。
- `skills/consensus-loop/scripts/`：consensus-rnd-cli、ghwrap、约百个契约测试（test_consensus_gate.py、test_prompt_contracts.py、test_marker_only_prompts_gh_ban.py、test_active_controller_lease.py、test_release_pipeline_contract.py 等）。
- `skills/sshx/SKILL.md`：7 阶段流程、WorkerMode 三级降级、GoalArtifact/SshxResultEnvelope/FlightRecord、"stdout/stderr/日志文本绝不参与完成检测"、`ASSUMED-UNVERIFIED` 标记纪律。
