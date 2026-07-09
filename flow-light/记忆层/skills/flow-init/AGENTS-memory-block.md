<!-- The section flow-init writes into the repo-root AGENTS.md (Codex auto-loads it every session).
     A standalone section; leave setup's ## Agent skills block untouched.
     It costs context every turn, so keep it to reflexes that must always be present — the craft lives in the skills; this only points. -->

## Project memory (flow-light)

Memory lives in `docs/agents/`.

- **At session start / on a new session / continuing a task**: read `PROGRESS.md` first to resume. If the current user message is the same task → trust it and continue; if it's a new task → judge from the message and rewrite PROGRESS via flow-progress.
- **Before acting**: read `constraints.md` (and `frontend.md` / `backend.md` if present, when touching them). For direction read `ROADMAP.md`; for history read `learnings.md`, `docs/adr/`, `CONTEXT.md`.
- **Main-line priority**: current user message > code and verification evidence > `PROGRESS` (progress only) > other memory files.
- **Maintenance**: update progress with `flow-progress`, capture lessons with `flow-reflect` (both fire themselves at the right moment).
