function c = kp_algo_fptas_config()
%KP_ALGO_FPTAS_CONFIG  Settings of 'fptas' (block cfg.fptas of BENCHMARK_CONFIG).
  c = struct();
  c.epsilon = 0.1;              % accuracy: value >= (1 - epsilon) * optimum; smaller = slower
  c.repeats = 5;                % fast: timed several times, median and min reported
end
