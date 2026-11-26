function [items, info] = kp_algo_qubo_b_main(v, w, C, acfg, seed, mark)
%KP_ALGO_QUBO_B_MAIN  0-1 knapsack -> QUBO -> multi-start tabu search -> decoded items.
%   [ITEMS, INFO] = KP_ALGO_QUBO_B_MAIN(V, W, C, ACFG, SEED, MARK)
%     ACFG  settings block cfg.qubo_b (penalty, tabu)
%     SEED  seed of the random tabu starts
%     MARK  optional phase hook, called as MARK('build'), MARK('solve'), MARK('decode')
%           at the end of each phase (default: none)
%   ITEMS are the decoded (and, if needed, repaired) 1-based items.
%   INFO: penalty, variables, slack_bits, model_memory_bytes, energy, mode, the tabu
%   statistics (iterations, move_evaluations, working_memory_bytes) and the decoded
%   solution INFO.sol of kb_qubo_b_decode.
%
%   Variant B has the same code as variant A ('qubo'). In a later iteration it hosts
%   MathWorks KNAPSACK2QUBO in MATLAB (Python keeps this code). Transition, in order:
%     1. Needs MATLAB R2025b or later + "MATLAB Support Package for Quantum Computing"
%        (free add-on). GNU Octave has neither: the server image then skips qubo_b.
%     2. kp_algo_qubo_b_loader.m: L.available checks exist('knapsack2qubo') (see the
%        comment there), L.environment reports the package.
%     3. Build (TODO(knapsack2qubo) below): replace kb_qubo_b_knapsack2qubo by
%          qprob = knapsack2qubo(v, w, C, Penalty=penalty);
%          Q = full(qprob.QuadraticTerm); c = qprob.LinearTerm(:); d = qprob.ConstantTerm;
%          slack_bits = qprob.NumVariables - numel(v);
%        First check, in a test, that this equals kb_qubo_b_knapsack2qubo on the MathWorks
%        example (v = [5 2 8 4 3], w = [9 8 4 5 2], M = 17: 10 variables, constant 289,
%        energy -16 for items 1 3 5). MathWorks may keep the x_i^2 terms on the diagonal of
%        Q (ours moves them to c): energies must agree, not necessarily Q itself.
%     4. Solve: keep kb_qubo_b_tabu_slack / kb_qubo_b_tabu on (Q, c, d) (seeded, same as
%        Python), or use the package solver:
%          result = solve(qprob, Algorithm=tabuSearch(MaxTime=...)); x = result.BestX;
%        The package solver is not seeded by kb_lcg: MATLAB results then differ from Python
%        and from variant A, and 'iterations'/'move_evaluations' must come from
%        result.AlgorithmResult (or be dropped from the details schema).
%     5. Decode: keep kb_qubo_b_decode (repair + the same details), or
%          [items, value, weight] = quboResult2knapsack(result, v, w, C);
%        (no repair: check feasibility yourself).
%     6. Delete the modules no longer called, update kp_algo_qubo_b_config.m (new settings,
%        e.g. MaxTime), kp_algo_qubo_b_output.schema.json (config and details),
%        documentation/functional/algorithms/qubo_b.md and the parity expectation
%        (qubo_b = qubo no longer holds in MATLAB).
  if nargin < 6
    mark = @(name) [];
  end
  penalty = kb_qubo_b_penalty(v, acfg.penalty);
  tabu = acfg.tabu;
  tabu.seed = seed;

  % TODO(knapsack2qubo) step 3: build the model with MathWorks knapsack2qubo (see above).
  [Q, c, d, slack_bits] = kb_qubo_b_knapsack2qubo(v, w, C, penalty);
  mark('build');

  % TODO(knapsack2qubo) step 4: solver (own seeded tabu, or solve(qprob, ...)).
  if strcmp(tabu.mode, 'all-bits')
    [x, energy, stats] = kb_qubo_b_tabu(Q, c, d, tabu);
  else
    [x, energy, stats] = kb_qubo_b_tabu_slack(v, w, C, penalty, Q, c, d, tabu);
  end
  mark('solve');

  % TODO(knapsack2qubo) step 5: decode (own repair, or quboResult2knapsack).
  sol = kb_qubo_b_decode(x, v, w, C);
  mark('decode');

  items = sol.final_items;
  info = struct('penalty', penalty, 'variables', numel(c), 'slack_bits', slack_bits, ...
                'model_memory_bytes', kb_bytes(Q, c, d), 'energy', energy, 'mode', tabu.mode, ...
                'iterations', stats.iterations, 'move_evaluations', stats.move_evaluations, ...
                'working_memory_bytes', stats.working_memory_bytes);
  info.sol = sol;
end
