# ROADMAP · flow-light(陪伴型)

> `flow-*` 家族的陪伴轻量版。采用现成好 skill(mattpocock)+ 自建**项目记忆层** + 按需补真实缺口。
> 目标 host:Codex(高上下文可持续)。**机器门禁/脚本暂缓**,先纯手动跑通。
> 纪律:见文末"从 v1 失败学到的规矩"。**痛点驱动,不预先建全。**

---

## 要建的东西(方向,非清单)

**不是又一个框架。** 是三块:
1. **采用层**:mattpocock 真身(grilling/to-prd/to-issues/implement/tdd/code-review/…),不重造。
2. **记忆层(核心,自建)**:照 helloagents 结构改造成纯 markdown、手动维护版。
   - 记忆层(耐久):约束/规范/蓝图 → `AGENTS.md` + 指向的 reference md
   - 状态层(易变):任务内进度 + 复位上下文 → 一个 `STATE.md`(≤70 行单文件重写,抄 helloagents)
   - 追溯层(增长):决策记录 → 追加式(抄 maestro decisions)
   - roadmap 层:项目多任务轨迹 → `ROADMAP.md`(抄 gsd)
3. **补缺层**:只补真实咬人的缺口(见 P0 验证结果)。

---

## 阶段(每阶段是"合得上"的停靠点,gated 前一步结果)

### P0 · 用户实测 mattpocock 真身(先做,你来)
不建任何东西。在真 Codex 里装 mattpocock 全套,跑一个真实小任务,收集缺口。
- [ ] 装:`npx skills@latest add mattpocock/skills`(或 clone → `.agents/skills/`)
- [ ] 跑:`/grilling → /to-prd → /to-issues → /implement`
- [ ] **带缺口观察表验证**(理论预测的真缺口):
  - 跨会话教训会不会**蒸发**?(S8)
  - 重构会不会**漏掉已有功能**?(重构反查)
  - 会不会**没测就说完成**?(完成权,边际)
  - **压缩后**它靠什么复位、顺不顺?(状态层)
  - `code-review` 在 Codex 上(无 subagent fork)够不够狠?

### P1 · 定向深读记忆层最佳实现(gated:P0 确认要建记忆层)
- [ ] 深读 helloagents:`.helloagents/` 结构、`~init` 行为、`STATE.md` 模板、旧项目怎么扫描填充
- [ ] 深读 gsd:`ROADMAP.md` 形态、`map-codebase`(旧项目 init)
- [ ] 产出:记忆层的确切文件结构 + init 行为设计(手动版)

### P2 · 手动搭记忆层(gated:P1)
- [ ] 定 `AGENTS.md` 骨架(耐久约束 + 指向大块 reference 的规则)
- [ ] 定 `STATE.md` 模板(≤70 行,复位友好)
- [ ] 定追溯/roadmap 文件形态
- [ ] **init 说明**:新项目怎么建这些文件;旧项目怎么让 AI 扫代码反推填充
- [ ] 纯 markdown,靠 AI 按 skill 提示手动维护,**无脚本**

### P3 · 补真实缺口(gated:P0 结果)
- [ ] 复盘沉淀件(教训回写 + 毕业进 AGENTS.md)—— 若 P0 确认教训蒸发
- [ ] 重构反查件(对照 spec 查 missing)—— 若 P0 确认重构漏东西
- [ ] 其余按 P0 实际疼的补,不疼不补

### 暂缓(明确不做,除非将来有痛点)
- 所有机器门禁 / git hook / 完成权脚本 / 状态机脚本(v1 就死在这)
- 分解编排型架构(留给"小上下文 host"的另一个版本,以后另说)

---

## 从 v1 失败学到的规矩(每步自检)
1. **先定架构再动手**,不骑墙(companion-light 就是 companion-light,不掺分解型机器)。
2. **skills-first**:先让流程手动跑通,再谈任何机器件。
3. **痛点驱动**:缺口是**实测**出来的,不是想象的;不疼不补。
4. **早在真 host 验**:别又攒一堆没在 Codex 里跑过的东西。
5. **先理解再动手**:涉及 skill 机制/框架细节,查证再说,不懂装懂。
6. **诚实标注**:抄来的标来源,自组的标自组,没验的标没验。
