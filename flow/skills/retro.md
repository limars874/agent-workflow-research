---
name: retro
description: 复盘沉淀(S8)。把这次踩的坑/调通的姿势写进 learnings,并"毕业"进 AGENTS.md/CLAUDE.md 使其下次自动加载——host 无关的双环。
---

# retro — 复盘沉淀

> 抄自:trellis 的 spec-sync(回写)+ maestro 的洞见自动回注 + mattpocock 的 `.out-of-scope`(拒绝先例)。
> 对抗的失败模式:教训留在聊天记录里蒸发,同一个坑每个 session 重踩。

## 双环(缺一不可)
1. **回写**:追加到 `.flow/learnings.md`
   ```markdown
   ## <日期> <一句话标题>
   - 坑: <发生了什么>
   - 因: <根因>
   - 策: <下次怎么避免 / 调通的姿势>
   ```
2. **自动注入(host 无关的关键)**:定期把稳定、通用的教训**毕业进 `AGENTS.md` / `CLAUDE.md`**——这两个文件每个 agent host 启动都自动加载,等于不靠 hook 的自动注入。
   - `.flow/learnings.md` = 流水账(全量、原始)
   - `AGENTS.md` = 提炼后的规则(下次真正生效的那份)

## 何时触发
抄 helloagents 的明确条件:验证循环 ≥2 次 / 调试超 3 次 / 中途换过方案 / 发现仓库暗礁。满足任一就 retro,别等"记得"。

## 交接
产出:`.flow/learnings.md`(回写)+ `AGENTS.md` 更新(注入)。闭环。
