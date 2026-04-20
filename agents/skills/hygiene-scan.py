#!/usr/bin/env python3
"""
hygiene-scan.py — Standalone Python script implementing all 5 code hygiene checks.

Design ref: docs/design/29-continuous-code-hygiene.md

Usage:
  python3 agents/skills/hygiene-scan.py [--max-issues N] [--repo REPO] [--label LABEL]

Checks implemented (per design doc §What the scan checks):
  Check 2: Orphaned TODO/FIXME/HACK comments (>14 days old)
  Check 3: Dead export detection (Python, Go, TypeScript/JS — basic, not transitive)
  Check 4: Stale generated files committed to repo
  Check 5: Docs/design drift — Present items with unverifiable references

Checks 1 and 6 (stale design doc items, stale Future items) are owned by vibe-vision.
This script does NOT run those checks.

Output: prints hygiene findings to stdout. Caller (SM §4g) opens issues via gh CLI.
"""

import re
import os
import sys
import subprocess
import json
import datetime
import argparse


# ── Configuration ────────────────────────────────────────────────────────────

def get_config():
    """Read hygiene config from otherness-config.yaml. Return defaults if missing."""
    config = {
        'max_issues': 3,
        'enabled': True,
        'cycle_interval': 3,
    }
    try:
        section = None
        for line in open('otherness-config.yaml'):
            s = re.match(r'^(\w[\w_]*):', line)
            if s:
                section = s.group(1)
            if section == 'hygiene':
                m = re.match(r'\s+max_issues_per_scan:\s*(\d+)', line)
                if m:
                    config['max_issues'] = int(m.group(1))
                m = re.match(r'\s+enabled:\s*(true|false)', line)
                if m:
                    config['enabled'] = m.group(1) == 'true'
    except Exception:
        pass
    return config


# ── Issue deduplication ───────────────────────────────────────────────────────

def issue_exists(repo, title_frag):
    """Check if a hygiene issue with this title fragment already exists."""
    try:
        r = subprocess.run(
            ['gh', 'issue', 'list', '--repo', repo, '--state', 'all',
             '--search', title_frag[:60], '--json', 'number'],
            capture_output=True, text=True, timeout=10)
        return len(json.loads(r.stdout)) > 0
    except Exception:
        return True  # safe default: assume exists


def open_issue(repo, title, body, label):
    """Open a hygiene issue. Return issue number or None."""
    try:
        r = subprocess.run(
            ['gh', 'issue', 'create', '--repo', repo,
             '--title', title, '--label', label, '--body', body],
            capture_output=True, text=True, timeout=15)
        if r.returncode == 0:
            return r.stdout.strip().split('/')[-1]
    except Exception:
        pass
    return None


# ── Check 2: Orphaned TODO/FIXME/HACK comments ───────────────────────────────

TODO_PATTERN = re.compile(
    r'(?:^|\s)(?:#|//|/\*)\s*(TODO|FIXME|HACK)\b',
    re.IGNORECASE
)
TODO_STALE_DAYS = 14
TODO_MAX_FILES = 50


def check_orphaned_todos(repo, max_issues, label, findings):
    """Check 2: find TODO/FIXME/HACK comments older than 14 days."""
    try:
        # Find files with TODO comments (limit scope)
        result = subprocess.run(
            ['git', 'grep', '-l', '-E', r'(TODO|FIXME|HACK)', '--',
             '*.py', '*.go', '*.ts', '*.tsx', '*.js', '*.jsx'],
            capture_output=True, text=True, timeout=15)
        files_with_todos = result.stdout.strip().splitlines()[:TODO_MAX_FILES]
    except Exception:
        return

    now = datetime.datetime.utcnow()
    found = 0

    for fpath in files_with_todos:
        if len(findings) + found >= max_issues:
            break
        if not os.path.exists(fpath):
            continue
        try:
            content = open(fpath).read()
            lines = content.splitlines()
            for lineno, line in enumerate(lines, 1):
                if len(findings) + found >= max_issues:
                    break
                if not TODO_PATTERN.search(line):
                    continue
                # Get age via git log
                try:
                    log_result = subprocess.run(
                        ['git', 'log', '-1', '--format=%ci', '-L',
                         f'{lineno},{lineno}:{fpath}'],
                        capture_output=True, text=True, timeout=8)
                    date_str = log_result.stdout.strip().split('\n')[-1].strip()
                    if date_str:
                        commit_date = datetime.datetime.fromisoformat(
                            date_str.split(' ')[0])
                        age_days = (now.date() - commit_date.date()).days
                    else:
                        age_days = 0
                except Exception:
                    age_days = 0

                if age_days >= TODO_STALE_DAYS:
                    kind = 'TODO'
                    for k in ('FIXME', 'HACK', 'TODO'):
                        if k.lower() in line.lower():
                            kind = k
                            break
                    findings.append({
                        'check': 2,
                        'title': f'hygiene: unresolved {kind} in {os.path.basename(fpath)}:{lineno}',
                        'body': (
                            f'SM §4g hygiene: `{fpath}:{lineno}` has an unresolved '
                            f'{kind} comment ({age_days} days old).\n\n'
                            f'```\n{line.strip()[:120]}\n```\n\n'
                            f'**Action**: Resolve, convert to an issue, or delete.\n'
                            f'Design ref: `docs/design/29-continuous-code-hygiene.md §Check 2`.'
                        ),
                    })
                    found += 1
        except Exception:
            continue


# ── Check 3: Dead export detection (basic, Python/Go/TypeScript) ──────────────

DEAD_EXPORT_MAX = 30
DEAD_EXPORT_SKIP_PREFIXES = ('test', 'Test', 'main', 'Main', '__', '_')


def check_dead_exports(repo, max_issues, label, findings):
    """Check 3: detect exports with 0 direct imports in same repo (surface only)."""
    if len(findings) >= max_issues:
        return

    # Detect repo language from file counts
    py_count = len(subprocess.run(['git', 'ls-files', '--', '*.py'],
                                   capture_output=True, text=True).stdout.splitlines())
    go_count = len(subprocess.run(['git', 'ls-files', '--', '*.go'],
                                   capture_output=True, text=True).stdout.splitlines())
    ts_count = len(subprocess.run(['git', 'ls-files', '--', '*.ts', '*.tsx'],
                                   capture_output=True, text=True).stdout.splitlines())

    # Only run for the dominant language to avoid false positives
    dominant = max([('python', py_count), ('go', go_count), ('typescript', ts_count)],
                   key=lambda x: x[1])
    if dominant[1] == 0:
        return

    lang, _ = dominant

    if lang == 'python':
        _check_dead_python_exports(max_issues, findings)
    elif lang == 'go':
        _check_dead_go_exports(max_issues, findings)
    elif lang == 'typescript':
        _check_dead_ts_exports(max_issues, findings)


def _check_dead_python_exports(max_issues, findings):
    """Check Python functions with no imports detected via git grep."""
    try:
        py_files = subprocess.run(['git', 'ls-files', '--', '*.py'],
                                   capture_output=True, text=True).stdout.splitlines()
        checked = 0
        for fpath in py_files[:DEAD_EXPORT_MAX]:
            if len(findings) >= max_issues:
                break
            if not os.path.exists(fpath) or 'test' in fpath.lower():
                continue
            try:
                content = open(fpath).read()
                # Find top-level function definitions
                for m in re.finditer(r'^def (\w+)\(', content, re.MULTILINE):
                    fname = m.group(1)
                    if fname.startswith(DEAD_EXPORT_SKIP_PREFIXES):
                        continue
                    if len(findings) >= max_issues:
                        break
                    # Count imports in rest of repo
                    ref_result = subprocess.run(
                        ['git', 'grep', '-l', fname, '--', '*.py'],
                        capture_output=True, text=True, timeout=8)
                    refs = ref_result.stdout.strip().splitlines()
                    # Subtract the defining file itself
                    refs = [r for r in refs if r != fpath]
                    if len(refs) == 0:
                        findings.append({
                            'check': 3,
                            'title': f'hygiene: possible dead export `{fname}` in {os.path.basename(fpath)}',
                            'body': (
                                f'SM §4g hygiene: `{fpath}` defines `{fname}` but 0 '
                                f'other `.py` files import it.\n\n'
                                f'**Action**: Verify if this function is still used. '
                                f'If not: remove or add a `# used by external caller` comment.\n'
                                f'Note: this is a surface-level check (not transitive).\n'
                                f'Design ref: `docs/design/29-continuous-code-hygiene.md §Check 3`.'
                            ),
                        })
                    checked += 1
                    if checked > 50:
                        break
            except Exception:
                continue
    except Exception:
        pass


def _check_dead_go_exports(max_issues, findings):
    """Check Go exported functions with no references."""
    try:
        go_files = subprocess.run(['git', 'ls-files', '--', '*.go'],
                                   capture_output=True, text=True).stdout.splitlines()
        for fpath in go_files[:DEAD_EXPORT_MAX]:
            if len(findings) >= max_issues:
                break
            if not os.path.exists(fpath) or '_test.go' in fpath:
                continue
            try:
                content = open(fpath).read()
                for m in re.finditer(r'^func ([A-Z]\w+)\(', content, re.MULTILINE):
                    fname = m.group(1)
                    if len(findings) >= max_issues:
                        break
                    ref_result = subprocess.run(
                        ['git', 'grep', '-l', fname, '--', '*.go'],
                        capture_output=True, text=True, timeout=8)
                    refs = [r for r in ref_result.stdout.strip().splitlines()
                            if r != fpath and '_test.go' not in r]
                    if len(refs) == 0:
                        findings.append({
                            'check': 3,
                            'title': f'hygiene: possible dead export `{fname}` in {os.path.basename(fpath)}',
                            'body': (
                                f'SM §4g hygiene: `{fpath}` exports `{fname}` but 0 '
                                f'other non-test `.go` files reference it.\n\n'
                                f'**Action**: Verify if exported. If unexported: lowercase the name.\n'
                                f'Design ref: `docs/design/29-continuous-code-hygiene.md §Check 3`.'
                            ),
                        })
            except Exception:
                continue
    except Exception:
        pass


def _check_dead_ts_exports(max_issues, findings):
    """Check TypeScript exports with no imports."""
    try:
        ts_files = subprocess.run(['git', 'ls-files', '--', '*.ts', '*.tsx'],
                                   capture_output=True, text=True).stdout.splitlines()
        for fpath in ts_files[:DEAD_EXPORT_MAX]:
            if len(findings) >= max_issues:
                break
            if not os.path.exists(fpath) or '.test.' in fpath or '.spec.' in fpath:
                continue
            try:
                content = open(fpath).read()
                for m in re.finditer(r'^export\s+(?:function|const|class|type|interface)\s+(\w+)',
                                     content, re.MULTILINE):
                    fname = m.group(1)
                    if fname.startswith(DEAD_EXPORT_SKIP_PREFIXES):
                        continue
                    if len(findings) >= max_issues:
                        break
                    ref_result = subprocess.run(
                        ['git', 'grep', '-l', fname, '--', '*.ts', '*.tsx', '*.js', '*.jsx'],
                        capture_output=True, text=True, timeout=8)
                    refs = [r for r in ref_result.stdout.strip().splitlines()
                            if r != fpath and '.test.' not in r and '.spec.' not in r]
                    if len(refs) == 0:
                        findings.append({
                            'check': 3,
                            'title': f'hygiene: possible dead export `{fname}` in {os.path.basename(fpath)}',
                            'body': (
                                f'SM §4g hygiene: `{fpath}` exports `{fname}` but 0 '
                                f'other files import it.\n\n'
                                f'**Action**: Remove the export or verify it is used.\n'
                                f'Design ref: `docs/design/29-continuous-code-hygiene.md §Check 3`.'
                            ),
                        })
            except Exception:
                continue
    except Exception:
        pass


# ── Check 4: Stale generated files ───────────────────────────────────────────

GENERATED_PATTERNS = [
    ('**/__pycache__/', 'Python bytecode cache'),
    ('**/dist/', 'build artifact directory'),
    ('**/.next/', 'Next.js build output'),
    ('**/node_modules/', 'npm dependencies'),
    ('**/*.pyc', 'Python bytecode file'),
    ('**/*.pyo', 'Python optimized bytecode'),
    ('**/vendor/', 'vendored dependencies'),
]


def check_stale_generated_files(repo, max_issues, label, findings):
    """Check 4: find committed build artifacts that should be in .gitignore."""
    if len(findings) >= max_issues:
        return

    # Read .gitignore entries
    gitignore_patterns = set()
    try:
        for line in open('.gitignore'):
            line = line.strip()
            if line and not line.startswith('#'):
                gitignore_patterns.add(line)
    except Exception:
        pass

    try:
        tracked = subprocess.run(['git', 'ls-files'],
                                  capture_output=True, text=True).stdout.splitlines()
    except Exception:
        return

    for pattern, desc in GENERATED_PATTERNS:
        if len(findings) >= max_issues:
            break
        clean_pattern = pattern.replace('**/', '').replace('/', '').replace('*', '')
        # Check if any tracked file matches this pattern
        matching = [f for f in tracked if clean_pattern in f and len(clean_pattern) > 2]
        if matching:
            # Check if already in .gitignore
            if any(clean_pattern in p for p in gitignore_patterns):
                continue
            findings.append({
                'check': 4,
                'title': f'hygiene: build artifact committed — {clean_pattern} should be in .gitignore',
                'body': (
                    f'SM §4g hygiene: found committed build artifact matching `{pattern}` ({desc}).\n\n'
                    f'Example: `{matching[0]}`\n\n'
                    f'**Action**: Add `{pattern}` to `.gitignore` and remove committed artifacts.\n'
                    f'Design ref: `docs/design/29-continuous-code-hygiene.md §Check 4`.'
                ),
            })


# ── Check 5: Docs/design drift ────────────────────────────────────────────────

def check_design_drift(repo, max_issues, label, findings):
    """Check 5: find Present items in design docs with unverifiable references."""
    if len(findings) >= max_issues:
        return

    design_dir = 'docs/design'
    if not os.path.isdir(design_dir):
        return

    # Build set of tracked files
    try:
        tracked = set(subprocess.run(['git', 'ls-files'],
                                      capture_output=True, text=True).stdout.splitlines())
    except Exception:
        tracked = set()

    unverifiable = 0
    total_present = 0

    for fname in sorted(os.listdir(design_dir)):
        if not fname.endswith('.md'):
            continue
        try:
            content = open(f'{design_dir}/{fname}').read()
            m = re.search(r'^## Present.*?\n(.*?)(?=^## |\Z)', content,
                          re.MULTILINE | re.DOTALL)
            if not m:
                continue
            present_items = re.findall(r'^- ✅ (.+)', m.group(1), re.MULTILINE)
            for item in present_items:
                total_present += 1
                # Look for file references in the item text
                file_refs = re.findall(r'`([^`]+\.[a-z]{1,5}[^`]*)`', item)
                for fref in file_refs:
                    # Strip function signatures, keep path
                    fpath = fref.split('(')[0].split('#')[0].strip()
                    if '/' in fpath or '.' in fpath:
                        if fpath not in tracked and not os.path.exists(fpath):
                            unverifiable += 1
                            break
        except Exception:
            continue

    if total_present > 0 and unverifiable / total_present > 0.20:
        findings.append({
            'check': 5,
            'title': f'hygiene: design doc drift — {unverifiable}/{total_present} Present items unverifiable',
            'body': (
                f'SM §4g hygiene: {unverifiable} out of {total_present} ✅ Present items '
                f'in `docs/design/` reference files that no longer exist in the repo.\n\n'
                f'**Action**: Run `agents/skills/hygiene-scan.py` locally to identify specific '
                f'items, then update design docs to match current state.\n'
                f'Design ref: `docs/design/29-continuous-code-hygiene.md §Check 5`.'
            ),
        })


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description='otherness hygiene scan')
    parser.add_argument('--max-issues', type=int, default=None)
    parser.add_argument('--repo', default=os.environ.get('REPO', ''))
    parser.add_argument('--label', default='kind/chore,priority/low,area/tooling')
    parser.add_argument('--dry-run', action='store_true',
                        help='Print findings but do not open issues')
    args = parser.parse_args()

    config = get_config()
    max_issues = args.max_issues if args.max_issues is not None else config['max_issues']
    repo = args.repo
    label = args.label

    if not config['enabled']:
        print('[hygiene-scan] Disabled in otherness-config.yaml — skipping.')
        return

    findings = []

    print('[hygiene-scan] Check 2: orphaned TODO/FIXME/HACK comments...')
    check_orphaned_todos(repo, max_issues, label, findings)

    print('[hygiene-scan] Check 3: dead export detection...')
    check_dead_exports(repo, max_issues, label, findings)

    print('[hygiene-scan] Check 4: stale generated files...')
    check_stale_generated_files(repo, max_issues, label, findings)

    print('[hygiene-scan] Check 5: docs/design drift...')
    check_design_drift(repo, max_issues, label, findings)

    print(f'[hygiene-scan] Found {len(findings)} findings (max: {max_issues}).')

    issues_opened = 0
    for finding in findings[:max_issues]:
        title = finding['title']
        body = finding['body']

        print(f'  Check {finding["check"]}: {title[:70]}')

        if args.dry_run:
            print('    [dry-run] would open issue')
            continue

        if not repo:
            print('    [skip] no REPO configured')
            continue

        if issue_exists(repo, title[:40]):
            print('    [skip] already exists')
            continue

        num = open_issue(repo, title, body, label)
        if num:
            print(f'    Opened issue #{num}')
            issues_opened += 1

    print(f'[hygiene-scan] Done: {issues_opened} issues opened.')


if __name__ == '__main__':
    main()
