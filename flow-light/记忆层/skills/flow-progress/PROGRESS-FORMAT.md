# PROGRESS.md Format

`docs/PROGRESS.md` is a snapshot of the present, not a log. Rewrite the whole file each time; ≤70 lines.

## Structure

```md
# Resume snapshot

## Goal
[one line: what this continuous task must actually finish]

## Doing now
[one line: current task + the exact step in progress; "idle" if none]

## Key context
[minimum to resume: decisions locked in, files changed + one-line summary, assumptions in play]

## Next
[the next action, concrete enough to start immediately, with file paths]

## Blockers
(none)
```

## Rules

- **Snapshot, not log.** Rewrite the whole file; keep the current state, drop what's gone stale.
- **≤70 lines.** Longer means it's carrying history it shouldn't.
- **Key context is the minimum to resume** — the decisions, files, and assumptions the next run needs, and nothing it doesn't.
