#!/usr/bin/env python3
"""
scripts/calibrate.py — Calibrate simulation parameters against real batch history.

Reads docs/aide/metrics.md, runs a grid search over simulation parameters,
finds the combination that best matches observed behavior, and writes
scripts/sim-params.json.

Usage:
    python3 scripts/calibrate.py
    python3 scripts/calibrate.py --dry-run   # print grid size and exit
    python3 scripts/calibrate.py --metrics path/to/metrics.md
    python3 scripts/calibrate.py --output path/to/sim-params.json
    python3 scripts/calibrate.py --runs 3    # runs per combination (default 5)

See docs/design/11-simulation-feedback-loop.md for design rationale.
"""

import argparse
import datetime
import itertools
import json
import math
import re
import sys
import os


# ---------------------------------------------------------------------------
# Metrics parsing
# ---------------------------------------------------------------------------


def parse_metrics_md(path: str) -> list:
    """Parse docs/aide/metrics.md into a list of batch dicts."""
    rows = []
    try:
        with open(path) as f:
            content = f.read()
    except FileNotFoundError:
        print(f"[calibrate] metrics file not found: {path}", file=sys.stderr)
        return []

    # Table rows: | date | batch | prs | needs_human | nh_rate | skills | items | ...
    pattern = re.compile(
        r"^\|\s*(\d{4}-\d{2}-\d{2})\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|"
        r"\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|",
        re.MULTILINE,
    )
    for m in pattern.finditer(content):
        date, batch, prs, needs_human, nh_rate, skills, items = m.groups()
        rows.append(
            {
                "date": date,
                "batch": int(batch),
                "prs": int(prs),
                "needs_human": int(needs_human),
                "skills": int(skills),
                "items": int(items),
            }
        )

    return rows


def compute_observed_stats(rows: list) -> dict:
    """Compute target statistics from real batch data."""
    if not rows:
        return {}

    valid = [r for r in rows if r["items"] > 0]
    if not valid:
        return {}

    completion_rates = [r["prs"] / r["items"] for r in valid]
    nh_rates = [r["needs_human"] / max(r["items"], 1) for r in valid]

    return {
        "mean_completion_rate": sum(completion_rates) / len(completion_rates),
        "std_completion_rate": _std(completion_rates),
        "mean_nh_rate": sum(nh_rates) / len(nh_rates),
        "n_batches": len(rows),
        "skills_start": rows[0]["skills"],
        "skills_end": rows[-1]["skills"],
        "skills_growth_per_batch": (rows[-1]["skills"] - rows[0]["skills"]) / len(rows),
    }


def _std(values):
    if len(values) < 2:
        return 0.0
    mean = sum(values) / len(values)
    return math.sqrt(sum((x - mean) ** 2 for x in values) / len(values))


# ---------------------------------------------------------------------------
# Grid search
# ---------------------------------------------------------------------------

GRID = {
    "decay_rate": [0.88, 0.90, 0.92, 0.94],
    "jump_multiplier": [1.3, 1.5, 1.6, 1.8, 2.0],
    "skill_boldness_coefficient": [0.010, 0.013, 0.015, 0.018],
}


def build_grid() -> list:
    keys = list(GRID.keys())
    combos = list(itertools.product(*[GRID[k] for k in keys]))
    return [dict(zip(keys, c)) for c in combos]


def run_grid_search(
    observed: dict, n_runs: int = 5, seed: int = 42, n_cycles: int = 100
) -> dict:
    """
    Run simulation grid search. Returns best-fit parameters.
    Imports simulate lazily to avoid circular import.
    """
    # Import simulate from same directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, script_dir)
    from simulate import SimConfig, run_simulation, average_metrics

    target_completion = observed.get("mean_completion_rate", 0.5)
    grid = build_grid()

    best_params = None
    best_rmse = float("inf")
    total = len(grid)

    print(
        f"[calibrate] Grid: {total} combinations × {n_runs} runs × {n_cycles} cycles",
        file=sys.stderr,
    )
    print(
        f"[calibrate] Target completion rate: {target_completion:.4f} "
        f"(from {observed.get('n_batches', 0)} batches)",
        file=sys.stderr,
    )

    for i, combo in enumerate(grid):
        runs = []
        for run_idx in range(n_runs):
            cfg = SimConfig(
                n_agents=4,
                n_cycles=n_cycles,
                seed=seed + run_idx,
                decay_rate=combo["decay_rate"],
                jump_multiplier=combo["jump_multiplier"],
                skill_boldness_coefficient=combo["skill_boldness_coefficient"],
            )
            metrics, _ = run_simulation(cfg)
            runs.append(metrics)

        avg = average_metrics(runs)
        sim_completion = sum(m.completion_rate for m in avg) / len(avg)
        rmse = math.sqrt((sim_completion - target_completion) ** 2)

        if rmse < best_rmse:
            best_rmse = rmse
            best_params = {**combo}

        if (i + 1) % 20 == 0 or i == total - 1:
            print(
                f"[calibrate] Progress: {i + 1}/{total} "
                f"(best RMSE so far: {best_rmse:.4f})",
                file=sys.stderr,
            )

    return best_params, best_rmse


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------


def write_params(params: dict, rmse: float, observed: dict, output_path: str) -> None:
    """Write calibrated parameters to sim-params.json."""
    result = {
        **params,
        "calibrated_at": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
        "source": "otherness-metrics",
        "n_batches": observed.get("n_batches", 0),
        "rmse": round(rmse, 6),
        "observed_completion_rate": round(observed.get("mean_completion_rate", 0), 4),
        "observed_nh_rate": round(observed.get("mean_nh_rate", 0), 4),
        "skills_growth_per_batch": round(observed.get("skills_growth_per_batch", 0), 4),
    }
    with open(output_path, "w") as f:
        json.dump(result, f, indent=2)
    print(f"[calibrate] Written: {output_path}", file=sys.stderr)
    print(json.dumps(result, indent=2))


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def main():
    parser = argparse.ArgumentParser(
        description="Calibrate simulation parameters against real batch history"
    )
    parser.add_argument(
        "--metrics",
        default="docs/aide/metrics.md",
        help="Path to metrics.md (default: docs/aide/metrics.md)",
    )
    parser.add_argument(
        "--output",
        default="scripts/sim-params.json",
        help="Output path (default: scripts/sim-params.json)",
    )
    parser.add_argument(
        "--runs",
        type=int,
        default=5,
        help="Simulation runs per parameter combination (default: 5)",
    )
    parser.add_argument(
        "--cycles",
        type=int,
        default=100,
        help="Simulation cycles per run (default: 100)",
    )
    parser.add_argument(
        "--seed", type=int, default=42, help="Random seed base (default: 42)"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Print grid size and exit"
    )
    args = parser.parse_args()

    grid = build_grid()
    if args.dry_run:
        print(f"Grid size: {len(grid)} combinations")
        print(f"Total runs: {len(grid) * args.runs}")
        print(f"Parameters: {list(GRID.keys())}")
        for k, v in GRID.items():
            print(f"  {k}: {v}")
        return

    # Parse real metrics
    rows = parse_metrics_md(args.metrics)
    if not rows:
        print(
            f"[calibrate] ERROR: no batch data found in {args.metrics}", file=sys.stderr
        )
        sys.exit(1)

    observed = compute_observed_stats(rows)
    print(
        f"[calibrate] Observed stats from {observed['n_batches']} batches:",
        file=sys.stderr,
    )
    for k, v in observed.items():
        if isinstance(v, float):
            print(f"  {k}: {v:.4f}", file=sys.stderr)
        else:
            print(f"  {k}: {v}", file=sys.stderr)

    # Run grid search
    best_params, best_rmse = run_grid_search(
        observed, n_runs=args.runs, seed=args.seed, n_cycles=args.cycles
    )

    print(f"\n[calibrate] Best parameters (RMSE={best_rmse:.6f}):", file=sys.stderr)
    for k, v in best_params.items():
        print(f"  {k}: {v}", file=sys.stderr)

    # Write output
    write_params(best_params, best_rmse, observed, args.output)


if __name__ == "__main__":
    main()
