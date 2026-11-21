function c = kp_algo_ilp_config()
%KP_ALGO_ILP_CONFIG  Settings of 'ilp' (block cfg.ilp of BENCHMARK_CONFIG).
  c = struct();
  % Per solve: a hard instance (large, strongly correlated) stops here with its best packing,
  % reported as not proven optimal, instead of blocking the run.
  c.time_limit_s = 10;
  c.repeats = 3;
end
