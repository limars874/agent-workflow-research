# journal.md Format

`docs/journal.md` is append-only, newest at the bottom. One entry per session or meaningful chunk of work.

## Structure

```md
# Journal

## [2026-07-09] <session title>
- **Did**: <what changed, one or two lines>
- **Decided**: <key decisions + why; "none" if routine>
- **Commit**: <sha, or (none) for planning/review work>
```

## Rules

- **Append, never rewrite.** History stays — this is the opposite of progress.
- **Record decisions and why, not diffs.** git already holds the diffs; the journal holds the reasoning git can't.
- **One entry per wrap point, not per action.** If nothing worth remembering happened, write nothing.
