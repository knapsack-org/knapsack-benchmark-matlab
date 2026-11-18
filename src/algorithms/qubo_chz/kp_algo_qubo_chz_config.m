function c = kp_algo_qubo_chz_config()
%KP_ALGO_QUBO_CHZ_CONFIG  Settings of 'qubo_chz' (block cfg.qubo_chz of BENCHMARK_CONFIG).
%   Own copy of the qubo settings (same values when created), so qubo_chz can
%   be tuned without touching qubo.
  c = struct();
  c.penalty = 'auto';
  c.seed_offset = 0;            % added to the tabu seed: 0 -> same random starts as qubo
  tabu = struct();
  tabu.mode = 'slack-optimal';
  tabu.restarts = 20;
  tabu.max_iter_factor = 100;
  tabu.stall_factor = 20;
  tabu.tenure_min = 10;
  c.tabu = tabu;
  c.repeats = 1;
end
