---
name: flow-progress
description: Rewrite the resume snapshot at docs/agents/PROGRESS.md. Use after finishing a step, before a commit, or when a key decision or blocker changes — so a fresh session can pick up where this one left off.
---

# Rewrite the resume snapshot

`docs/agents/PROGRESS.md` is a **snapshot** of the present, not a log. Rewrite the whole file each time: keep only what a fresh session needs to continue, and drop whatever has gone stale.

Five sections, ≤70 lines total:
- **Goal** — the one thing this continuous task must finish. Rewrite it if the user has switched tasks.
- **Doing now** — the current task and the exact step in progress.
- **Key context** — the minimum to resume: decisions locked in, files changed with a one-line summary, assumptions in play. Keep what the next run will use.
- **Next** — the next action, concrete enough to start immediately, with file paths.
- **Blockers** — what's blocking, or (none).

## The test that tells you it's good
Ask: **if the context vanished right now, could the next run continue from this file alone?** If not, something's missing — add it. If a line wouldn't help that next run, cut it.

The snapshot is done when it passes that test and reads as the current state.
