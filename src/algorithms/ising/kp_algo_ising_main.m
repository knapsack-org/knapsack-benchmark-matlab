function [items, info] = kp_algo_ising_main(v, w, C, acfg, seed, mark)
%KP_ALGO_ISING_MAIN  0-1 knapsack -> Ising Hamiltonian -> spin annealing -> decoded items.
%   [ITEMS, INFO] = KP_ALGO_ISING_MAIN(V, W, C, ACFG, SEED, MARK)
%     ACFG  settings block cfg.ising (penalty, restarts, steps_factor, t0_factor, t_end_factor)
%     SEED  seed of the random spin starts and of the annealing
%     MARK  optional phase hook, called as MARK('build'), MARK('solve'), MARK('decode')
%           at the end of each phase (default: none)
%   ITEMS are the decoded (and, if needed, repaired) 1-based items.
%   INFO: penalty, variables, slack_bits, model_memory_bytes, energy (best H), proposals,
%   accepted, working_memory_bytes and the decoded solution INFO.sol of KB_ISING_DECODE.
  if nargin < 6
    mark = @(name) [];
  end
  v = v(:)';
  w = w(:)';
  if ischar(acfg.penalty)
    penalty = max(v) + 1;
  else
    penalty = acfg.penalty;
  end

  [J, h, E0, slack_bits] = kb_ising_model(v, w, C, penalty);
  mark('build');

  [s, energy, stats] = kb_ising_anneal(J, h, E0, acfg, seed, penalty * max(w));
  mark('solve');

  sol = kb_ising_decode(s, v, w, C);
  mark('decode');

  items = sol.final_items;
  model_bytes = kb_bytes(J, h, E0);
  info = struct('penalty', penalty, 'variables', numel(h), 'slack_bits', slack_bits, ...
                'model_memory_bytes', model_bytes, 'energy', energy, ...
                'proposals', stats.proposals, 'accepted', stats.accepted, ...
                'working_memory_bytes', model_bytes + kb_bytes(s, s));
  info.sol = sol;
end
