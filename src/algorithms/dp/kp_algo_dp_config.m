function c = kp_algo_dp_config()
%KP_ALGO_DP_CONFIG  Settings of 'dp' (block cfg.dp of BENCHMARK_CONFIG).
  c = struct();
  c.repeats = 5;                % fast: timed several times, median and min reported
end
