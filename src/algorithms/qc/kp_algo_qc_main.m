function [items, info] = kp_algo_qc_main(v, w, C, acfg, seed, mark)
%KP_ALGO_QC_MAIN  0-1 knapsack -> QUBO -> multi-start tabu search -> decoded items.
%   Today the code of QUBO variant B ('qubo_b'); modules/ also hold KB_QC_QAOA (simulated
%   QAOA) and KB_QC_GREEDY (ratio greedy). The commented block below the solve step shows
%   how to call each of them instead.
%   [ITEMS, INFO] = KP_ALGO_QC_MAIN(V, W, C, ACFG, SEED, MARK)
%     ACFG  settings block cfg.qc (penalty, tabu, qaoa)
%     SEED  seed of the random tabu starts
%     MARK  optional phase hook, called as MARK('build'), MARK('solve'), MARK('decode')
%           at the end of each phase (default: none)
%   ITEMS are the decoded (and, if needed, repaired) 1-based items.
%   INFO: penalty, variables, slack_bits, model_memory_bytes, energy, mode, the tabu
%   statistics (iterations, move_evaluations, working_memory_bytes) and the decoded
%   solution INFO.sol of kb_qc_decode.
  if nargin < 6
    mark = @(name) [];
  end
  penalty = kb_qc_penalty(v, acfg.penalty);
  tabu = acfg.tabu;
  tabu.seed = seed;

  [Q, c, d, slack_bits] = kb_qc_knapsack2qubo(v, w, C, penalty);
  mark('build');

  if strcmp(tabu.mode, 'all-bits')
    [x, energy, stats] = kb_qc_tabu(Q, c, d, tabu);
  else
    [x, energy, stats] = kb_qc_tabu_slack(v, w, C, penalty, Q, c, d, tabu);
  end
  % Other solvers of modules/ (uncomment one line, comment out the tabu call above):
  % [x, energy, stats] = kb_qc_tabu_slack(v, w, C, penalty, Q, c, d, tabu);   % QUBO: tabu (active above)
  % [x, energy, stats] = kb_qc_qaoa(Q, c, d, setfield(acfg.qaoa, 'seed', seed)); % QAOA: needs
  %                     % variables = n + slack bits <= acfg.qaoa.max_qubits (error kb_qc_qaoa:tooLarge)
  % [items, info] = kb_qc_greedy(v, w, C); return;                            % Greedy: no QUBO,
  %                     % no decode; its info has other fields than the details below
  % QAOA and Greedy report other statistics: update kp_algo_qc_output.m (details) and
  % kp_algo_qc_output.schema.json with the switch; tabu.mode is then unused.
  mark('solve');

  sol = kb_qc_decode(x, v, w, C);
  mark('decode');

  items = sol.final_items;
  info = struct('penalty', penalty, 'variables', numel(c), 'slack_bits', slack_bits, ...
                'model_memory_bytes', kb_bytes(Q, c, d), 'energy', energy, 'mode', tabu.mode, ...
                'iterations', stats.iterations, 'move_evaluations', stats.move_evaluations, ...
                'working_memory_bytes', stats.working_memory_bytes);
  info.sol = sol;
end
