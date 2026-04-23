# Spec: issue-917 — PM §5k label creation fallback

## Design reference
- **Design doc**: `docs/design/39-autonomous-readme-refresh.md`
- **Section**: `§ Future`
- **Implements**: label creation fallback before README refresh PR open (bug fix)

---

## Zone 1 — Obligations

**O1 — Before `gh pr create` in §5k, verify each required label exists**
The code in `agents/phases/pm.md` §5k (README refresh PR opening) must check
whether each of the labels in `all_labels` exists on the repo before calling
`gh pr create`. If any label does not exist, it must be created (color: `ededed`)
before the PR create call.

**O2 — Label check must be per-label**
The check must iterate each label individually and create only missing ones.
It must not fail if some labels exist and others don't.

**O3 — Label creation failure must be non-fatal**
If `gh label create` fails (e.g. permissions), the code must continue and attempt
the PR create anyway. The label fallback must never block the PR creation.

**O4 — The fix applies only to the §5k README refresh PR labels**
Scope: `kind/docs,priority/low,size/s` (and the PR_LABEL if it's not `otherness`).
The fix does not generalize to other `gh pr create` calls in pm.md — scoped change.

---

## Zone 2 — Implementer's judgment

- Color `ededed` (light gray) is a safe default for auto-created labels.
- The label list to check is `['kind/docs', 'priority/low', 'size/s']` plus
  `PR_LABEL` if non-empty.
- Position: immediately before line `all_labels = f'{PR_LABEL},kind/docs,...'`

---

## Zone 3 — Scoped out

- Label creation for other pm.md PR calls (§5i, §5m, etc.)
- Changing label colors for existing labels
- Creating a generic label-ensuring utility function
