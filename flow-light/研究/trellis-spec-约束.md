# trellis spec(=约束/工程约定)怎么写(供 flow-light constraints 参考)

> 读 trellis(AGPL,只参考不抄)的 `trellis-update-spec/SKILL.md` + `trellis-spec-bootstrap/references/{repository-analysis,spec-writing}.md`。
> 背景:dogfood 发现 flow-init 反推的 constraints 过度锁定当前结构。回归发现我们抄的 gsd map-codebase 是"地图"不是"约束",trellis 的 spec 才是正主,且明显更对。

## 1. 两条建 spec 的路(对上我们 flow-init + flow-reflect)
- **bootstrap**:从仓库分析初始生成(对 flow-init brownfield)
- **update-spec**:**从学习增量捕获**(debugging/implementing/discussion 中学到的),每条是主动学到/决定的,不是被动扫的 → 天然不堆结构清单(对 flow-reflect learnings→constraints)

## 2. spec-writing.md 的核心(直接治过度锁定)
- spec = "**如何在这个仓库里工作**",不是通用项目怎么组织
- **Write From Evidence**:每条规则由 源文件/测试/重复模式 支撑;**链接文件路径 + 点名行为**
- **AVOID 清单**(命中我们的病):
  - ❌ **rules based on a single accidental implementation detail** ← MVP 机制/结构锁定
  - ❌ generic framework advice / long copied code / 单 host 工具指令
- **Example Shape**:规则=局部**模式/边界**(如 parsing/validation/side-effects 分离)+ **Reference files 单列(证据)** + **Avoid 反模式**

## 3. repository-analysis.md
- "发现真实架构**再写规则**;别从通用模板填空,从代码出发让结构跟着走"
- 读代表性源文件和测试**再把 finding 变成 spec rule**

## 4. flow-light 采纳(升级原 gsd 式修法)
constraints = 局部模式/边界(非结构清单、非通用建议),write-from-evidence(文件是证据非主语,禁单一 accidental detail),Example Shape 带 Evidence + Avoid,few strong boundaries。已改 CONSTRAINTS-FORMAT + flow-init step4。
架构验证:trellis bootstrap+update-spec = 我们 flow-init+flow-reflect,思路本来就对,只是 flow-init 该学 trellis 的 spec-writing 纪律而非 gsd 的 map。
