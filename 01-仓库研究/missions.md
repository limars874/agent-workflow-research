# missions

## 基本信息
- **地址**: https://github.com/flowing-water1/Missions
- **作者**: flowing-water1（中文作者，文档以中文为主）
- **Stars**: ~51（小众个人项目量级）
- **目标 agent host**: Codex CLI（首选，配合 `/goal`）+ Claude Code 双兼容；同时提供 AGENTS.md 与 CLAUDE.md 两套入口
- **形态**: 纯 prompt/skill 包（14 个文件：README、codex-missions.md、6 个 skill 目录下的 SKILL.md + 辅助 schema 文档），无任何代码/脚本

## 定位与设计哲学
**一句话定位**：以 CSV 为唯一状态源的长任务闭环执行框架——把需求分解成 CSV 行，逐行走"开发→初审→回归→提交"四态闭环，断线后一句 `continue` 从断点恢复。

它认为 agent 编码的核心问题有两个：
1. **agent 中途莫名停下**（"干净边界谬误"——agent 总想在阶段性节点停下汇报），导致长任务需要人反复推；
2. **声明与证据不一致**（用 mock/stub/dry-run 包装成"完成"），导致虚假交付。

解法分别是：反暂停护栏 + 状态机强制续跑；四态闭环 + `required_mcp` 强制工具调用证据。

## 核心机制

### Skill 栈（路由汇聚架构）
| Skill | 职责 |
|---|---|
| `mission` | 路由器，只分类分发不执行 |
| `mission-approved-doc` | 批准的设计文档 → `issues/*.csv`（含硬停批准门） |
| `mission-long-task` | 自然语言 → 5-15 条原子 issue → `.mission/*.csv` |
| `mission-csv-execute` | 核心执行引擎，Step 0-9 闭环循环 |
| `mission-recovery` | 扫描未完成 CSV，修复状态，转交执行器 |
| `mission-doc-route` | markdown 文档路由 |

路由规则顺序匹配、首中即走：`*.csv` → 执行器；`.md` → 文档路由；空输入/"continue/继续" → 恢复；预估 >1 小时或 ≥3 步 → long-task 分解；轻量任务直接做不进 mission。"所有执行流最终汇聚到 `mission-csv-execute`"。

### CSV 状态机（唯一状态源）
19 列 schema，关键字段：
- `acceptance_criteria`：必须机器可验证，格式 `WHEN X THEN Y; ref: file:line`
- `test_mcp`：验证策略枚举（AUTOSERVER/AUTOFRONTEND/AUTOE2E/CONTRACT/MIGRATION/MANUAL）
- `required_skills`：执行合同——实现前必须显式读取的 skill
- `required_mcp`：验收合同——必须实际调用的工具（playwright、chrome-devtools 等）
- 四个状态列：`dev_state`/`review_initial_state`/`review_regression_state`（未开始/进行中/已完成）+ `git_state`（未提交/已提交）
- `refs`：至少一个 `path:line`

### Step 0-9 执行循环（每条 issue）
接收与现实检查 → 补齐执行信息 → 状态置"进行中"写回 CSV → 上下文收集（读 skill、refs、规划 MCP 证据）→ 实现（最小原子变更）→ 两段式 Review（初次+回归，`required_mcp` 逐项落证）→ 自我验收（管线 vs 模块判定）→ 状态置"已完成"+ notes 写证据摘要 → Git 提交 → **立即 continue_now 下一条，不等用户**。

### 闭环判定
> "四个全到位 + `required_mcp` 证据齐 = 闭环。少一个都不行"

### 反暂停护栏（最有特色的机制）
- 硬规则 #15："非终态 turn 必须以工具调用结尾"——禁止纯文本收尾
- #16："执行态优先于问答态"——回答用户问题后同一 turn 必须继续工具调用
- 明确列举 8 种"不构成停止条件"的情形（完成里程碑、写完 checkpoint、想做阶段汇报、X/Y 完成、下一条更脏……）
- 停止前强制三问断言：全部闭环？剩余全是 human-required blockers？继续需伪造证据？三问皆非"是" → 不得停止
- 每轮末行强制 `continue_now: <next id>` 并立即执行

### 声明-证据一致性
- #17：禁止用 mock/fixture/stub/dry-run/字符串检查伪装真实完成
- "管线 vs 模块"判定：验收涉及端到端行为必须走完整管线（HTTP→中间件→业务→数据层），不得 import 内部模块绕过
- 受限验收：仅"需付费/凭证/外部服务不可达"可豁免，且必须记录 `validation_limited/validation_gap/mcp_evidence/risk` 四项；"缺依赖、缺环境配置"不构成理由，agent 自行解决

### Vision Review（REVIEW-* 行）
全部非 review 行闭环后，调用**同模型独立 sub-agent**，对照批准文档 + CSV 全状态 + diff/commit + 测试/MCP 证据审查，结论 `vision_met` 或 `gaps_found`；发现差距则追加 follow-up issue + `REVIEW-(N+1)` 行继续跑。结果写 `<csv-path>.review.md`（固定格式含 Claim/evidence alignment 字段）。

### Codex 适配（codex-missions.md，29KB 长文）
作者推荐分工：**Claude Opus 做讨论/规格/CSV 生成**（"Codex 拆得太粗，Claude 能拆 15-20 条原子 issue"），**Codex `/goal @file.csv` 执行**（`/goal` 自带断线自动续跑，API 挂了恢复后自动继续）。skill 包放 `.codex/skills/`。

## 步骤流覆盖
| 步骤 | 覆盖 | 说明 |
|---|---|---|
| 澄清意图 | ⚠️ 弱 | long-task 有"歧义问用户"、approved-doc 有批准硬停门，但无系统化提问/brainstorm 阶段（外包给 Superpowers，仅在 codex-missions.md 中作为可选前置推荐） |
| 治理上下文 | ⚠️ 部分 | Step 3 上下文收集（读 refs/skill、首次 5-8 工具调用），CSV 本身即压缩后的任务上下文，但无 context 预算/压缩机制 |
| 写清规格 | ✅ | 规格 = CSV：机器可验证 acceptance_criteria + refs + 测试策略 + 工具合同；上游设计文档假设由 Superpowers 产出 |
| 小步切片 | ✅ 强 | 原子分解硬规则："一个 issue = 一个可独立验证、独立提交的原子变更"，多验收场景必须拆行 |
| 实现功能 | ✅ | Step 4：拆验收条件→最小变更→内循环验证→文档同步 |
| 验证证据 | ✅✅ 极强 | 全框架核心：test_mcp 策略 + required_mcp 实际调用证据 + 管线级验收 + 每工具最低证据门槛（如 chrome-devtools 需截图+console/network 摘要）+ 受限验收显式记录 gap |
| 独立审查 | ✅ | 行级两段式 review + 整体 Vision Review 同模型 sub-agent，明确检查 claim/evidence 对齐、mock 伪装 |
| 可控发布 | ⚠️ 部分 | 每 issue 原子 commit、CSV 与代码同提交；但无分支/PR/CI/回滚策略 |
| 复盘沉淀 | ❌ 基本无 | review.md 和 log.md 是过程记录，无经验沉淀/规则更新回路 |

## 横切能力覆盖
| 能力 | 覆盖 | 说明 |
|---|---|---|
| Task State 中断恢复 | ✅✅ 极强（招牌能力）| CSV 是持久化状态机；mission-recovery 扫描 issues/ 和 .mission/、校验 schema、修复不一致（如 git_state=已提交但实际未提交→重置）、报告 X/Y 进度后转交执行器；配合 Codex /goal 自动续跑 |
| Journal-Trace | ✅ 中等 | notes 列（done_at/skills_used/mcp_used/证据摘要）+ `.review.md` + `.mission/<task>/log.md` 决策日志；但非结构化事件流 |
| Safety Guardrails | ⚠️ 弱 | 主要护栏针对"不许停/不许作假"，几乎无破坏性操作防护（删文件、force push、生产环境等无约束；仅 approved-doc 有用户批准门） |
| Tool Compatibility 跨 host | ✅ 较好 | AGENTS.md（Codex）+ CLAUDE.md（Claude Code）双入口，skill 为纯 markdown 无 host API 依赖；但 required_mcp 假设特定 MCP（playwright/chrome-devtools/screenpipe）已装 |
| Runtime-Scripts 机器验证下沉 | ❌ 无 | 零脚本零代码，全部约束靠 prompt 文字，状态一致性靠 LLM 自律读写 CSV——规模化/可靠性隐患（CSV 写坏、状态漂移无机器校验） |

## 独特亮点
1. **反暂停护栏体系**：对"agent 爱在阶段节点停下"这一痛点的对抗设计最细致——枚举伪停止条件、停止三问断言、"非终态 turn 必须以工具调用结尾"、continue_now 强制续跑，是同类框架中少见的系统化 anti-pause prompt 工程。
2. **验收合同化**：required_mcp/required_skills 作为"合同"字段写进任务行，配每工具最低证据门槛和"管线 vs 模块"判定，直接针对 LLM 用 mock 糊弄验收的顽疾；受限验收规则连"什么不算借口"都写死。
3. **CSV 作为跨会话状态机**：用最朴素的格式实现可 diff、可 git 提交、可断点恢复的任务状态，与 Codex /goal 组合形成"掉线免疫"的长任务方案。

## 明显欠缺
- **前段缺失**：无澄清意图/头脑风暴/规格写作能力，完全依赖外部（Superpowers）产出批准文档；框架从"已有清晰需求"才开始。
- **零机器验证**：所有约束纯 prompt，CSV 读写、状态一致性、证据核查全靠 LLM 自觉；无 lint/hook/脚本兜底，规模化后状态漂移风险高。
- **安全护栏薄**：反暂停设计强推"不停不问"，与破坏性操作防护是天然张力——文档几乎没有 destructive op 约束，一路狂奔的 agent 出错成本高。
- **无复盘沉淀**：没有把踩坑经验回写到规则/skill 的机制。
- **无发布工程**：无分支策略、PR、CI 门禁概念，git 只用作提交状态位。
- **中英混杂状态值**（`已完成`/`已提交`）对非中文用户和解析脚本不友好。

## 臃肿度与耦合度评价
- **非常轻量**：14 个 markdown 文件，无依赖、无安装脚本，拷进 `.codex/skills/` 或 `.claude/skills/` 即用。
- **host 耦合浅**：核心逻辑是纯文字规约，双 host 兼容；但最佳体验绑定 Codex `/goal`（断线续跑靠它），且验证体系隐性依赖 playwright/chrome-devtools/screenpipe 等 MCP 生态。
- **学习成本低、接入成本低**：概念只有一个（CSV 四态闭环），README+schema 半小时可上手；但要发挥全部价值需搭配 Superpowers 做前段规格，形成两件套。
- **重量集中在 prompt 密度**：mission-csv-execute/SKILL.md 规则条款极多（17+ 条硬规则），对模型指令遵循能力要求高，弱模型可能执行走样。

## 关键证据
- `README.md`：四态闭环定义 "四个全到位 + required_mcp 证据齐 = 闭环。少一个都不行"；命令 `mission @issues/....csv` / `mission continue`
- `mission-csv-execute/SKILL.md`：Step 0-9；硬规则 #1 "CSV 是唯一状态源"、#15 "非终态 turn 必须以工具调用结尾"、#17 声明-证据一致性；"干净边界谬误：partial completion (3/9) 是最脏状态"；停止三问断言；`continue_now` 强制
- `mission-csv-execute/csv-schema.md`：19 列 schema，`acceptance_criteria` 格式 "WHEN X THEN Y; ref: file:line"
- `mission-csv-execute/test-mcp-mapping.md`：6 种 test_mcp 模式；chrome-devtools 需"至少一次页面截图 + console/network 摘要"
- `mission-approved-doc/SKILL.md`：批准硬停门 "若未批准则硬停…请先明确批准后再执行"；REVIEW-01 审计行须检查 mock/stub 伪装
- `mission-long-task/SKILL.md`：5-15 步原子分解；"一个 issue = 一个可独立验证工作单元"，多验收场景必须拆行
- `mission-recovery/SKILL.md`："恢复器自己不执行 issue loop，只负责定位与转交"；git_state 不一致修复规则
- `mission/SKILL.md`：路由顺序匹配规则；"所有执行流最终汇聚到 mission-csv-execute"
- `codex-missions.md`：Claude Opus 做规格 + Codex /goal 执行的分工；"Codex 拆得粗，Claude 能拆 15-20 条原子 issue"；skill 放 `.codex/skills/`
