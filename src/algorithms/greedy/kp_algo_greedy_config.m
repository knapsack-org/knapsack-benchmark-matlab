function c = kp_algo_greedy_config()
%KP_ALGO_GREEDY_CONFIG  Settings of 'greedy' (block cfg.greedy of BENCHMARK_CONFIG).
  c = struct();
  c.repeats = 20;               % very fast: timed many times, median and min reported
end
