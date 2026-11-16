function results = kb_add_ratios_vs_dp(results, algos)
%KB_ADD_RATIOS_VS_DP  Cost of each algorithm relative to dynamic programming (> 1 = costlier).
  has_dp = any(strcmp(algos, 'dp'));
  for a = 1:numel(algos)
    r = results.(algos{a});
    ratios = struct('time', NaN, 'cpu', NaN, 'memory', NaN);
    if has_dp
      ref = results.dp.cost;
      ratios.time = r.cost.wall_time_s / max(ref.wall_time_s, eps);
      ratios.cpu = r.cost.cpu_time_s / max(ref.cpu_time_s, eps);
      ratios.memory = r.cost.working_memory_bytes / ref.working_memory_bytes;
    end
    r.cost_ratio_vs_dp = ratios;
    results.(algos{a}) = r;
  end
end
