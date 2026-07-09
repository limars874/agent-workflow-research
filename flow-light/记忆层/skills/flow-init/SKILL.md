---
name: flow-init
description: Set up the flow-light memory layer for this repo — create the docs/agents/ memory files and wire AGENTS.md so the host reads them. Run once, after setup-matt-pocock-skills.
disable-model-invocation: true
---

# Set up the flow-light memory layer

Scaffold the project memory the companion flow relies on, and teach the host to read it:

- **Resume state** — `docs/agents/PROGRESS.md`, the snapshot a fresh session reads to continue
- **Constraints** — `docs/agents/constraints.md`, the project-wide rules every task obeys
- **Roadmap** — `docs/agents/ROADMAP.md`, the milestones work rolls up to
- **Lessons** — `docs/agents/learnings.md`, what past runs learned

This is a prompt-driven skill, not a deterministic script. Explore, present what you found, confirm with the user, then write. It is idempotent: update files in place and preserve the user's edits.

Run after `setup-matt-pocock-skills` — that skill owns the issue tracker, triage labels, domain docs, and `CONTEXT.md`. This skill owns only the memory layer and leaves setup's files alone.

## Process

### 1. Explore
Read the current state; don't assume:
- `AGENTS.md` / `CLAUDE.md` at the repo root — which exists? **Which one already holds setup's `## Agent skills` block?** (the memory section co-locates there.) Is there already a `## Project memory (flow-light)` section, and in which file?
- `docs/agents/` — do `PROGRESS.md` / `constraints.md` / `ROADMAP.md` / `learnings.md` already exist?
- Whether the repo has real code (brownfield — constraints can be inferred) or is empty (greenfield).

### 2. Present findings and ask
Summarise what's present and what's missing, then settle **which root file** the memory section goes in — the two sections must live side by side in one file:
- If setup's `## Agent skills` block already exists, write the memory section into **that same file**, right after it. Don't split them across `AGENTS.md` and `CLAUDE.md`.
- If setup hasn't run, follow setup's own rule: edit `CLAUDE.md` if it exists, else `AGENTS.md`, else ask the user which to create — don't pick for them.
- If a `## Project memory (flow-light)` section already exists in a *different* file than setup's block, say so and move it beside setup's block.

For a brownfield repo, also confirm you'll read the code to draft the constraints, and they'll review that draft before it's relied on.

### 3. Write the skeleton
Create any missing file in `docs/agents/`, each in its owning format:
- `PROGRESS.md` (Goal = "init", Doing now = "idle") — see the flow-progress skill's `PROGRESS-FORMAT.md`.
- `constraints.md` — see [CONSTRAINTS-FORMAT.md](./CONSTRAINTS-FORMAT.md).
- `ROADMAP.md` — see [ROADMAP-FORMAT.md](./ROADMAP-FORMAT.md).
- `learnings.md` — just a `# Lessons` heading; the flow-reflect skill owns its entry format.

Then add a `## Project memory (flow-light)` section to the root file settled in step 2 (from [AGENTS-memory-block.md](./AGENTS-memory-block.md)), beside setup's `## Agent skills` block. Update it in place if it already exists in that file; leave setup's block untouched. Keep `docs/agents/PROGRESS.md` tracked in git, so any machine can resume.

### 4. Infer constraints (brownfield only)
Read the codebase and draft `constraints.md` (and a first-pass `ROADMAP.md` if the user wants one). Sweep in focused passes; **every entry cites a `file/path` as evidence**:
- **Stack** — package.json / pyproject / lockfiles / config → the locked stack and libraries → `## Stack`.
- **Architecture** — directory layout, module boundaries, import direction → the layering rules → `## Architecture`.
- **Style** — conventions the code holds consistently but that aren't self-evident → `## Style`.

Route by kind: a domain term belongs in `CONTEXT.md` (domain-modeling's territory), a rule belongs in constraints. Report that a secrets file exists; read its values never. Mark anything uncertain "unsure".

### 5. Confirm and finish
Show the drafted `constraints.md` (and `ROADMAP.md`) to the user before relying on them — durable memory earns a human pass. Let them edit. Then set `PROGRESS.md` to the user's real task, or "idle".

Tell the user the memory layer is live, and that `flow-progress` and `flow-reflect` maintain it from here.
