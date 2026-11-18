function c = kp_algo_sa_config()
%KP_ALGO_SA_CONFIG  Settings of 'sa' (block cfg.sa of BENCHMARK_CONFIG).
  c = struct();
  c.penalty = 'auto';           % 'auto' = max(values) + 1, or a number
  c.restarts = 10;              % independent annealing runs from random starts
  c.steps_factor = 500;         % proposals per restart = factor * n
  c.t0_factor = 1.0;            % start temperature = factor * max(values)
  c.t_end_factor = 0.01;        % end temperature = factor * max(values)
  c.repeats = 1;                % randomised and slower: 1 run
end
