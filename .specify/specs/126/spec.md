# Spec: Session Handoff (#126)

## Zone 1 — Obligations (falsifiable)

### O1: Handoff written by SM phase
At the end of every SM batch (`sm.md` §4d or equivalent), the agent writes `.otherness/handoff.md`
in the main repo directory with a structured summary of the session.
- **Violation**: SM phase completes without writing `.otherness/handoff.md`.

### O2: Handoff content
The handoff file must contain at minimum:
- UTC timestamp of when it was written
- PRs merged in the current batch (number + title, from git log or gh pr list)
- Current queue items and their states (from state.json)
- CI status on main
- Next item to work on (first `todo` in state.json)
- **Violation**: File is written but missing any of the above sections.

### O3: Startup reads handoff
`standalone.md` startup block reads `.otherness/handoff.md` if present and echoes its content.
- **Violation**: `standalone.md` does not contain a reference to `handoff.md` in its startup section.

### O4: Handoff committed to main
`.otherness/handoff.md` is committed to main on every write (using pull-rebase-retry pattern, same as metrics.md).
- **Violation**: Handoff exists only locally and is lost on session end without commit.

### O5: Acceptance test passes
```bash
grep -c "handoff.md" ~/.otherness/agents/standalone.md  # ≥ 1
grep -c "handoff" ~/.otherness/agents/phases/sm.md       # ≥ 1
```

---

## Zone 2 — Implementer's judgment

- Exact sections and prose in the handoff file.
- Whether to include worktree list, skill file count, or other diagnostic info.
- Whether to overwrite or append (overwrite is simpler and correct — one handoff = one session).
- How many PRs to show (last 10 is fine).

---

## Zone 3 — Scoped out

- Operator conversation context (what was said in the chat) — agent cannot read that.
- Mid-thought reasoning capture — too expensive and too noisy.
- Per-item detailed history — state.json already has that.
- Handoff for bounded agents — they inherit context from the parent session.
