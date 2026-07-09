<!-- Project constraints — the rules every task obeys (what mattpocock's suite lacks).
     Put rules that aren't obvious from the code: locked stack, architecture rules, style conventions.
     Not terms (those go in CONTEXT.md), not one-off decision rationale (those go in docs/adr/).
     When it grows, split frontend/backend into docs/agents/frontend.md, backend.md and point here.
     Give each rule a "why" or a `file/path` as evidence. -->

# Constraints

## Stack (locked choices — don't swap without reason)
- [e.g. all HTTP goes through `src/lib/http.ts`, not fetch/axios directly — unified retry + auth]

## Architecture
- [e.g. dependency direction UI → service → repository, never reversed; cross-module only via `src/<mod>/index.ts`]

## Style (the conventions the code can't reveal on its own)
- [e.g. money is always the `Money` type, never a bare number; time is always UTC ISO]

## Large constraint sets (split out when big)
- Frontend: see `docs/agents/frontend.md`
- Backend: see `docs/agents/backend.md`
