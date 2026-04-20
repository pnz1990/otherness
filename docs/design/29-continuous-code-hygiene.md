# 29: Continuous Code Hygiene — Dead Code, Stale Files, Stale Docs

> Status: Active | Created: 2026-04-20
> Applies to: otherness itself and all managed projects

---

## The problem this solves

As a project evolves autonomously over many batches, it accumulates:

- **Dead code**: functions, classes, exports that are no longer called
- **Stale docs**: `docs/design/` files with `✅ Present` items that no longer
  match the actual implementation (code was deleted or refactored)
- **Orphaned files**: test fixtures, generated files, commented-out code blocks,
  TODO files that were never converted to issues
- **Duplicate logic**: two implementations of the same utility, both surviving
  because no session ever looked at them together
- **Outdated Future items**: `🔲 Future` design items that describe approaches
  superseded by later design decisions

Left unaddressed, this accumulation creates navigation debt, misleads the vision-
synthesis phase (§4g SM, §5 PM), and causes QA false-passes when spec checks match
stale references.

The fix: **a hygiene scan runs in every SM batch**. It systematically identifies
rot and queues refactor/deprecation items.

---

## The mechanism

### SM §4h (hygiene scan) — runs once per 3 SM cycles

```bash
# Every 3rd SM cycle: run hygiene scan. Post findings as issues.
if [ $((${SM_CYCLE:-0} % 3)) -eq 0 ]; then
  python3 ~/.otherness/agents/skills/hygiene-scan.py 2>/dev/null || \
  python3 - <<'HYGIENE_EOF'
  # inline fallback if skill file not available
  # [inline hygiene scan — see design doc 29]
  HYGIENE_EOF
fi
```

### What the scan checks

**Check 1 — Stale design doc items**

For each `✅ Present` item in `docs/design/*.md`: find the referenced file/function.
If the reference no longer exists in the codebase, mark the item `⚠️ Stale` and
open a hygiene issue.

```python
# Pattern: "✅ <description> — <file>:<function>"
# or: "✅ <description> (PR #N)"
# Check: does the referenced file/function still exist?
```

**Check 2 — Orphaned TODO comments**

Files with `# TODO`, `// TODO`, `/* TODO` older than 14 days (via `git log --follow`).
Queue as `chore/todo-resolve` items.

**Check 3 — Dead export detection (language-aware)**

- Python: functions in `*.py` files not imported anywhere in the repo
- Go: exported functions not referenced outside their package
- TypeScript/JS: exports not imported anywhere

Threshold: flag if a function/export has 0 references and is not a test helper,
main entry point, or interface implementation.

**Check 4 — Stale generated files**

Files in `**/__pycache__/`, `**/dist/`, `**/.next/`, `**/node_modules/` committed
to main. Open issue to add to `.gitignore`.

**Check 5 — Docs/design drift**

Count `docs/design/*.md` files where the `## Present` section has items but the
referenced code path no longer exists. Threshold: flag when >20% of Present items
are unverifiable.

**Check 6 — Stale `🔲 Future` items**

`🔲 Future` items older than 90 days (based on `git log -S "item text"`) that have
no corresponding open issue and no recent commit touching the related file. Flag for
PM review or automatic demotion to `⚠️ Superseded`.

### Issue format

```
[hygiene] <check>: <description>
Labels: kind/chore, area/<domain>, priority/low, size/xs
Body:
  Found by: SM §4h hygiene scan (batch N)
  Check: <check number and name>
  Location: <file:line or design doc section>
  Action: <specific refactor/delete/update instruction>
```

### Prioritization

Hygiene items are `priority/low` and `size/xs` by default. They enter the queue
with lower priority than `priority/high` feature items. COORD §1c routes them
to avoid blocking the feature queue:

- **Allowed**: when queue has ≥5 feature items and no CRITICAL items in_review
- **Preferred**: when queue depth < 3 (hygiene items are easy wins that keep
  throughput up during slow periods)

---

## Integration with vibe-vision (design doc 28)

The vibe-vision Step A in the dual-step workflow (doc 28) performs a subset of the
hygiene scan — specifically Check 1 (stale design doc items) and Check 6 (stale
Future items). This is intentional: vision quality depends on keeping design docs
accurate, so vision already owns doc hygiene.

SM §4h hygiene scan owns code hygiene (Checks 2–5) and is complementary, not
duplicative.

---

## Safety rules

**Never delete files autonomously.** The hygiene scan opens issues. The ENG phase
implements the deletion as a tracked item, with QA approval and a squash merge.

**Never modify `docs/aide/` or `docs/design/` vision layers** in the hygiene
scan. Those are Step A (vibe-vision) territory.

**Cap at 3 new hygiene issues per scan.** Prevents queue flooding when the scan
runs on a project with high accumulated debt. Issues accumulate over time;
the team works them down organically.

---

## Config flag: `hygiene.enabled`

```yaml
hygiene:
  enabled: true         # default: true
  max_issues_per_scan: 3
  cycle_interval: 3     # run every N SM cycles
  checks:               # omit to run all checks
    - stale_design_docs
    - orphaned_todos
    - dead_exports
    - stale_generated
    - stale_future_items
```

---

## Present (✅)

- ✅ Design doc created (this file) (2026-04-20)
- ✅ `agents/phases/sm.md §4g` (formerly §4h): hygiene scan block implemented — executable Python, not [AI-STEP]; 3 check categories (stale design doc refs, unresolved TODO/FIXME/HACK, build artifacts); cap at `max_issues_per_scan`; `priority/low` labels (PR #441, 2026-04-20)

## Future (🔲)

- 🔲 `agents/skills/hygiene-scan.py`: standalone Python script implementing all 5 checks
- 🔲 `otherness-config-template.yaml`: add `hygiene:` section with commented defaults
- 🔲 `agents/phases/coord.md §1b`: route hygiene items with lower priority than features
- 🔲 Roll out hygiene config to all managed projects (alibi, kardinal-promoter, kro-ui)

---

## Zone 1 — Obligations

**O1 — Hygiene scan never deletes or modifies code directly.**
It opens issues only. Implementation is via the normal COORD→ENG→QA loop.

**O2 — Cap at `max_issues_per_scan` new issues per run.**
Default 3. Prevents queue flooding on high-debt projects.

**O3 — Hygiene items are always `priority/low`.**
They must never preempt `priority/high` or `priority/critical` items.

**O4 — Check 1 (stale design docs) and Check 6 (stale Future) are owned by vibe-vision.**
SM §4h must not re-run these checks. Duplication creates conflicting issue titles.

---

## Zone 2 — Implementer's judgment

- Dead export detection depth: start with direct imports only (not transitive).
  Transitive analysis is expensive and error-prone. Flag "0 direct imports" as
  a candidate for human review, not automatic deletion.
- Language detection: read file extensions, not shebang lines. Go = `.go`,
  Python = `.py`, TypeScript = `.ts`/`.tsx`, JavaScript = `.js`/`.jsx`.
- Cross-language projects: hygiene scan runs all applicable checks based on
  detected languages. A full-stack project (Go + TypeScript) runs both.

---

## Zone 3 — Scoped out

- Automated dead code elimination (only issue creation is in scope)
- Semantic similarity deduplication (finding duplicate logic algorithmically)
- Integration with external static analysis tools (pylint, golangci-lint run separately)
- Real-time hygiene (checking on every PR) — this is batch-level only
