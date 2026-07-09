---
name: flow-reflect
description: Record a lesson. Use when a fix took 2+ verification loops, debugging ran past 3 attempts, you changed approach mid-task, or the user corrected a wrong assumption.
---

# Record a lesson

A **lesson** is abstract guidance the next run applies — a rule, not a snippet. Write what to do differently, in a line or two; a concrete code template anchors the next agent on the wrong details.

1. State the lesson as guidance the next run would follow. One idea, ≤2 lines.
   - Done when a fresh agent, reading that line alone, knows what to do differently — with no code to copy.
2. Append it to `docs/learnings.md`:
   `- [<date>] <lesson> — context: <what worked / what failed, one clause>`
3. If the lesson is stable and worth making a hard rule, propose graduating it: draft it as a constraint, show the owner, and add it to `docs/constraints.md` only on their confirmation — so `constraints.md` stays owner-confirmed and binding. Until confirmed, the lesson stays in `learnings.md` and is applied as guidance, not as a binding rule. A one-off stays in learnings.

Record only lessons worth the next run's attention — a surprise that cost real time, not a routine step.
