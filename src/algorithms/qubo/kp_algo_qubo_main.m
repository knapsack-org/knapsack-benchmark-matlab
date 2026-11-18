function [items, info] = kp_algo_qubo_main(v, w, C, acfg, seed, mark)
%KP_ALGO_QUBO_MAIN  0-1 knapsack -> QUBO -> multi-start tabu search -> decoded items.
%   [ITEMS, INFO] = KP_ALGO_QUBO_MAIN(V, W, C, ACFG, SEED, MARK)
%     ACFG  settings block cfg.qubo (penalty, tabu)
%     SEED  seed of the random tabu starts
%     MARK  optional phase hook, called as MARK('build'), MARK('solve'), MARK('decode')
%           at the end of each phase (default: none)
%   ITEMS are the decoded (and, if needed, repaired) 1-based items.
%   INFO: penalty, variables, slack_bits, model_memory_bytes, energy, mode, the tabu
%   statistics (iterations, move_evaluations, working_memory_bytes) and the decoded
%   solution INFO.sol of kb_decode.
  if nargin < 6
    mark = @(name) [];
  end
  penalty = kb_penalty(v, acfg.penalty);
  tabu = acfg.tabu;
  tabu.seed = seed;

  [Q, c, d, slack_bits] = kb_knapsack2qubo(v, w, C, penalty);
  mark('build');

  if strcmp(tabu.mode, 'all-bits')
    [x, energy, stats] = kb_qubo_tabu(Q, c, d, tabu);
  else
    [x, energy, stats] = kb_qubo_tabu_slack(v, w, C, penalty, Q, c, d, tabu);
  end
  mark('solve');

  sol = kb_decode(x, v, w, C);
  mark('decode');

  items = sol.final_items;
  info = struct('penalty', penalty, 'variables', numel(c), 'slack_bits', slack_bits, ...
                'model_memory_bytes', kb_bytes(Q, c, d), 'energy', energy, 'mode', tabu.mode, ...
                'iterations', stats.iterations, 'move_evaluations', stats.move_evaluations, ...
                'working_memory_bytes', stats.working_memory_bytes);
  info.sol = sol;
end
