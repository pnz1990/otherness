# Spec: validate.sh structural hardcoded-path detection

**Issue:** #47
**Size:** XS
**Risk tier:** LOW (scripts/validate.sh)

## Obligations (Zone 1)

1. Check [1/4] must catch any `pnz1990/<X>` reference in agent files where `<X>` is not `otherness`.

2. Check [1/4] must catch bare repo names from the known fleet (`alibi`, `kro-ui`, `kardinal-promoter`) when they appear in a project-reference context (e.g., as part of a repo slug like `repo: alibi`, `/alibi.git`, `pnz1990/alibi`).

3. Check [1/4] must NOT flag references to `pnz1990/otherness` — that is the project itself.

4. Check [1/4] must NOT flag the word `alibi` when it appears in prose that is clearly not a project reference (e.g., "The word alibi means...").

5. All existing passing tests must continue to pass after this change.

## Implementer's judgment (Zone 2)

Whether to implement as pure bash with `grep -E` or a Python script. Bash with `grep -E` is preferred (simpler, no added dependency).

The exact heuristic for "project-reference context" for bare names. Recommended: flag `pnz1990/<name>`, `repo: <name>`, `/<name>.git`, or `/<name>/`. These patterns are unambiguous project references.

## Scoped out (Zone 3)

- This spec does not add checks to `scripts/test.sh` — only `validate.sh` check [1/4].
- This spec does not maintain a fleet registry in the script — the structural pattern is sufficient.

## Implementation

```bash
echo "[1/4] Checking for hardcoded project paths in agent files..."
FOUND=0
for file in "$AGENTS_DIR"/*.md "$AGENTS_DIR/skills"/*.md; do
  [ -f "$file" ] || continue
  # Rule 1: any pnz1990/<X> where X is not 'otherness'
  if grep -qE 'pnz1990/[a-zA-Z0-9_-]+' "$file" 2>/dev/null; then
    # Extract all matches, filter out pnz1990/otherness
    BAD=$(grep -oE 'pnz1990/[a-zA-Z0-9_-]+' "$file" | grep -v '^pnz1990/otherness$' | head -3)
    if [ -n "$BAD" ]; then
      echo "  ERROR: $(basename $file) contains hardcoded project path(s): $BAD"
      FOUND=1
    fi
  fi
  # Rule 2: known fleet repos in project-reference context (bare name)
  for name in alibi kro-ui kardinal-promoter; do
    if grep -qE "(repo:|/)$name(\.git|/|\")" "$file" 2>/dev/null; then
      echo "  ERROR: $(basename $file) contains hardcoded fleet project reference: $name"
      FOUND=1
    fi
  done
done
[ $FOUND -eq 0 ] && echo "  OK: no hardcoded project paths in agent files" || exit 1
```

## Verification

```bash
# Test 1: adding pnz1990/kro-ui to a skill file fails
echo "see pnz1990/kro-ui for an example" >> agents/skills/test-probe.md
bash scripts/validate.sh 2>&1 | grep -q "ERROR" && echo "PASS" || echo "FAIL"
rm agents/skills/test-probe.md

# Test 2: pnz1990/otherness reference is allowed
bash scripts/validate.sh  # must still pass

# Test 3: current passing state still passes
bash scripts/validate.sh && echo "PASS" || echo "FAIL"
```
