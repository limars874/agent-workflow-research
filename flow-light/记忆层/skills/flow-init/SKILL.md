---
name: flow-init
description: Set up the flow-light memory layer for this repo — create the docs/ memory files and wire AGENTS.md so the host reads them. Run once, after setup-matt-pocock-skills.
disable-model-invocation: true
---

# Set up the flow-light memory layer

Scaffold the project memory the companion flow relies on, and teach the host to read it:

- **Resume state** — `docs/progress.md`, the snapshot a fresh session reads to continue
- **Constraints** — `docs/constraints.md`, the project-wide rules every task obeys after owner confirmation
- **Roadmap** — `docs/roadmap.md`, the milestones work rolls up to after owner confirmation
- **Lessons** — `docs/learnings.md`, what past runs learned

This is a prompt-driven skill, not a deterministic script. Explore, present what you found, confirm with the user, then write. It is idempotent: update files in place and preserve the user's edits.

Run after `setup-matt-pocock-skills` — that skill owns the issue tracker, triage labels, domain docs, and `CONTEXT.md`. This skill owns only the memory layer and leaves setup's files alone.

## Process

### 1. Explore
Read the current state; don't assume:
- `AGENTS.md` / `CLAUDE.md` at the repo root — which exists? **Which one already holds setup's `## Agent skills` block?** (the memory section co-locates there.) Is there already a `## Project memory (flow-light)` section, and in which file?
- `docs/` — do `progress.md` / `constraints.md` / `roadmap.md` / `learnings.md` already exist?
- Whether the repo has real code (brownfield — constraints can be inferred) or is empty (greenfield).

### 2. Present findings and ask
Summarise what's present and what's missing, then settle **which root file** the memory section goes in — the two sections must live side by side in one file:
- If setup's `## Agent skills` block already exists, write the memory section into **that same file**, right after it. Don't split them across `AGENTS.md` and `CLAUDE.md`.
- If setup hasn't run, follow setup's own rule: edit `CLAUDE.md` if it exists, else `AGENTS.md`, else ask the user which to create — don't pick for them.
- If a `## Project memory (flow-light)` section already exists in a *different* file than setup's block, say so and move it beside setup's block.

For a brownfield repo, also confirm you'll read the code to draft the constraints, and they'll review that draft before it's binding.

### 3. Write the skeleton
Create any missing file in `docs/`, each in its owning format:
- `progress.md` (Goal = "init", Doing now = "idle") — see the flow-progress skill's `PROGRESS-FORMAT.md`.
- `constraints.md` — see [CONSTRAINTS-FORMAT.md](./CONSTRAINTS-FORMAT.md); set file `Status` from the source of its content.
- `roadmap.md` — see [ROADMAP-FORMAT.md](./ROADMAP-FORMAT.md); set file `Status` from the source of its content.
- `learnings.md` — just a `# Lessons` heading; the flow-reflect skill owns its entry format.
- `journal.md` — just a `# Journal` heading; the flow-journal skill owns its entry format.

Then add a `## Project memory (flow-light)` section to the root file settled in step 2 (from [AGENTS-memory-block.md](./AGENTS-memory-block.md)), beside setup's `## Agent skills` block. Update it in place if it already exists in that file; leave setup's block untouched. Keep `docs/progress.md` tracked in git, so any machine can resume.

### 4. Infer constraints (brownfield only)
You're mapping the code to find **durable principles**, not cataloguing the current structure. Reading code tells you what *is*; a constraint is what *should hold across refactors*. So **abstract every observation up to a boundary before writing it** (see CONSTRAINTS-FORMAT's rules): "AX reads stay in the detection layer; currently `NativeDialogDetector`" — never "`NativeDialogDetector` exclusively does AX reads". Which type does what, and current mechanisms (keybindings, MVP flows, exact UX), are implementation facts — leave them out unless they express a boundary that should survive a refactor.

Sweep in focused passes and abstract each into a principle:
- **Stack** — package.json / pyproject / lockfiles / config → the locked stack and libraries → `## Stack`.
- **Architecture** — directory layout, module boundaries, import direction → the layering / dependency-direction rules → `## Architecture`.
- **Style** — conventions the code holds consistently but that aren't self-evident → `## Style`.

Prefer a handful of strong boundaries over a per-file inventory. Route by kind: a domain term belongs in `CONTEXT.md` (domain-modeling's territory), a rule belongs in constraints. Report that a secrets file exists; read its values never. Mark anything uncertain "unsure". Existing code is evidence for a draft, not product intent by itself.

Set status by source: `confirmed` only when the file contains owner-provided or owner-confirmed content; `draft` when material content is inferred from code, inferred from history, or filled in by the model. If mixed or uncertain, use `draft` and show the user what needs confirmation.

### 5. Confirm and finish
Show the drafted `constraints.md` (and `roadmap.md`) to the user before relying on them — durable memory earns a human pass. Only confirmed documents are binding. Let them edit. Then set `progress.md` to the user's real task, or "idle".

Tell the user the memory layer is live, and that `flow-progress` and `flow-reflect` maintain it from here.
