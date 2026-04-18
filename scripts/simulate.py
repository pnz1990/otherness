#!/usr/bin/env python3
"""
scripts/simulate.py — Multi-agent boldness simulation
Implements docs/design/10-multi-agent-simulation.md

Usage:
    python3 scripts/simulate.py
    python3 scripts/simulate.py --n-agents 8 --cycles 200 --runs 50
    python3 scripts/simulate.py --falsify force3
    python3 scripts/simulate.py --optimal-n

See docs/design/10-multi-agent-simulation.md for model details.
"""

import argparse
import math
import random
import sys
from dataclasses import dataclass, field
from typing import List, Optional, Tuple


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------


@dataclass
class SimConfig:
    n_agents: int = 4
    n_cycles: int = 200
    n_runs: int = 50
    seed: int = 42

    # Force 1: decay after each ship
    decay_rate: float = 0.92
    # Force 2: skill growth lift
    skill_boldness_coefficient: float = 0.02
    # Force 3: Type B failure jump
    jump_multiplier: float = 1.6
    jump_base: float = 0.15

    # Execution
    falsification_sensitivity: float = 0.3
    base_falsification_rate: float = 0.15

    # Monoculture
    monoculture_rate: float = 0.08

    # Human engagement
    human_engagement_rate: float = 0.7
    anomaly_threshold: float = 0.15
    boldness_floor: float = 0.10

    # Disable forces (for --falsify mode)
    disable_force1: bool = False  # decay
    disable_force2: bool = False  # skill growth
    disable_force3: bool = False  # Type B jumps


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------


@dataclass
class AgentState:
    id: int
    boldness: float = 0.5
    skill_count: int = 3
    local_skill_ids: List[int] = field(default_factory=list)
    type_b_count: int = 0
    type_a_count: int = 0
    ships: int = 0


@dataclass
class SystemState:
    t: int = 0
    agents: List[AgentState] = field(default_factory=list)
    shared_skill_ids: List[int] = field(default_factory=list)
    anomaly_count: int = 0
    inflection_points_fired: int = 0
    inflection_points_declined: int = 0
    next_skill_id: int = 100


# ---------------------------------------------------------------------------
# Metrics collected per cycle
# ---------------------------------------------------------------------------


@dataclass
class CycleMetrics:
    t: int
    vision_boldness: float  # mean agent boldness
    skill_diversity: float  # normalised diversity across agents
    type_b_rate: float  # Type B events this cycle / n_agents
    completion_rate: float  # ships this cycle / n_agents
    anomaly_density: float  # cumulative anomalies / (t+1)


# ---------------------------------------------------------------------------
# Simulation core
# ---------------------------------------------------------------------------


def _sigmoid(x: float) -> float:
    try:
        return 1.0 / (1.0 + math.exp(-x))
    except OverflowError:
        return 0.0 if x < 0 else 1.0


def _skill_diversity(agents: List[AgentState]) -> float:
    """Fraction of skills that are NOT shared by all agents (0=monoculture, 1=fully diverse)."""
    if len(agents) < 2:
        return 1.0
    all_skills: set = set()
    for a in agents:
        all_skills.update(a.local_skill_ids)
    if not all_skills:
        return 1.0
    skill_counts = {
        s: sum(1 for a in agents if s in a.local_skill_ids) for s in all_skills
    }
    shared_all = sum(1 for c in skill_counts.values() if c == len(agents))
    return 1.0 - (shared_all / len(all_skills))


def run_simulation(cfg: SimConfig) -> List[CycleMetrics]:
    """Run one simulation instance; return per-cycle metrics."""
    rng = random.Random(cfg.seed)

    # Initialise system
    state = SystemState()
    state.agents = [
        AgentState(
            id=i,
            boldness=0.5,
            skill_count=3,
            local_skill_ids=list(range(i * 3, i * 3 + 3)),
        )
        for i in range(cfg.n_agents)
    ]
    state.shared_skill_ids = list(range(0, 3))  # seed shared skills
    state.next_skill_id = cfg.n_agents * 3

    metrics: List[CycleMetrics] = []

    for t in range(cfg.n_cycles):
        state.t = t
        ships_this_cycle = 0
        type_b_this_cycle = 0

        for agent in state.agents:
            # --- Execution attempt ---
            # Success probability based on skill match
            shared_overlap = sum(
                1 for s in state.shared_skill_ids if s in agent.local_skill_ids
            )
            p_success = _sigmoid(2.0 * (shared_overlap - 1))
            p_success = max(0.2, min(0.9, p_success))

            roll = rng.random()

            if roll < p_success:
                # SUCCESS — ship it
                agent.ships += 1
                ships_this_cycle += 1

                # Agent gains a new skill
                new_skill = state.next_skill_id
                state.next_skill_id += 1
                agent.local_skill_ids.append(new_skill)
                agent.skill_count += 1

                # Skill absorbed into shared library with probability
                if rng.random() < 0.3:
                    state.shared_skill_ids.append(new_skill)

                # Force 1: decay (unless disabled)
                if not cfg.disable_force1:
                    agent.boldness *= cfg.decay_rate

                # Force 2: skill lift (unless disabled)
                if not cfg.disable_force2:
                    agent.boldness += agent.skill_count * cfg.skill_boldness_coefficient

                # Clamp
                agent.boldness = max(0.05, min(1.0, agent.boldness))

            else:
                # FAILURE — Type A or Type B?
                prediction_value = agent.boldness  # higher boldness = bolder prediction
                p_type_b = (
                    prediction_value
                    * cfg.falsification_sensitivity
                    * (1.0 if not cfg.disable_force3 else 0.0)
                )

                if rng.random() < p_type_b:
                    # TYPE B — disproved prediction (most valuable)
                    agent.type_b_count += 1
                    type_b_this_cycle += 1
                    state.anomaly_count += 1

                    # Force 3: boldness jump (unless disabled)
                    if not cfg.disable_force3:
                        agent.boldness = (
                            agent.boldness * cfg.jump_multiplier + cfg.jump_base
                        )

                    # Still gains partial skills from the attempt
                    if rng.random() < 0.4:
                        new_skill = state.next_skill_id
                        state.next_skill_id += 1
                        agent.local_skill_ids.append(new_skill)
                        agent.skill_count += 1

                    agent.boldness = max(0.05, min(1.0, agent.boldness))
                else:
                    # TYPE A — execution wrong, item back to queue
                    agent.type_a_count += 1
                    agent.boldness = max(0.05, agent.boldness * 0.97)

        # --- Monoculture pressure ---
        # Divergent skills drift toward shared library
        for agent in state.agents:
            divergent = [
                s for s in agent.local_skill_ids if s not in state.shared_skill_ids
            ]
            for s in divergent:
                if rng.random() < cfg.monoculture_rate:
                    state.shared_skill_ids.append(s)

        # --- Human inflection point check ---
        anomaly_density = state.anomaly_count / (t + 1)
        mean_boldness = sum(a.boldness for a in state.agents) / len(state.agents)

        if (
            anomaly_density > cfg.anomaly_threshold
            or mean_boldness < cfg.boldness_floor
        ):
            state.inflection_points_fired += 1
            if rng.random() < cfg.human_engagement_rate:
                # Human re-enters: injects boldness, clears anomalies
                for agent in state.agents:
                    agent.boldness = min(1.0, agent.boldness * 1.5 + 0.2)
                state.anomaly_count = 0
            else:
                state.inflection_points_declined += 1

        # --- Record metrics ---
        mean_b = sum(a.boldness for a in state.agents) / len(state.agents)
        diversity = _skill_diversity(state.agents)
        tb_rate = type_b_this_cycle / len(state.agents)
        comp_rate = ships_this_cycle / len(state.agents)
        a_density = state.anomaly_count / (t + 1)

        metrics.append(
            CycleMetrics(
                t=t,
                vision_boldness=round(mean_b, 4),
                skill_diversity=round(diversity, 4),
                type_b_rate=round(tb_rate, 4),
                completion_rate=round(comp_rate, 4),
                anomaly_density=round(a_density, 4),
            )
        )

    return metrics


# ---------------------------------------------------------------------------
# Averaging across runs
# ---------------------------------------------------------------------------


def average_metrics(all_runs: List[List[CycleMetrics]]) -> List[CycleMetrics]:
    n_runs = len(all_runs)
    n_cycles = len(all_runs[0])
    averaged = []
    for t in range(n_cycles):
        avg = CycleMetrics(
            t=t,
            vision_boldness=round(
                sum(r[t].vision_boldness for r in all_runs) / n_runs, 4
            ),
            skill_diversity=round(
                sum(r[t].skill_diversity for r in all_runs) / n_runs, 4
            ),
            type_b_rate=round(sum(r[t].type_b_rate for r in all_runs) / n_runs, 4),
            completion_rate=round(
                sum(r[t].completion_rate for r in all_runs) / n_runs, 4
            ),
            anomaly_density=round(
                sum(r[t].anomaly_density for r in all_runs) / n_runs, 4
            ),
        )
        averaged.append(avg)
    return averaged


# ---------------------------------------------------------------------------
# Curve classification
# ---------------------------------------------------------------------------


def classify_curve(metrics: List[CycleMetrics]) -> str:
    """Classify the boldness curve shape."""
    boldness = [m.vision_boldness for m in metrics]
    n = len(boldness)
    if n < 10:
        return "INSUFFICIENT_DATA"

    # Split into thirds
    t1 = boldness[: n // 3]
    t2 = boldness[n // 3 : 2 * n // 3]
    t3 = boldness[2 * n // 3 :]

    mean1, mean2, mean3 = sum(t1) / len(t1), sum(t2) / len(t2), sum(t3) / len(t3)
    final = boldness[-1]
    initial = boldness[0]

    # Count jumps: points >10% above rolling mean
    jumps = 0
    window = 10
    for i in range(window, n):
        local_mean = sum(boldness[i - window : i]) / window
        if boldness[i] > local_mean * 1.1:
            jumps += 1

    # Variance in second half (stability measure)
    second_half = boldness[n // 2 :]
    variance = sum(
        (x - sum(second_half) / len(second_half)) ** 2 for x in second_half
    ) / len(second_half)

    if final < initial * 0.8:
        return "CONVERGENCE_TO_ZERO"
    elif mean3 > mean1 * 1.2 and jumps > 5:
        return "PUNCTUATED_EQUILIBRIUM"
    elif mean3 > mean2 > mean1 * 1.05:
        return "MONOTONIC_GROWTH"
    elif variance < 0.005 and abs(final - initial) < 0.1:
        return "LOCAL_MAXIMUM_PLATEAU"
    else:
        return "OSCILLATING"


def detect_monoculture_onset(
    metrics: List[CycleMetrics], threshold: float = 0.3
) -> int:
    """Return cycle where skill diversity first drops below threshold, or -1."""
    for m in metrics:
        if m.skill_diversity < threshold:
            return m.t
    return -1


# ---------------------------------------------------------------------------
# ASCII chart
# ---------------------------------------------------------------------------


def ascii_chart(
    values: List[float], width: int = 60, height: int = 10, label: str = ""
) -> str:
    if not values:
        return ""
    lo, hi = min(values), max(values)
    if hi == lo:
        hi = lo + 0.001
    rows = []
    for row in range(height, -1, -1):
        threshold = lo + (row / height) * (hi - lo)
        line = ""
        step = max(1, len(values) // width)
        for i in range(0, len(values), step):
            chunk = values[i : i + step]
            avg = sum(chunk) / len(chunk)
            line += "█" if avg >= threshold else " "
        rows.append(f"{threshold:5.2f} |{line}|")
    rows.append(f"      +{'-' * (width // max(1, len(values) // width))}+")
    if label:
        rows.insert(0, f"  {label}")
    return "\n".join(rows)


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------


def print_csv(metrics: List[CycleMetrics], n_agents: int, file=sys.stdout) -> None:
    print(
        "cycle,n_agents,vision_boldness,skill_diversity,"
        "type_b_rate,completion_rate,anomaly_density",
        file=file,
    )
    for m in metrics:
        print(
            f"{m.t},{n_agents},{m.vision_boldness},{m.skill_diversity},"
            f"{m.type_b_rate},{m.completion_rate},{m.anomaly_density}",
            file=file,
        )


def print_summary(results_by_n: dict, cfg: SimConfig) -> None:
    print("\n=== SIMULATION SUMMARY ===")
    print(
        f"Cycles: {cfg.n_cycles} | Runs per N: {cfg.n_runs} | "
        f"Human engagement: {cfg.human_engagement_rate}"
    )
    if cfg.disable_force1 or cfg.disable_force2 or cfg.disable_force3:
        disabled = []
        if cfg.disable_force1:
            disabled.append("Force1(decay)")
        if cfg.disable_force2:
            disabled.append("Force2(skill-growth)")
        if cfg.disable_force3:
            disabled.append("Force3(TypeB-jump)")
        print(f"FALSIFY MODE — disabled: {', '.join(disabled)}")
    print()

    best_n = None
    best_final = -1.0

    print(
        f"{'N':>4}  {'Final boldness':>15}  {'Diversity':>10}  "
        f"{'TypeB rate':>11}  {'Monoculture':>12}  {'Curve shape'}"
    )
    print("-" * 80)

    for n, metrics in sorted(results_by_n.items()):
        final_b = metrics[-1].vision_boldness
        final_div = metrics[-1].skill_diversity
        mean_tb = sum(m.type_b_rate for m in metrics) / len(metrics)
        mono = detect_monoculture_onset(metrics)
        mono_str = f"cycle {mono}" if mono >= 0 else "none"
        curve = classify_curve(metrics)

        print(
            f"{n:>4}  {final_b:>15.4f}  {final_div:>10.4f}  "
            f"{mean_tb:>11.4f}  {mono_str:>12}  {curve}"
        )

        if final_b > best_final:
            best_final = final_b
            best_n = n

    print("-" * 80)
    print(f"Optimal N: {best_n} (final boldness {best_final:.4f})")

    # Chart for default N
    if cfg.n_agents in results_by_n:
        default_metrics = results_by_n[cfg.n_agents]
        boldness_values = [m.vision_boldness for m in default_metrics]
        diversity_values = [m.skill_diversity for m in default_metrics]
        print()
        print(ascii_chart(boldness_values, label=f"Vision boldness (N={cfg.n_agents})"))
        print()
        print(
            ascii_chart(diversity_values, label=f"Skill diversity (N={cfg.n_agents})")
        )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Multi-agent boldness simulation — otherness design doc 10"
    )
    parser.add_argument("--n-agents", type=int, default=4)
    parser.add_argument("--cycles", type=int, default=200)
    parser.add_argument("--runs", type=int, default=50)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--human-engagement", type=float, default=0.7)
    parser.add_argument(
        "--falsify",
        choices=["force1", "force2", "force3"],
        help="Remove one force and measure the effect",
    )
    parser.add_argument(
        "--optimal-n",
        action="store_true",
        help="Run N=1,2,4,8,16 and find optimal agent count",
    )
    parser.add_argument(
        "--csv", metavar="FILE", help="Write CSV output to FILE (default: stdout)"
    )
    args = parser.parse_args()

    cfg = SimConfig(
        n_agents=args.n_agents,
        n_cycles=args.cycles,
        n_runs=args.runs,
        seed=args.seed,
        human_engagement_rate=args.human_engagement,
        disable_force1=(args.falsify == "force1"),
        disable_force2=(args.falsify == "force2"),
        disable_force3=(args.falsify == "force3"),
    )

    agent_counts = [1, 2, 4, 8, 16] if args.optimal_n else [cfg.n_agents]

    results_by_n: dict = {}

    for n in agent_counts:
        cfg.n_agents = n
        all_runs = []
        for run_idx in range(cfg.n_runs):
            cfg.seed = args.seed + run_idx
            metrics = run_simulation(cfg)
            all_runs.append(metrics)
        averaged = average_metrics(all_runs)
        results_by_n[n] = averaged
        print(f"N={n}: done ({cfg.n_runs} runs)", file=sys.stderr)

    # CSV output
    cfg.n_agents = args.n_agents
    primary_metrics = results_by_n[args.n_agents]
    if args.csv:
        with open(args.csv, "w") as f:
            print_csv(primary_metrics, args.n_agents, file=f)
        print(f"CSV written to {args.csv}", file=sys.stderr)
    else:
        print_csv(primary_metrics, args.n_agents)

    # Summary always goes to stderr so it doesn't pollute CSV stdout
    print_summary(results_by_n, cfg)


if __name__ == "__main__":
    main()
