function c = kp_algo_qubo_config()
%KP_ALGO_QUBO_CONFIG  Settings of 'qubo' (block cfg.qubo of BENCHMARK_CONFIG).
  c = struct();
  c.penalty = 'auto';           % 'auto' = max(values) + 1, or a number
  tabu = struct();
  tabu.mode = 'slack-optimal';  % 'slack-optimal' (flip item bits, slack bits set optimally)
                                % or 'all-bits' (plain single-bit-flip tabu on the whole QUBO)
  tabu.restarts = 20;           % independent tabu searches from random starts
  tabu.max_iter_factor = 100;   % iterations per restart = factor * N (N = searched bits)
  tabu.stall_factor = 20;       % stop a restart after factor * N iterations without improvement
  tabu.tenure_min = 10;         % tabu tenure = tenure_min + round(N / 10)
  c.tabu = tabu;
  c.repeats = 1;                % deterministic and slow: 1 run
end
