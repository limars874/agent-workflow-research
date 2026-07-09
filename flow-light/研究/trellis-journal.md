# trellis 的 journal / 记忆分层(供 flow-light 参考)

> 读的是 trellis(mindfold-ai/Trellis,AGPL)真身:`trellis-session-insight/SKILL.md` + `trellis-meta/references/local-architecture/workspace-memory.md`。AGPL 只参考模式,不抄文件。

## 1. 三个 store + routing 铁律(最值钱)

| store | 存什么 | flow-light 对应 |
|---|---|---|
| `.trellis/tasks/` | 某任务的需求/设计/状态 | PROGRESS(快照) |
| `.trellis/workspace/<dev>/journal-N.md` | 跨任务跨会话的**工作记录 = journal** | journal(新增) |
| `.trellis/spec/` | 长期工程约定 | constraints |

**routing 铁律**:只对当前任务有用 → 任务目录;描述这次会话发生了什么 → journal;以后每次写代码都要遵守 → spec。
→ learnings→constraints 的回写在 spec 那条线;journal 是独立的另一条线。**两条分开,不混。**

## 2. 两种 journal 形态

- **写出来的 journal**:`journal-N.md`,每会话追加 `title + summary + commit`,~2000 行轮转(`add_session.py`)。
- **`trellis mem`(session-insight skill)**:不写文件,**索引原始对话日志**(`~/.claude`、`~/.codex/sessions/`、`~/.pi` 的 JSONL),按关键词/任务边界搜过去对话。
  → **Codex 的 JSONL 本身就是完整开发日志**;mem 只是检索工具。flow-light 现在做"写出来的 journal";检索工具是机器层,**defer**。

## 3. "能力,非仪式"哲学(治 journal 变噪音)

session-insight 原文:**没有固定输出文件、没有强制回写、没有"finish-work 后必须跑"**;mem 是工具不是 ceremony;硬把每次 recall 塞进固定文件→长成噪音。
→ flow-light journal 照此:**会话/里程碑/值得记的 commit 才追加,不强制每步**。

## 4. 其他框架 journal(对比,都更重/机械)
- maestro `decisions.ndjson`(结构化决策日志)+ goal_changelog + `.history/`
- gsd `SUMMARY.md`(deviations↔commit + threat flags + known stubs)
- gstack `context-save` checkpoint(append-only,frontmatter branch/status)
- missions `.mission/<task>/log.md`
- mattpocock / helloagents:**明确无**结构化 journal

## 结论
flow-light 抄 trellis 的**写出来的 journal + 三 store routing + 能力非仪式**:一个 append-only `docs/agents/journal.md`,判断驱动。journal 与 learnings 分开(各一条线)。Codex JSONL 检索留作未来机器层。
