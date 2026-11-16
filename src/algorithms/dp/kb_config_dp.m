function c = kb_config_dp()
%KB_CONFIG_DP  Default settings of 'dp' (block cfg.dp of BENCHMARK_CONFIG).
  c = struct();
  c.repeats = 5;                % fast: timed several times, median and min reported
end
