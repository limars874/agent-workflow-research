# roadmap.md Format

`docs/roadmap.md` holds the plan (what, in what order) and the progress (what's done) in one file. It starts as a draft and becomes directional only after owner confirmation. No time estimates.

## Structure

```md
# Roadmap

> Status: draft
> Owner confirmation required before this document guides future work.

## Milestones
- 🚧 M1 <current milestone, one line>
- 📋 M2 <next>

## Phases (current milestone)

### Phase 1 · <name>
- **Goal**: <one line, user-facing>
- **Depends on**: <none / Phase X>
- **Success criteria**: <2-5 observable behaviours>
- **Plans**:
  - [ ] 1-1 <plan, one line>

## Progress
| Phase | Plans done | Status |
|---|---|---|
| 1 | 0/1 | in progress |
```

## Rules

- **Status is file-level.** New files start as `draft`; change to `confirmed` only after the owner reviews and accepts the whole document. Missing status means draft.
- **Draft is not direction.** Use a draft roadmap as planning input, not as committed project direction.
- **Milestone → Phase → Plan.** A small project can use just Phases + a checklist.
- **Success criteria are observable, user-facing behaviours** — not implementation steps.
- **No time estimates.**
