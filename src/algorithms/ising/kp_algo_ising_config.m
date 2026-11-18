function c = kp_algo_ising_config()
%KP_ALGO_ISING_CONFIG  Settings of 'ising' (block cfg.ising of BENCHMARK_CONFIG).
  c = struct();
  c.penalty = 'auto';           % 'auto' = max(values) + 1, or a number
  c.restarts = 5;               % independent annealing runs from random spins
  c.steps_factor = 2000;        % proposals per restart = factor * N (N = items + slack spins)
  c.t0_factor = 100.0;          % start temperature = factor * P * max(weights)
  c.t_end_factor = 1.0;         % end temperature = factor * P * max(weights)
  c.repeats = 1;                % randomised and slower: 1 run
end
