# constraints.md Format

`docs/agents/constraints.md` holds the project-wide rules every task obeys.

## Structure

```md
# Constraints

## Stack (locked choices — don't swap without reason)
- [e.g. all HTTP goes through `src/lib/http.ts`, not fetch/axios directly — unified retry + auth]

## Architecture
- [e.g. dependency direction UI → service → repository, never reversed]

## Style (conventions the code can't reveal on its own)
- [e.g. money is always the `Money` type, never a bare number]

## Large constraint sets (split out when big)
- Frontend: see `docs/agents/frontend.md`
- Backend: see `docs/agents/backend.md`
```

## Rules

- **Give each rule a reason or a `file/path`.** A rule the next run can't justify, it won't follow.
- **Rules, not terms or rationale.** A domain term belongs in `CONTEXT.md`; a one-off decision's why belongs in `docs/adr/`; a standing rule belongs here.
- **Split when it grows.** When frontend or backend constraints get long, move them to `docs/agents/frontend.md` / `backend.md` and leave a pointer here.
