<!-- 把下面这一整节贴进你项目根的 AGENTS.md(Codex 每会话自动加载)。
     独立成节,不要动 mattpocock setup 维护的 ## Agent skills 块。
     保持精简——它每会话都占上下文,细节留给各文件自己。 -->

## 项目记忆层(flow-light)

本项目的持久记忆在 `docs/agents/`。按下述规则读写,别只凭会话记忆。

**读(什么时候读什么)**
- 开工 / 新会话 / 延续任务:**先读 `docs/agents/PROGRESS.md` 复位**。先确认当前用户消息仍是同一任务,是→采信它接着做;否→按当前消息重新判断,并立即重写 PROGRESS。
- 动手前:读 `docs/agents/constraints.md`(项目约束);碰前端读 `docs/agents/frontend.md`、碰后端读 `docs/agents/backend.md`(若存在)。
- 需要方向:读 `docs/agents/ROADMAP.md`。深入历史:`docs/agents/learnings.md`、`docs/adr/`、`CONTEXT.md`。
- **主线判断优先级**:当前用户消息/命令 > 代码与验证证据 > PROGRESS(只补进度) > 其他记忆文件。

**写(什么时候更新)**
- 关键决策落定 / 子任务完成 / 遇到或解除阻塞 / 收尾 / 每次 commit 后:**重写 `PROGRESS.md`**(整体重写,非追加;≤70 行;只记当前状态不记历史)。
  - 自检:现在若压缩或换会话,下一轮能只凭 PROGRESS 找回进度吗?不能 → 没写好。
- 出现"值得记的教训"(2+ 次验证才过 / 调试>3 次 / 中途换方案 / 用户纠正了假设):按格式追加到 `docs/agents/learnings.md`。
- 定下新的项目级约束 → 写进 `constraints.md`;架构级不可逆决策 → 走 `docs/adr/`;领域术语 → `CONTEXT.md`。
