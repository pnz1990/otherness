# Design Doc Marker Conventions

> Status: Active | Created: 2026-04-19
> Applies to: all design docs across all otherness-managed projects

This is a reference document. It is not a feature doc — it defines the vocabulary
used in all `docs/design/` files.

---

## The four markers

| Marker | Meaning | Who sets it | COORD queue behavior |
|---|---|---|---|
| `✅ Present` | Feature is shipped, intentional, and documented with a PR reference | ENG (on merge) | Skipped — already done |
| `🔲 Future` | Feature is planned and scoped; ready for implementation | Human or PM | **Queued** — becomes a GitHub issue |
| `⚠️ Inferred` | Feature gap identified by PM from competitive analysis; human has not reviewed | PM §5c | Queued — same as 🔲, but flagged for human review |
| `⚠️ Observed` | Feature found in code with no design doc coverage; human should confirm or deprecate | PM §5h | Queued as kind/docs — human confirms intent |

---

## Usage examples

### ✅ Present
```markdown
- ✅ Feature name — short description (PR #42, YYYY-MM-DD)
```
Every ✅ must have a PR reference. A ✅ without `(PR #N` is flagged by PM §5f.

### 🔲 Future
```markdown
- 🔲 Feature name — why it matters and what correct looks like
```
This is the standard queue input. COORD generates an issue from this line.

### ⚠️ Inferred (PM §5c competitive observation)
```markdown
- 🔲 ⚠️ Inferred: feature name — competitor X has this, we do not. (PM §5c, YYYY-MM-DD)
```
Same syntax as 🔲 (so COORD queues it). The `⚠️ Inferred` prefix flags it for human
review before the next vibe-vision session. The human can confirm, reshape, or remove.

### ⚠️ Observed (PM §5h emergent pattern)
```markdown
- 🔲 ⚠️ Observed: feature name — shipped in PR #N but no design doc coverage. (PM §5h, YYYY-MM-DD)
```
Same syntax as 🔲. COORD queues it as a kind/docs issue asking the human to document
the intent or deprecate the feature.

### 🚫 Deprecated
```markdown
- 🚫 Feature name — deprecated: replaced by Feature Y (PR #N, YYYY-MM-DD)
```
COORD skips all 🚫 items. They remain for history.

---

## Present (✅)

- ✅ ✅/🔲 markers — original design doc vocabulary (introduced in Stage 3, 2026-04-14)
- ✅ 🚫 Deprecated marker — COORD queue-gen skips deprecated items (PR #209, 2026-04-17)
- ✅ ⚠️ Inferred marker — PM §5c writes competitive gap stubs with this prefix (PR #307-310, 2026-04-19)
- ✅ ⚠️ Observed marker — PM §5h writes emergent pattern stubs with this prefix (PR #307-310, 2026-04-19)

## Future (🔲)

*(All marker conventions defined. Future refinements should be opened as new issues.)*
