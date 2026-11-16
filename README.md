# knapsack-benchmark-matlab

Benchmark of five 0-1 knapsack algorithms, written in MATLAB-compatible code and run with **GNU Octave** (free). It also runs unchanged in MATLAB.

| Key | Algorithm | Type | Implementation |
|---|---|---|---|
| `dp` | Dynamic programming 0-1 | exact (reference optimum) | `src/algorithms/dp/kb_knapsack_dp.m`, vectorised table, O(n·C) |
| `bnb` | Branch and bound | exact | `src/algorithms/bnb/kb_knapsack_bnb.m`, depth-first, Dantzig (LP) bound, greedy start |
| `ilp` | Integer linear programming | exact | `src/algorithms/ilp/kb_knapsack_ilp.m`: `glpk` in Octave, `intlinprog` in MATLAB (Optimization Toolbox) |
| `qubo` | QUBO + tabu search | heuristic | `src/algorithms/qubo/kb_knapsack2qubo.m` + `kb_qubo_tabu_slack.m` |
| `qubo_chz` | QUBO CHZ: independent copy of `qubo` | heuristic | `src/algorithms/qubo_chz/kb_chz_*.m`, own settings `cfg.qubo_chz` |

For each of **100 generated instances** every algorithm is run and measured on:
- **quality**: value, items, feasibility, gap to the DP optimum, proven optimality;
- **execution cost**: wall time, CPU time, working memory, process memory, operations.

Everything is written to `./output/run-dd-mm-yy-hh-mm.json`.

## Requirements

- GNU Octave **≥ 7** (needs `jsonencode`; `glpk` is built in); tested with Octave 11.3 on Windows.
- or MATLAB **≥ R2021a**. Without the Optimization Toolbox (`intlinprog`) and without `glpk`, the `ilp` algorithm is skipped with a warning.

## Run

From a terminal, in this folder:

```
octave-cli --eval "run_benchmark"
```

or in the Octave GUI: `cd` to this folder, then `run_benchmark`. A full run takes about 3 minutes (most of it is the two QUBO tabu searches).

Options (any field of `benchmark_config.m`):

```octave
run_benchmark(struct('instances', struct('count', 10)))
run_benchmark(struct('algorithms', {{'dp', 'bnb', 'ilp'}}))   % subset (note the double braces)
run_benchmark(struct('bnb', struct('max_nodes', 1e5)))          % cap branch and bound
run_benchmark(struct('bnb', struct('repeats', 3)))              % more timing repeats
run_benchmark(struct('qubo', struct('tabu', struct('mode', 'all-bits'))))   % plain bit-flip tabu for QUBO
run_benchmark(struct('qubo_chz', struct('tabu', struct('restarts', 50))))   % tune qubo_chz only
run_benchmark(struct('qubo_chz', struct('seed_offset', 7)))     % other random starts for qubo_chz
```

Tests (reference instance P01 = 309 for DP, B&B and ILP; MathWorks `knapsack2qubo` example; QUBO solvers; slack encoding; `qubo_chz` identical to `qubo`):

```
octave-cli --eval "addpath('tests'); test_p01"
```

## Project layout

```
knapsack-benchmark-matlab/
├── run_benchmark.m            entry point: generate → run each algorithm (timed) → compare → JSON
├── benchmark_config.m         all parameters (seed, sizes, algorithms, limits, tabu, timing)
├── src/                       added to the path with genpath (all subfolders)
│   ├── helpers/
│   │   ├── kb_algorithm_ids.m       registry of algorithm ids (add new algorithms here)
│   │   ├── kb_check_algorithms.m    validate the requested algorithm ids
│   │   ├── kb_ilp_solver_name.m     intlinprog / glpk / none
│   │   ├── kb_run_algorithm.m       run one algorithm with its timing repeats → result + cost
│   │   ├── kb_add_ratios_vs_dp.m    cost ratios to dp
│   │   ├── kb_summary.m             per-algorithm / per-family summary
│   │   ├── kb_penalty.m             QUBO penalty rule (shared by qubo and qubo_chz)
│   │   ├── kb_print_instance.m, kb_print_summary.m, kb_human_bytes.m   console output
│   │   ├── kb_interpreter.m         'GNU Octave' or 'MATLAB'
│   │   ├── kb_lcg.m, kb_randi.m, kb_seed.m   portable random numbers (same in MATLAB, Octave, Python)
│   │   ├── kb_bytes.m               working memory of arrays (whos)
│   │   ├── kb_process_memory.m      process RAM snapshot (memory())
│   │   └── kb_write_json.m          JSON output
│   ├── instances/
│   │   ├── kb_generate_instances.m  100 reproducible instances (Pisinger families)
│   │   └── kb_config_instances.m    generator settings (block cfg.instances)
│   └── algorithms/            each folder also holds kb_config_<id>.m (settings) and kb_algo_<id>.m (adapter)
│       ├── dp/kb_knapsack_dp.m      dynamic programming 0-1 (exact)
│       ├── bnb/kb_knapsack_bnb.m    branch and bound (exact)
│       ├── ilp/kb_knapsack_ilp.m    integer linear programming via glpk / intlinprog (exact)
│       ├── qubo/
│       │   ├── kb_knapsack2qubo.m       knapsack → QUBO (Q, c, d), binary-encoded slack
│       │   ├── kb_qubo_tabu_slack.m     tabu search, item bits flipped, slack bits set optimally (default)
│       │   ├── kb_qubo_tabu.m           plain single-bit-flip tabu search on all QUBO bits
│       │   ├── kb_encode_slack.m        slack value → slack bits
│       │   └── kb_decode.m              QUBO vector → items / value / weight (+ repair)
│       └── qubo_chz/kb_chz_*.m      independent copies of the five QUBO files,
│                                    to be modified without touching qubo
├── tests/test_p01.m
└── output/                    run-dd-mm-yy-hh-mm.json files (git-ignored)
```

## Method

**Instances.** 100 instances; sizes grow linearly from 10 to 48 items. Families rotate: *uncorrelated* (v ~ U(1,100)), *weakly correlated* (v = w ± 10), *strongly correlated* (v = w + 10). Weights w ~ U(1,100); capacity = ⌊0.5 · Σw⌋. A Park–Miller generator replaces `rand` so the instances are identical in Octave, MATLAB and Python.

**Dynamic programming.** Table m(i, j) = best value with the first i items and capacity j; one row is computed at a time (vectorised). Backtracking recovers the items. Time and memory O(n·C).

**Branch and bound.** Items sorted by value/weight. Depth-first search, "take" before "skip"; a node is pruned when ⌊Dantzig bound⌋ ≤ best value found (the bound is the LP relaxation: greedy fill plus a fraction of the critical item). Greedy solution as the starting lower bound; iterative backtracking, O(n) memory. Node limit `bnb.max_nodes` (default 5·10⁶); if reached, the result is flagged `proven_optimal = false`.

**Integer linear programming.** max v'x s.t. w'x ≤ C, x binary, solved by GLPK (`glpk`, Octave) or HiGHS (`intlinprog`, MATLAB R2024a+). `proven_optimal` comes from the solver status.

**QUBO.** Minimise f(x, s) = −Σ vᵢxᵢ + P · (Σ wᵢxᵢ + s − C)², slack s on ⌈log₂(C+1)⌉ bits; P = max(v) + 1 (then the QUBO minimum is the knapsack optimum). Same model as MATLAB's `knapsack2qubo`. Solved by a multi-start tabu search (20 restarts, tenure 10 + n/10, aspiration) that flips item bits and sets the slack bits to their optimal value (every visited point is a valid QUBO assignment; the energy is recomputed from Q, c, d). The `all-bits` mode is the textbook single-bit-flip version, kept for comparison.

**QUBO CHZ (`qubo_chz`).** An independent replica of the QUBO pipeline: its own five source files (`src/algorithms/qubo_chz/kb_chz_*.m`) and its own settings block `cfg.qubo_chz` (`penalty`, `seed_offset`, `tabu`). It shares only the infrastructure (random generator, memory helper, JSON writer). When created it is identical to `qubo`: same model, solver and random starts (`seed_offset = 0`), so it gives the same solutions; only its timings differ slightly. Change its files or settings to experiment without affecting `qubo`.

## Execution cost measures

Each algorithm result has a `cost` object:

| Field | Meaning |
|---|---|
| `wall_time_s` / `wall_time_min_s` | median / fastest wall-clock time over the repeats (`tic`/`toc`). Repeats: dp 5, bnb 1, ilp 3, qubo 1 (`timing.repeats_*`) |
| `cpu_time_s` | CPU time per run (`cputime`) |
| `working_memory_bytes` | bytes held by the algorithm's own arrays (`whos` at the end of the function): DP table; B&B vectors; ILP problem data (the solver's internal memory is not visible); QUBO Q, c and search vectors |
| `process_memory_before/after/delta_bytes` | process RAM from `memory()` (Octave on Linux and Windows; MATLAB on Windows only), `null` when unavailable. Process-wide snapshot: indicative only |
| `operations` + `operations_unit` | dp: table cells n·(C+1) · bnb: nodes · ilp: B&B nodes (`intlinprog` only, `null` with glpk) · qubo, qubo_chz: move evaluations |

and a `cost_ratio_vs_dp` object (`time`, `cpu`, `memory`; > 1 means costlier than DP).

## Expected results (default settings, seed 2026, 100 instances)

Quality and operation counts were computed with a line-by-line Python copy of this code; the Octave runs of the previous versions matched it exactly (QUBO: 44/100 optimal, mean gap 1.02 %).

| Algorithm | Optimal | Mean gap | Notes |
|---|---|---|---|
| `dp` | 100 / 100 | 0 % | reference |
| `bnb` | 100 / 100 (all proven) | 0 % | nodes: median 114, mean ≈ 4 900, max 284 157 |
| `ilp` | 100 / 100 expected | 0 % | exact solver (not run in the Python copy) |
| `qubo` | 44 / 100 | 1.02 % (max 4.80 %) | all feasible before repair |
| `qubo_chz` | 44 / 100 | 1.02 % (max 4.80 %) | identical to `qubo` until modified |

Branch-and-bound nodes by family: uncorrelated mean 73 (max 152), weakly correlated mean 140 (max 377), **strongly correlated mean 14 608 (max 284 157)**. B&B is very fast on easy instances and explodes on strongly correlated ones, while DP's cost depends only on n·C.

Measured on the Octave 11.3 / Windows test machine (4-algorithm run, 100 instances, GLPK for ILP):

| Algorithm | Optimal | Median time | Max time | Total time | Median working memory |
|---|---|---|---|---|---|
| `ilp` (glpk) | 100 | 1.7 ms | 0.98 s | 1.5 s | 0.9 kB (problem data only) |
| `dp` | 100 | 2.7 ms | 5 ms | 0.3 s | 171 kB |
| `bnb` | 100 | 5.6 ms | 10.9 s (instance 96) | 19.3 s | 2.3 kB |
| `qubo` | 44 | 0.62 s | 1.4 s | 65.6 s | 15 kB |

Ranking by median time: ilp < dp < bnb < qubo. `qubo_chz` should measure like `qubo`.

## Output file

`output/run-dd-mm-yy-hh-mm.json` (day-month-year-hour-minute of the run). `schema_version` identifies the JSON structure (currently 2, same value in the Python project); increase it on any breaking change:

```json
{
  "project": "knapsack-benchmark-matlab",
  "schema_version": 2,
  "algorithms": [
    { "id": "dp", "label": "dynamic programming 0-1", "exact": true, "config": { "repeats": 5 } },
    { "id": "bnb", "label": "branch and bound (Dantzig bound, depth-first)", "exact": true,
      "config": { "max_nodes": 5000000, "repeats": 1 } },
    "..."
  ],
  "instance_config": { "seed": 2026, "count": 100, "min_items": 10, "max_items": 48,
                       "max_coefficient": 100, "capacity_ratio": 0.5 },
  "reference_algorithm": "dp",
  "created": "2026-11-14T13:40:00",
  "environment": { "interpreter": "GNU Octave", "version": "11.3.0", "computer": "...",
                   "process_memory_available": true, "ilp_solver": "glpk" },
  "parameters": { "seed": 2026, "instances": { "count": 100, "...": "..." }, "algorithms": ["dp", "bnb", "ilp", "qubo", "qubo_chz"],
                  "dp": { "repeats": 5 }, "bnb": { "max_nodes": 5000000, "repeats": 1 },
                  "ilp": { "repeats": 3 }, "qubo": { "penalty": "auto", "tabu": { "...": "..." }, "repeats": 1 },
                  "qubo_chz": { "penalty": "auto", "seed_offset": 0, "tabu": { "...": "..." }, "repeats": 1 } },
  "summary": {
    "num_instances": 100, "total_time_seconds": 0,
    "algorithms": {
      "dp":   { "algorithm": "dynamic programming 0-1", "exact": true,
                "num_optimal": 100, "num_proven_optimal": 100, "num_feasible": 100,
                "mean_gap_percent": 0, "max_gap_percent": 0,
                "total_wall_time_s": 0, "mean_wall_time_s": 0, "median_wall_time_s": 0,
                "max_wall_time_s": 0, "mean_cpu_time_s": 0,
                "mean_working_memory_bytes": 0, "median_working_memory_bytes": 0,
                "max_working_memory_bytes": 0, "mean_operations": 0, "max_operations": 0,
                "operations_unit": "table cells",
                "median_time_ratio_vs_dp": 1, "median_memory_ratio_vs_dp": 1,
                "by_family": [ { "family": "strongly_correlated", "count": 33, "num_optimal": 33,
                                 "mean_gap_percent": 0, "mean_wall_time_s": 0,
                                 "max_wall_time_s": 0, "mean_working_memory_bytes": 0 } ] },
      "bnb":  { "...": "same fields" },
      "ilp":  { "...": "same fields" },
      "qubo": { "...": "same fields" },
      "qubo_chz": { "...": "same fields" }
    },
    "ranking_by_median_time": ["...", "..."]
  },
  "instances": [
    { "id": 1, "family": "uncorrelated", "n": 10, "capacity": 285,
      "weights": [], "values": [], "optimum": 345, "optimal_items": [],
      "results": {
        "dp":  { "algorithm": "dynamic programming 0-1", "exact": true, "proven_optimal": true,
                 "value": 345, "items": [], "weight": 0, "feasible": true,
                 "is_optimal": true, "gap_percent": 0,
                 "cost": { "repeats": 5, "wall_time_s": 0, "wall_time_min_s": 0, "cpu_time_s": 0,
                           "working_memory_bytes": 0, "process_memory_before_bytes": 0,
                           "process_memory_after_bytes": 0, "process_memory_delta_bytes": 0,
                           "operations": 0, "operations_unit": "table cells" },
                 "details": { "table_cells": 0 },
                 "cost_ratio_vs_dp": { "time": 1, "cpu": 1, "memory": 1 } },
        "bnb": { "...": "...", "details": { "nodes": 0, "node_limit": 5000000, "node_limit_reached": false } },
        "ilp": { "...": "...", "details": { "solver": "glpk", "status": 5 } },
        "qubo": { "...": "...",
                  "details": { "penalty": 101, "variables": 19, "slack_bits": 9,
                               "model_memory_bytes": 0, "energy": -345, "iterations": 0,
                               "raw_items": [], "raw_value": 345, "raw_weight": 0,
                               "feasible_before_repair": true, "repaired": false,
                               "build_time_s": 0, "solve_time_s": 0, "decode_time_s": 0 } },
        "qubo_chz": { "algorithm": "QUBO CHZ + tabu search (slack-optimal)", "...": "same fields as qubo" }
      } }
  ]
}
```

Item indices are 1-based. `gap_percent` = 100 · (optimum − value) / optimum, with the DP optimum as reference.

## Notes

- MATLAB's `knapsack2qubo` / `solve` (Quantum Computing support package) are not used: they do not exist in Octave. `kb_knapsack2qubo` reproduces the same model (checked against the MathWorks example: 10 variables, constant 289, energy −16).
- Documentation: knapsack Obsidian vault, `docs/shared/knapsack-problem/theory.*`, `docs/matlab/libraries/*` and `docs/python/libraries/*`.
