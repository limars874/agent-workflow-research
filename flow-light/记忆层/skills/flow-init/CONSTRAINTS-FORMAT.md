# constraints.md Format

`docs/constraints.md` holds project-wide rules. Its file-level `Status` says whether the document is binding.

## Structure

```md
# Constraints

> Status: draft
> Owner confirmation required before this document is binding.

## Stack (locked choices — don't swap without reason)
- [e.g. all HTTP goes through `src/lib/http.ts`, not fetch/axios directly — unified retry + auth]

## Architecture
- [e.g. dependency direction UI → service → repository, never reversed]
- [e.g. accessibility reads stay in the detection layer, not app lifecycle or UI; currently `NativeDialogDetector` — the rule is the boundary, the type is just where it lives now]

## Style (conventions the code can't reveal on its own)
- [e.g. money is always the `Money` type, never a bare number]

## Large constraint sets (split out when big)
- Frontend: see `docs/frontend.md`
- Backend: see `docs/backend.md`
```

## Rules

- **Status is file-level.** Use `confirmed` only when the file contains owner-provided or owner-confirmed content. Use `draft` when material content is inferred from code, inferred from history, or filled in by the model. Missing status means draft.
- **Draft is not binding.** Use draft constraints as review context, not as rules future tasks must obey.
- **A constraint is a durable principle, not the current structure.** Write the boundary, layering, or dependency direction that should survive a refactor. Which type currently does what, and current mechanisms (keybindings, MVP flows, exact UX), are *not* constraints — they're implementation facts. If it wouldn't hold after a reasonable refactor, leave it out.
- **Name the current implementer as evidence, not as the rule.** Write "AX reads stay in the detection layer; currently `NativeDialogDetector`." Not "`NativeDialogDetector` exclusively does AX reads" — that locks the type, so any refactor reads as a violation.
- **Few strong boundaries beat an inventory.** A handful of real layering/dependency/seam rules is worth more than a per-file list of who does what.
- **Give each rule a reason, and cite where it currently lives (`file/path`) as evidence.** A rule the next run can't justify, it won't follow.
- **Rules, not terms or rationale.** A domain term belongs in `CONTEXT.md`; a one-off decision's why belongs in `docs/adr/`; a standing rule belongs here.
- **Split when it grows.** When frontend or backend constraints get long, move them to `docs/frontend.md` / `backend.md` and leave a pointer here.
