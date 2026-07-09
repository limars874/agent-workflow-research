<!-- The section flow-init writes into the repo-root AGENTS.md (Codex auto-loads it every session).
     A standalone section; leave setup's ## Agent skills block untouched.
     It costs context every turn, so keep it to reflexes that must always be present — the craft lives in the skills; this only points. -->

## Project memory (flow-light)

Memory lives in `docs/`.

- **At session start / on a new session / continuing a task**: read `progress.md` first to resume. If the current user message is the same task → trust it and continue; if it's a new task → judge from the message and rewrite progress via flow-progress.
- **Before acting**: read `constraints.md` if present. If its `Status` is `confirmed`, obey it; if `draft` or missing, use it only as review context. For direction read `roadmap.md` with the same status rule. For "how did we get here" read `journal.md`; for lessons read `learnings.md`; for decisions read `docs/adr/`, `CONTEXT.md`.
- **Main-line priority**: current user message > code and verification evidence > confirmed memory files > `progress.md` (progress only) > draft memory files and history.
- **Maintenance**: update progress with `flow-progress`, record what happened with `flow-journal`, capture lessons with `flow-reflect` (each fires itself at the right moment).
