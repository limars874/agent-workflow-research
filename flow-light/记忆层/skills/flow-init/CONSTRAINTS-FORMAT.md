# constraints.md Format

`docs/constraints.md` holds project-wide rules. It starts as a draft and becomes binding only after owner confirmation.

## Structure

```md
# Constraints

> Status: draft
> Owner confirmation required before this document is binding.

## Stack (locked choices — don't swap without reason)
- [e.g. all HTTP goes through `src/lib/http.ts`, not fetch/axios directly — unified retry + auth]

## Architecture
- [e.g. dependency direction UI → service → repository, never reversed]

## Style (conventions the code can't reveal on its own)
- [e.g. money is always the `Money` type, never a bare number]

## Large constraint sets (split out when big)
- Frontend: see `docs/frontend.md`
- Backend: see `docs/backend.md`
```

## Rules

- **Status is file-level.** New files start as `draft`; change to `confirmed` only after the owner reviews and accepts the whole document. Missing status means draft.
- **Draft is not binding.** Use draft constraints as review context, not as rules future tasks must obey.
- **Give each rule a reason or a `file/path`.** A rule the next run can't justify, it won't follow.
- **Rules, not terms or rationale.** A domain term belongs in `CONTEXT.md`; a one-off decision's why belongs in `docs/adr/`; a standing rule belongs here.
- **Split when it grows.** When frontend or backend constraints get long, move them to `docs/frontend.md` / `backend.md` and leave a pointer here.
