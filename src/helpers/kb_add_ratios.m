function results = kb_add_ratios(results, ids, ref)
%KB_ADD_RATIOS  Cost of each algorithm relative to the reference algorithm REF (> 1 = costlier).
  base = results.(ref).cost;
  for a = 1:numel(ids)
    r = results.(ids{a});
    ratios = struct();
    ratios.time = r.cost.wall_time_s / max(base.wall_time_s, eps);
    ratios.cpu = r.cost.cpu_time_s / max(base.cpu_time_s, eps);
    ratios.memory = r.cost.working_memory_bytes / base.working_memory_bytes;
    r.cost_ratio_vs_reference = ratios;
    results.(ids{a}) = r;
  end
end
