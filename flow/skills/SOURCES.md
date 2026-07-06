# skills 来源与署名(honest provenance)

这里的 skill **分两类**,泾渭分明,不混淆:

1. **vendored(逐字抄)** —— 从许可允许的开源仓库**一字不改**复制过来,原文即原文,不画蛇添足。
2. **flow-native(自组)** —— 我们自己写、且诚实标注为自组的(通常因为要咬合本仓库的强制脚本,或原始源许可不允许复制)。

> 背景:早期版本这里放过几个"凭理解重写、却包装成 skill"的假货,已全部删除。措辞即价值,能抄的必须逐字抄。

---

## 一、vendored:来自 mattpocock/skills

- **源**:https://github.com/mattpocock/skills
- **许可**:MIT(全文见同目录 `LICENSE.mattpocock`,MIT 要求复制时随附版权与许可声明,已满足)
- **抓取**:2026-07-06,`main` 分支,raw.githubusercontent 逐字;**逐字未改**
- **待补 SHA**:抓取时 GitHub API 限流,未能锁定 commit SHA;下次补 pin

| 本地文件 | 源路径 | 映射步骤 | 状态 |
|---|---|---|---|
| `grilling/SKILL.md` | productivity/grilling/SKILL.md | S1 澄清意图 | ✅ 逐字 |
| `to-prd/SKILL.md` | engineering/to-prd/SKILL.md | S2 写清规格 | ✅ 逐字 |
| `to-issues/SKILL.md` | engineering/to-issues/SKILL.md | S3 小步切片 | ✅ 逐字 |
| `implement/SKILL.md` | engineering/implement/SKILL.md | S4 实现 | ✅ 逐字 |
| `tdd/SKILL.md` | engineering/tdd/SKILL.md | S5 验证 | ✅ 逐字 |
| `code-review/SKILL.md` | engineering/code-review/SKILL.md | S6 独立审查 | ✅ 逐字 |
| `diagnosing-bugs/SKILL.md` | engineering/diagnosing-bugs/SKILL.md | S5 调试 | ✅ 逐字 |

### ⚠️ 未闭合的引用(限流未拉全,TODO)
vendored 文件里有指向**尚未拉取**的兄弟文件/约定,现在是悬空链接:
- `tdd/SKILL.md` → `tests.md`、`mocking.md`(附属,必须补,否则 tdd 不完整)
- 多处引用 `CONTEXT.md` 约定(项目领域词汇表)与 `ADR`(架构决策记录)——这是 mattpocock 套装的**隐含前置**,采用需一并建立
- `implement` → `/tdd`、`/code-review`(套装内互引,已在本目录,OK)

**含义**:mattpocock 的 skill 是**一套互相咬合的套装**,不是孤立文件。要忠实使用,得连 `tests.md`/`mocking.md`/`CONTEXT.md`/ADR 约定一起采纳。下次限流解除补齐。

---

## 二、flow-native:自组(尚未写)

以下步骤**没有可逐字复制的干净源**,需自己写并诚实标注,**不会伪装成"抄来的"**:

| 能力 | 为什么自组 |
|---|---|
| spec ↔ verify.sh 的咬合约定 | 见下"集成缺口";mattpocock 的 to-prd 产出 tracker PRD,不产出我们脚本要读的 `spec.md` |
| retro / learnings | 源是 trellis(AGPL,传染,不能抄)+ maestro(无 LICENSE=保留所有权利,不能抄) |
| 放跑挡位 / 状态恢复 | 本就是本仓库自有机制 |

---

## 三、⚠️ 集成缺口(必须正视,未解决)

强制层 `flow/lib/verify.sh` 期望仓库根有 `spec.md`,每条验收写成 `verify: <命令>`。
但 vendored 的 `to-prd` **不产出这个格式**——它产出 issue tracker 里的 PRD。

**即:能力件(mattpocock)和强制件(我们的脚本)现在不咬合。** 二选一:
- (a) 改 `verify.sh` 去适配 mattpocock 的 PRD/issue 产物;或
- (b) 保留一个 flow-native 的 spec 约定(自组),只在它和 to-prd 之间做一次转换。

这是设计决策,留给下一步定,**不在文档里假装已解决**。

---

## 四、其他候选源为何没抄

| 源 | 许可 | 结论 |
|---|---|---|
| superpowers / spec-kit / gsd | MIT(可抄) | 但其 skill 深耦合自身框架(STATE.md/wave 等),逐字抄会拖入耦合、违背本方案"轻/host 无关",故不抄;需要时"改编"并另行标注 |
| maestro-flow / missions | **无 LICENSE** | 法律上保留所有权利,**不可复制** |
| trellis | AGPL-3.0 | 传染性,不复制 |
