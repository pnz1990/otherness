# 04: Documentation Health — Continuous Reality Alignment

> Status: Active | Created: 2026-04-17
> Applies to: all projects managed by otherness

---

## What this does

Every design doc and customer-facing doc in a project managed by otherness must
continuously reflect reality: what is shipped, what is coming, and what is no longer
relevant. Stale docs — aspirational claims, deprecated features, `🔲 Future` items
that were silently shipped or silently abandoned — are bugs, not cosmetic issues.

The PM phase runs a periodic documentation health scan that identifies misalignment
between what docs claim and what code delivers. Findings become `kind/docs` issues.

The problem this solves: currently, docs drift in both directions:
- **Forward drift**: code ships a feature but the design doc still shows it as `🔲 Future`
- **Backward drift**: a `🔲 Future` item in a design doc is abandoned or superseded, but
  the item keeps appearing in COORD queue generation as live work
- **Aspirational claims**: README or AGENTS.md make claims about capabilities that aren't
  implemented (see arch-audit findings #198–#205)

This design doc defines the mechanism to detect and fix all three forms of drift
generically, for any project using otherness.

---

## Present (✅)

- ✅ Deprecated marker `🚫` — COORD queue-gen skips `🔲` items containing `🚫` (PR #209, 2026-04-17)
- ✅ Self-seeding check in COORD startup — §1b vision check: opens [NEEDS HUMAN] issue once when docs/aide/vision.md absent, proceeds with empty queue (PR #244, 2026-04-18)
- ✅ Codebase hygiene scan — SM §4g: scans agents/*.md and scripts/*.{sh,py} every 20 SM cycles; files with no design doc coverage get kind/chore issues; duplicate-suppressed; graceful fallback (PR #258, 2026-04-18)
- ✅ PM §5f: periodic doc health scan — Steps 0-5: Present item PR ref check, Future item shipping check, freshness metric (>60d stale); duplicate-suppressed; graceful fallback (PR #287 integration, 2026-04-19)
- ✅ Design doc freshness metric — Step 5 in PM §5f: git log age per design doc, stale docs get kind/docs issue; PR #287 integration, 2026-04-19)
- ✅ Codebase hygiene scan — SM §4g: every 20 cycles, agents/+scripts/ coverage check; PR #287 integration, 2026-04-19)
- ✅ Self-seeding check in COORD startup — §1b vision check gate; PR #244, 2026-04-18)

## Future (🔲)

---

## Zone 1 — Obligations

**O1 — Design doc Present items must have evidence.**
Every `✅ Present` item in a design doc must reference the PR that implemented it, in
the format `(PR #N, YYYY-MM-DD)`. Bare `✅ Present` without a PR reference is a
documentation smell (not a blocker, but flagged by the health scan).

**O2 — Future items not in queue must be explicitly deferred or deprecated.**
A `🔲 Future` item that appears in a design doc but has never been queued as a GitHub
issue — and has sat there for more than 60 days — is flagged for review: is it still
intended? Is it blocked? Should it be `🚫 Deprecated`?

**O3 — COORD skips 🚫 Deprecated items.**
The queue generation regex must not match `🚫 Deprecated` items. They remain in the
design doc for history but are invisible to the work queue.

**O4 — PM health scan runs every N_PM_CYCLES cycles.**
The doc health scan is not a one-time command — it runs periodically as part of the
PM phase, same cadence as product validation.

**O5 — Claims in README and AGENTS.md are verified periodically.**
The health scan is not limited to `docs/design/` — it also checks that architectural
claims in README and AGENTS.md that reference specific mechanisms (files, functions,
commands) are still accurate.

---

## Zone 2 — Implementer's judgment

- How to verify a Present item is implemented: check for its PR reference OR grep for
  a related code symbol or command. Do not require both — one is sufficient.
- How many days before an unqueued Future item is flagged: 60 days is the default.
  Projects with slower velocity may increase this via config.
- Whether to fix docs inline during the health scan or only open issues: open issues
  only. The health scan does not make edits — it surfaces findings for the ENG queue.
- How to detect "silently shipped" Future items: compare Future item descriptions
  (first 60 chars) against merged PR titles, same pattern as `is_done()` in COORD.

---

## Zone 3 — Scoped out

- Automated code analysis (AST parsing, symbol resolution) — prose matching against
  PR titles is sufficient and language-agnostic
- Real-time doc validation on every PR (CI lint) — periodic PM scan is sufficient;
  per-PR validation is too expensive and too noisy
- Retroactively fixing all existing stale docs on first run — health scan surfaces
  findings, fixes are queued as normal work items

---

## Design

### The health scan algorithm (PM §5f)

```python
# For each docs/design/*.md file:
for fname in sorted(os.listdir('docs/design')):
    content = open(f'docs/design/{fname}').read()

    # 1. Check Present items have PR references
    present_items = re.findall(r'^- ✅ (.+)', content, re.MULTILINE)
    for item in present_items:
        if not re.search(r'\(PR #\d+', item):
            open_issue(f"docs: {fname} Present item missing PR reference: {item[:60]}")

    # 2. Check Future items not silently shipped
    future_items = re.findall(r'^- 🔲 (.+)', content, re.MULTILINE)
    for item in future_items:
        desc_key = item[:60].lower().strip()
        if any(desc_key in pr_title.lower() for pr_title in merged_pr_titles):
            open_issue(f"docs: {fname} Future item appears shipped but not marked Present: {item[:60]}")

    # 3. Check for stale Future items (no issue, no activity, >60 days)
    # [implementation detail: check GitHub issues with title matching item description]
```

### The COORD 🚫 Deprecated filter

```python
# In queue generation — extend the Future section regex to exclude Deprecated:
items = re.findall(r'^- 🔲 (?!.*🚫)(.+)', m.group(1), re.MULTILINE)
# Items starting with 🔲 but containing 🚫 are skipped
```

### Cross-checking README/AGENTS.md claims

The arch-audit (2026-04-17) found 6 false claims in README alone. The health scan
should periodically rerun a lightweight version of this check:

```python
# Claims to verify (machine-checkable subset):
# - "validate.sh performs N checks" → count echo "[N/N]" in scripts/validate.sh
# - "ALLOWED_MILESTONES supported" → grep bounded-standalone.md
# - File existence claims: "X.md exists" → os.path.exists(X)
```

### Deprecated marker usage

```markdown
## Future (🔲)

- ✅ Feature A — implemented (PR #42, 2026-01-15)
- 🔲 Feature B — planned next quarter
- 🚫 Feature C — deprecated: replaced by Feature D (see PR #87)
```

COORD queue generator reads `^- 🔲 ` — the `🚫` marker is invisible to it.

---

## Rejected alternatives

**"Run arch-audit on every batch instead of a separate health scan."**
Arch-audit is a deep, adversarial session that takes significant context and time. Doc
health scanning is a lightweight, mechanical check (string matching against PR titles and
file contents). They serve different purposes and should run at different cadences.

**"Require human approval of all design doc changes."**
The health scan opens issues — it does not make changes. The ENG agent implements the
fixes through the normal D4 queue. No additional human gate needed.

**"Store doc health state in state.json."**
The health scan findings are ephemeral observations — they become issues immediately.
There is nothing to persist beyond what GitHub issues already track.
