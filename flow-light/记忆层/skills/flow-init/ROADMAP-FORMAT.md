# ROADMAP.md Format

`docs/agents/ROADMAP.md` holds the plan (what, in what order) and the progress (what's done) in one file. No time estimates.

## Structure

```md
# Roadmap

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

- **Milestone → Phase → Plan.** A small project can use just Phases + a checklist.
- **Success criteria are observable, user-facing behaviours** — not implementation steps.
- **No time estimates.**
