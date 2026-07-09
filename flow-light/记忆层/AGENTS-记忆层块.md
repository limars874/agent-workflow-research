<!-- 把下面这一整节贴进你项目根的 AGENTS.md(Codex 每会话自动加载)。
     独立成节,setup 的 ## Agent skills 块保持原样。
     它每轮都占上下文,所以只放"必须每轮在场的反射"——craft 在各 skill 里,这里只指路。 -->

## 项目记忆层(flow-light)

记忆在 `docs/agents/`。

- **开工 / 新会话 / 延续任务**:先读 `PROGRESS.md` 复位。当前用户消息仍是同一任务 → 采信它接着做;已切新任务 → 按当前消息重判,并用 flow-progress 重写 PROGRESS。
- **动手前**:读 `constraints.md`(碰前端读 `frontend.md`、碰后端读 `backend.md`,若存在)。要方向读 `ROADMAP.md`;查历史读 `learnings.md`、`docs/adr/`、`CONTEXT.md`。
- **主线优先级**:当前用户消息 > 代码与验证证据 > `PROGRESS`(只补进度) > 其他记忆文件。
- **维护**:进度更新用 `flow-progress`,教训沉淀用 `flow-reflect`(二者在该触发时自行触发)。
