function c = kb_config_instances()
%KB_CONFIG_INSTANCES  Default settings of the instance generator (block cfg.instances
%   of BENCHMARK_CONFIG), used by KB_GENERATE_INSTANCES with the master seed cfg.seed.
  c = struct();
  c.count = 100;                % number of generated knapsack instances
  c.min_items = 10;             % smallest instance (number of items)
  c.max_items = 48;             % largest instance
  c.max_coefficient = 100;      % weights in 1..R (values depend on the family)
  c.capacity_ratio = 0.5;       % capacity = floor(ratio * sum(weights))
  corr = struct();
  corr.families = {'uncorrelated', 'weakly_correlated', 'strongly_correlated'};  % rotated in this order
  corr.weak_noise_ratio = 0.1;      % weakly:   v = max(w + U(-k, k), 1),  k = floor(ratio * R)
  corr.strong_offset_ratio = 0.1;   % strongly: v = w + floor(ratio * R)
  c.correlation = corr;
end
