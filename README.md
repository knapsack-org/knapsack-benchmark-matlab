# knapsack-benchmark-matlab

Benchmark of eleven 0-1 knapsack algorithms (`bnb`, `dp`, `fptas`, `ga`, `greedy`, `ilp`, `ising`, `qc`, `qubo`, `qubo_b`, `sa`; the table lists the exact ones and the QUBO family), written in MATLAB-compatible code and run with **GNU Octave** (free). It also runs unchanged in MATLAB.

| Key | Algorithm | Type | Implementation |
|---|---|---|---|
| `bnb` | Branch and bound | exact | `src/algorithms/bnb/kp_algo_bnb_main.m`, depth-first, Dantzig (LP) bound, greedy start |
| `dp` | Dynamic programming 0-1 | exact (reference optimum) | `src/algorithms/dp/kp_algo_dp_main.m`, vectorised table, O(n·C) |
| `ilp` | Integer linear programming | exact | `src/algorithms/ilp/kp_algo_ilp_main.m`: `glpk` in Octave, `intlinprog` in MATLAB (Optimization Toolbox); `ilp.time_limit_s` (default 60 s per solve): when reached, not proven optimal (Octave's `glpk` then returns no solution: empty packing, status -1) |
| `qubo` | QUBO variant A + tabu search | heuristic | `src/algorithms/qubo/kp_algo_qubo_main.m` (modules `kb_knapsack2qubo.m`, `kb_qubo_tabu_slack.m`, …) |
| `qubo_b` | QUBO variant B + tabu search | heuristic | `src/algorithms/qubo_b/`: same code as `qubo` (modules `kb_qubo_b_*.m`); later MathWorks `knapsack2qubo` (steps in `kp_algo_qubo_b_main.m`, marked `TODO(knapsack2qubo)`) |
| `qc` | QC: QUBO + tabu search | heuristic | `src/algorithms/qc/`: QUBO B code; `modules/kb_qc_qaoa.m` (simulated QAOA) and `kb_qc_greedy.m`, with commented calls in `kp_algo_qc_main.m` |

The algorithms are found by scanning `src/algorithms/` (one folder per algorithm, see [Adding an algorithm](#adding-an-algorithm)); they run in alphabetical order. For each of **100 generated instances** every algorithm is run and measured on:
- **quality**: value, items, feasibility, gap to the optimum of the reference algorithm (`dp`), proven optimality;
- **execution cost**: wall time, CPU time, working memory, process memory, operations.

The raw results go to `./output/run-dd-mm-yy-hh-mm/raw.json` (with `instances.json`); the run file (`schema_version` 4: optimum, gaps, ratios, summary) is built from them by `knapsack-output` in [knapsack-server](https://github.com/knapsack-org/knapsack-server) (ADR 0014).

## Requirements

- GNU Octave **≥ 7** (needs `jsonencode`; `glpk` is built in); tested with Octave 11.3 on Windows.
- or MATLAB **≥ R2021a**. Without the Optimization Toolbox (`intlinprog`) and without `glpk`, the `ilp` algorithm is skipped with a warning.

## Run

From a terminal, in this folder:

```
octave-cli --eval "run_benchmark"                                            % defaults
octave-cli --eval "run_benchmark('req.json', 'instances.json', 'out');"     % each argument optional ('' = absent)
octave-cli --eval "run_benchmark('--describe');"                           % algorithms, default settings, JSON Schemas
```

or in the Octave GUI: `cd` to this folder, then `run_benchmark`.

| Argument | Meaning |
|---|---|
| request file | run request JSON (knapsack-server `RunRequest`): `seed`, `instances` (`count`, `min_items`, `max_items`, `max_coefficient`, `capacity_ratio`, `correlation`: `families`, `weak_noise_ratio`, `strong_offset_ratio`), `algorithms` (ids; the reference `dp` is always added), `algorithm_config` (`{<id>: partial settings}`, merged into the defaults; an unknown field is an error). Absent fields come from the settings files; `environments` is ignored |
| instances file | instance set JSON (`format: "knapsack-instances"`, the `instances.json` of an earlier run or a knapsack-server shard) used instead of the generator; the per-instance seed stays `seed + 1000 * id` with the file's global ids |
| out dir | output folder (default `output/run-dd-mm-yy-hh-mm/`) |

Output: `raw.json` (`format: "knapsack-raw"`, `format_version` 1: algorithm entries and schemas, parameters, raw results per instance without `is_optimal`, `gap_percent`, `cost_ratio_vs_reference`) and, without an instances file, `instances.json`. stdout has one line per instance plus progress lines `@@progress {"instance":<id>,"algorithm":"<id>","event":"start"|"done"}` before and after each algorithm. A full run file: `pnpm -C <knapsack-server> knapsack-output <out dir>`.

The settings files: `benchmark_config.m` (master seed), `src/instances/kb_config_instances.m` (number and size of instances, correlation: families rotated in order, weak noise and strong offset ratios) and `src/algorithms/<id>/kp_algo_<id>_config.m` (settings of one algorithm, e.g. `bnb.max_nodes`, `qubo.tabu.mode`).

Tests (every discovered algorithm on P01 through its adapter, keys checked against its schema file; `--describe`; request, instances file and shard (global seeds) round trip; P01 = 309 for DP, B&B and ILP; MathWorks `knapsack2qubo` example; QUBO solvers; slack encoding):

```
octave-cli --eval "addpath('tests'); test_p01"
```

## Project layout

```
knapsack-benchmark-matlab/
├── run_benchmark.m            entry point: discover → generate or read instances → run each algorithm (timed) → raw.json
├── benchmark_config.m         master seed + settings collected from src/instances and src/algorithms/<id>, request overrides
├── src/                       added to the path with genpath (all subfolders)
│   ├── helpers/               generic code, no algorithm names
│   │   ├── kb_discover_algorithms.m  scan src/algorithms/, check the folder contract, reference, availability, request filter
│   │   ├── kb_run_algorithm.m       run one algorithm with its timing repeats → raw result + cost
│   │   ├── kb_merge_settings.m      request settings merged into the defaults
│   │   ├── kb_phase_timer.m         phase timer passed to kp_algo_<id>_main as MARK
│   │   ├── kb_write_json.m          JSON output (schema files inserted verbatim)
│   │   ├── kb_print_instance.m, kb_print_progress.m   console output, progress lines
│   │   ├── kb_interpreter.m         'GNU Octave' or 'MATLAB'
│   │   ├── kb_lcg.m, kb_randi.m, kb_seed.m   portable random numbers (same in MATLAB, Octave, Python)
│   │   ├── kb_lcg_states.m          the next COUNT generator states in O(log COUNT) vector operations
│   │   ├── kb_bytes.m               working memory of arrays (whos)
│   │   ├── kb_process_memory.m      process RAM snapshot (memory())
│   │   └── kb_write_json.m          JSON output
│   ├── instances/
│   │   ├── kb_generate_instances.m  100 reproducible instances (Pisinger families)
│   │   └── kb_config_instances.m    generator settings (block cfg.instances)
│   └── algorithms/            one self-contained folder per algorithm (only folders here)
│       ├── bnb/                     branch and bound (exact): kp_algo_bnb_{loader,main,config,output}.m
│       ├── dp/                      dynamic programming 0-1 (exact, reference): kp_algo_dp_*.m
│       ├── ilp/                     integer linear programming via glpk / intlinprog (exact)
│       │   └── modules/kb_ilp_solver_name.m   intlinprog / glpk / none (loader availability)
│       ├── qc/                      QC: QUBO B code + modules/kb_qc_qaoa.m, kb_qc_greedy.m, kb_qc_*.m (QUBO copies)
│       ├── qubo_b/                  QUBO variant B: copy of qubo/ (modules kb_qubo_b_*.m)
│       └── qubo/                    QUBO variant A: kp_algo_qubo_*.m
│           └── modules/
│               ├── kb_penalty.m             penalty rule 'auto' = max(v) + 1
│               ├── kb_knapsack2qubo.m       knapsack → QUBO (Q, c, d), binary-encoded slack
│               ├── kb_qubo_tabu_slack.m     tabu search, item bits flipped, slack bits set optimally (default)
│               ├── kb_qubo_tabu.m           plain single-bit-flip tabu search on all QUBO bits
│               ├── kb_encode_slack.m        slack value → slack bits
│               └── kb_decode.m              QUBO vector → items / value / weight (+ repair)
├── tests/test_p01.m
└── output/                    run-dd-mm-yy-hh-mm/ folders (git-ignored)
```

## Adding an algorithm

Everything about an algorithm lives in `src/algorithms/<id>/` (`<id>` matches `[a-z][a-z0-9_]*`); nothing else is edited. Copy the folder of a similar algorithm, rename its files, and adapt:

| File | Role |
|---|---|
| `kp_algo_<id>_loader.m` | `L.id` (= folder name), `label` (capitalised words, e.g. `Branch and Bound (Dantzig Bound, Depth-First)`), `description` (one or two sentences, written to its `algorithms[]` entry), `short_label` (Knapview chip), `exact`, `reference` (exactly one algorithm, `dp`), `available()` (false → skipped with a warning), `environment()` (struct written to `environment.algorithms.<id>`) |
| `kp_algo_<id>_main.m` | the maths: `[items, info] = kp_algo_<id>_main(v, w, C, acfg, seed, mark)`; `mark('phase')` (optional) ends a timed phase |
| `kp_algo_<id>_config.m` | settings block `cfg.<id>`, always with `repeats` |
| `kp_algo_<id>_output.m` | `O.run(v, w, C, acfg, seed)` (calls `_main`, times its phases with `kb_phase_timer`, returns the common result) and `O.entry(acfg, env)` (its `algorithms[]` entry) |
| `kp_algo_<id>_output.schema.json` | JSON Schema 2020-12 of its `entry` (with `config` as an object), `config` and `details`; byte-identical to the Python file (knapsack-server `scripts/check-schemas.mjs`), checked by knapsack-server's output formatter |
| `modules/` | helper functions of `_main` (optional) |

`.m` file names must be unique across all algorithm folders (they share one path); `kb_discover_algorithms` stops with an error otherwise. Algorithms may call `src/helpers/` but never another algorithm's folder: shared code is copied into the folder's own `modules/`. See also `documentation/implementation/adding-an-algorithm.md`.

## Method

**Instances.** 100 instances; sizes grow linearly from 10 to 48 items. Families rotate: *uncorrelated* (v ~ U(1,100)), *weakly correlated* (v = w ± 10), *strongly correlated* (v = w + 10). Weights w ~ U(1,100); capacity = ⌊0.5 · Σw⌋. A Park–Miller generator replaces `rand` so the instances are identical in Octave, MATLAB and Python.

**Dynamic programming.** Table m(i, j) = best value with the first i items and capacity j; one row is computed at a time (vectorised). Backtracking recovers the items. Time and memory O(n·C).

**Branch and bound.** Items sorted by value/weight. Depth-first search, "take" before "skip"; a node is pruned when ⌊Dantzig bound⌋ ≤ best value found (the bound is the LP relaxation: greedy fill plus a fraction of the critical item). Greedy solution as the starting lower bound; iterative backtracking, O(n) memory. Node limit `bnb.max_nodes` (default 5·10⁶); if reached, the result is flagged `proven_optimal = false`.

**Integer linear programming.** max v'x s.t. w'x ≤ C, x binary, solved by GLPK (`glpk`, Octave) or HiGHS (`intlinprog`, MATLAB R2024a+). `proven_optimal` comes from the solver status.

**QUBO.** Minimise f(x, s) = −Σ vᵢxᵢ + P · (Σ wᵢxᵢ + s − C)², slack s on ⌈log₂(C+1)⌉ bits; P = max(v) + 1 (then the QUBO minimum is the knapsack optimum). Same model as MATLAB's `knapsack2qubo`. Solved by a multi-start tabu search (20 restarts, tenure 10 + n/10, aspiration) that flips item bits and sets the slack bits to their optimal value (every visited point is a valid QUBO assignment; the energy is recomputed from Q, c, d). The `all-bits` mode is the textbook single-bit-flip version, kept for comparison.

## Execution cost measures

Each algorithm result has a `cost` object:

| Field | Meaning |
|---|---|
| `wall_time_s` / `wall_time_min_s` | median / fastest wall-clock time over the repeats (`tic`/`toc`). Repeats: dp 5, bnb 1, ilp 3, qubo 1 (`repeats` in `kp_algo_<id>_config.m`) |
| `cpu_time_s` | CPU time per run (`cputime`) |
| `working_memory_bytes` | bytes held by the algorithm's own arrays (`whos` at the end of the function): DP table; B&B vectors; ILP problem data (the solver's internal memory is not visible); QUBO Q, c and search vectors |
| `process_memory_before/after/delta_bytes` | process RAM from `memory()` (Octave on Linux and Windows; MATLAB on Windows only), `null` when unavailable. Process-wide snapshot: indicative only |
| `operations` + `operations_unit` | dp: table cells n·(C+1) · bnb: nodes · ilp: B&B nodes (`intlinprog` only, `null` with glpk) · qubo: move evaluations |

and a `cost_ratio_vs_reference` object (`time`, `cpu`, `memory`; > 1 means costlier than the reference algorithm `dp`).

## Expected results (default settings, seed 2026, 100 instances)

Quality and operation counts were computed with a line-by-line Python copy of this code; the Octave runs of the previous versions matched it exactly (QUBO: 44/100 optimal, mean gap 1.02 %).

| Algorithm | Optimal | Mean gap | Notes |
|---|---|---|---|
| `dp` | 100 / 100 | 0 % | reference |
| `bnb` | 100 / 100 (all proven) | 0 % | nodes: median 114, mean ≈ 4 900, max 284 157 |
| `ilp` | 100 / 100 expected | 0 % | exact solver (not run in the Python copy) |
| `qubo` | 44 / 100 | 1.02 % (max 4.80 %) | all feasible before repair |

Branch-and-bound nodes by family: uncorrelated mean 73 (max 152), weakly correlated mean 140 (max 377), **strongly correlated mean 14 608 (max 284 157)**. B&B is very fast on easy instances and explodes on strongly correlated ones, while DP's cost depends only on n·C.

Measured on the Octave 11.3 / Windows test machine (4-algorithm run, 100 instances, GLPK for ILP):

| Algorithm | Optimal | Median time | Max time | Total time | Median working memory |
|---|---|---|---|---|---|
| `ilp` (glpk) | 100 | 1.7 ms | 0.98 s | 1.5 s | 0.9 kB (problem data only) |
| `dp` | 100 | 2.7 ms | 5 ms | 0.3 s | 171 kB |
| `bnb` | 100 | 5.6 ms | 10.9 s (instance 96) | 19.3 s | 2.3 kB |
| `qubo` | 44 | 0.62 s | 1.4 s | 65.6 s | 15 kB |

Ranking by median time: ilp < dp < bnb < qubo.

These times predate the phase-3 speed-ups (same results): on the 10 reference instances `qubo` is now about 3× faster (all restarts searched at once), `ising` about 2×, `sa` about 3×, `ga` about 24×.

## Output file

`raw.json` is described by the knapsack-server contracts (`rawFileSchema`, `libs/contracts`), the run file built from it (`schema_version` 4) in the `documentation` repo (`functional/output-format.md`). Item indices are 1-based; algorithms and results are in alphabetical order of their ids.

## Notes

- MATLAB's `knapsack2qubo` / `solve` (Quantum Computing support package) are not used: they do not exist in Octave. `kb_knapsack2qubo` (qubo module) reproduces the same model (checked against the MathWorks example: 10 variables, constant 289, energy −16).
- Documentation: knapsack Obsidian vault, `docs/shared/knapsack-problem/theory.*`, `docs/matlab/libraries/*` and `docs/python/libraries/*`.
