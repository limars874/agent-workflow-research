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

| 能力 | 状态 | 综合自哪些机制(致敬,非复制) |
|---|---|---|
| `spec/`(S2 规格) | ✅ 已写 | spec-kit 的需求编号+converge 反查、missions 的机器可验收+反 mock、mattpocock 的 seam 先约定。**是原创综合,不是任何一家的复制** |
| retro / learnings | ⏳ 未写 | 源是 trellis(AGPL,传染,不能抄)+ maestro(无 LICENSE,不能抄)——只能自组 |
| 放跑挡位 / 状态恢复 | ⏳ 未写 | 本就是本仓库自有机制 |

---

## 三、集成缺口(Phase 1 已解决)

原缺口:mattpocock 的 to-prd 产出 tracker PRD,不产出 verify.sh 要读的 spec.md。

**解法(已落地)**:走上面的方案 (b)——写了 flow-native 的 `spec/` 能力件,产出 `flow/CONTRACT.md §spec.md` 定义的格式,`verify.sh` 直接读它。咬合检查点已过(真 spec 跑通、拦截/放行两条路径都验)。
to-prd 现定位为**可选的前段 craft 参考**(它的 seam-先约定、tight PRD 思路已吸收进 spec skill),不再要求它直接驱动门禁。

---

## 四、其他候选源为何没抄

| 源 | 许可 | 结论 |
|---|---|---|
| superpowers / spec-kit / gsd | MIT(可抄) | 但其 skill 深耦合自身框架(STATE.md/wave 等),逐字抄会拖入耦合、违背本方案"轻/host 无关",故不抄;需要时"改编"并另行标注 |
| maestro-flow / missions | **无 LICENSE** | 法律上保留所有权利,**不可复制** |
| trellis | AGPL-3.0 | 传染性,不复制 |
