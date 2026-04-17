# Spec: validate.sh structural hardcoded-path detection

**Issue:** #47
**Size:** XS
**Risk tier:** LOW (scripts/validate.sh)

## Obligations (Zone 1)

1. Check [1/4] must catch any `<owner>/<X>` reference in agent files where `<X>` is not `otherness`, where `<owner>` is read from `otherness-config.yaml project.repo`.

2. Check [1/4] must catch bare repo names from the configured fleet (`monitor.projects`) when they appear in a project-reference context (e.g., as part of a repo slug like `repo: my-project`, `/my-project.git`, `owner/my-project`).

3. Check [1/4] must NOT flag references to `<owner>/otherness` — that is the project itself.

4. Check [1/4] must NOT flag project names when they appear in prose that is clearly not a project reference.

5. All existing passing tests must continue to pass after this change.

## Implementer's judgment (Zone 2)

Whether to implement as pure bash with `grep -E` or a Python script. Bash with `grep -E` is preferred (simpler, no added dependency).

The exact heuristic for "project-reference context" for bare names. Recommended: flag `pnz1990/<name>`, `repo: <name>`, `/<name>.git`, or `/<name>/`. These patterns are unambiguous project references.

## Scoped out (Zone 3)

- This spec does not add checks to `scripts/test.sh` — only `validate.sh` check [1/4].
- This spec does not maintain a fleet registry in the script — the structural pattern is sufficient.

## Implementation

Note: The actual implementation reads `<owner>` and fleet names from `otherness-config.yaml` dynamically. See `scripts/validate.sh` for the shipped implementation. The snippet below shows the conceptual structure:

```bash
echo "[1/4] Checking for hardcoded project paths in agent files..."
# OWNER and FLEET_NAMES are read from otherness-config.yaml at runtime
FOUND=0
for file in "$AGENTS_DIR"/*.md "$AGENTS_DIR/skills"/*.md; do
  [ -f "$file" ] || continue
  # Rule 1: any <owner>/<X> where X is not 'otherness'
  if grep -qE "${OWNER}/[a-zA-Z0-9_-]+" "$file" 2>/dev/null; then
    BAD=$(grep -oE "${OWNER}/[a-zA-Z0-9_-]+" "$file" | grep -v "^${OWNER}/otherness$" | head -3)
    if [ -n "$BAD" ]; then
      echo "  ERROR: $(basename $file) contains hardcoded project path(s): $BAD"
      FOUND=1
    fi
  fi
  # Rule 2: fleet project names in project-reference context (bare name)
  for name in $FLEET_NAMES; do
    if grep -qE "(repo:|/)${name}(\.git|/|\")" "$file" 2>/dev/null; then
      echo "  ERROR: $(basename $file) contains hardcoded fleet project reference: $name"
      FOUND=1
    fi
  done
done
[ $FOUND -eq 0 ] && echo "  OK: no hardcoded project paths in agent files" || exit 1
```

## Verification

```bash
# Test 1: adding <owner>/<project> to a skill file fails
# (replace <owner> and <project> with values from your otherness-config.yaml)
echo "see <owner>/<project> for an example" >> agents/skills/test-probe.md
bash scripts/validate.sh 2>&1 | grep -q "ERROR" && echo "PASS" || echo "FAIL"
rm agents/skills/test-probe.md

# Test 2: <owner>/otherness reference is allowed
bash scripts/validate.sh  # must still pass

# Test 3: current passing state still passes
bash scripts/validate.sh && echo "PASS" || echo "FAIL"
```

---

## Design reference
- N/A — pre-DDDD item (written before design doc system, PR #144)
