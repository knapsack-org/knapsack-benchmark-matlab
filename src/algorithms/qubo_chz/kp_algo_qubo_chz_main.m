function [items, info] = kp_algo_qubo_chz_main(v, w, C, acfg, seed, mark)
%KP_ALGO_QUBO_CHZ_MAIN  0-1 knapsack -> QUBO -> multi-start tabu search -> decoded items.
%   Independent copy of 'qubo': uses only its own modules (modules/kb_chz_*.m)
%   and settings (cfg.qubo_chz), so it can be modified without touching 'qubo'.
%   [ITEMS, INFO] = KP_ALGO_QUBO_CHZ_MAIN(V, W, C, ACFG, SEED, MARK)
%     ACFG  settings block cfg.qubo_chz (penalty, seed_offset, tabu)
%     SEED  seed of the random tabu starts (plus ACFG.seed_offset)
%     MARK  optional phase hook, called as MARK('build'), MARK('solve'), MARK('decode')
%           at the end of each phase (default: none)
%   ITEMS are the decoded (and, if needed, repaired) 1-based items.
%   INFO: penalty, variables, slack_bits, model_memory_bytes, energy, mode, the tabu
%   statistics (iterations, move_evaluations, working_memory_bytes) and the decoded
%   solution INFO.sol of kb_chz_decode.
  if nargin < 6
    mark = @(name) [];
  end
  penalty = kb_chz_penalty(v, acfg.penalty);
  tabu = acfg.tabu;
  tabu.seed = seed + acfg.seed_offset;

  [Q, c, d, slack_bits] = kb_chz_knapsack2qubo(v, w, C, penalty);
  mark('build');

  if strcmp(tabu.mode, 'all-bits')
    [x, energy, stats] = kb_chz_qubo_tabu(Q, c, d, tabu);
  else
    [x, energy, stats] = kb_chz_qubo_tabu_slack(v, w, C, penalty, Q, c, d, tabu);
  end
  mark('solve');

  sol = kb_chz_decode(x, v, w, C);
  mark('decode');

  items = sol.final_items;
  info = struct('penalty', penalty, 'variables', numel(c), 'slack_bits', slack_bits, ...
                'model_memory_bytes', kb_bytes(Q, c, d), 'energy', energy, 'mode', tabu.mode, ...
                'iterations', stats.iterations, 'move_evaluations', stats.move_evaluations, ...
                'working_memory_bytes', stats.working_memory_bytes);
  info.sol = sol;
end
