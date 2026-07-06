---
name: retro
description: 复盘沉淀(S8)。把这次的坑与调通姿势沉淀下来,并让稳定教训"毕业"进 AGENTS.md 使其下次自动加载。触发:验证循环≥2次 / 调试>3次 / 换过方案 / 发现仓库暗礁。
---

# 复盘沉淀

双环,缺一不可。

## 环一:回写(本地流水账)
读 `.flow/summary.md` 的偏差记录和 `.flow/reviews/` 的审查发现,把值得记的写进 `.flow/learnings.md`:

```
./flow learn "坑:X / 因:Y / 策:下次Z"
```

或直接追加同样结构。learnings.md 是**本地噪音流水账**(不入库),大多是这个项目一次性的东西。

## 环二:毕业(生效注入)
从 learnings.md 里挑出**稳定、通用**的那几条,提炼成规则写进 `AGENTS.md`。

**为什么要两层**:`AGENTS.md` 入库,且每个 agent host 启动都自动加载——**这就是不靠 hook 的自动注入**。只有毕业进 AGENTS.md 的教训,下个 session 才会真正生效;留在 learnings.md 的不会。

## 毕业判据(克制,别把噪音塞进 AGENTS.md)
只有这三类值得毕业:
- 难复现、容易再踩的坑
- 会让新上下文吃惊的项目约定
- 有真实权衡、需要提前知道的决策

项目一次性的琐事留在 learnings.md,别污染 AGENTS.md。

交接:回写完 `.flow/learnings.md`,毕业物进 `AGENTS.md`。闭环。
