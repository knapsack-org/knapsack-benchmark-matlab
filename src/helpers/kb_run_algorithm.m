function res = kb_run_algorithm(algo, v, w, C, cfg, k)
%KB_RUN_ALGORITHM  Run one algorithm with its timing repeats and build its result.
%   RES = KB_RUN_ALGORITHM(ALGO, V, W, C, CFG, K): ALGO is one entry of
%   KB_DISCOVER_ALGORITHMS; its adapter ALGO.output.run is timed CFG.(id).repeats
%   times and its details are checked against ALGO.output.schema.details.
%   RES.is_optimal and RES.gap_percent are filled by the caller once the
%   reference optimum is known (placeholders false / NaN here).
  acfg = cfg.(algo.id);
  seed = cfg.seed + 1000 * k;     % per-instance seed (used by the randomised algorithms)
  repeats = acfg.repeats;
  times = zeros(1, repeats);
  mem_before = kb_process_memory();
  cpu0 = cputime();
  for rep = 1:repeats
    t = tic;
    out = algo.output.run(v, w, C, acfg, seed);
    times(rep) = toc(t);
  end
  cpu = (cputime() - cpu0) / repeats;
  mem_after = kb_process_memory();
  kb_validate_schema(out.details, algo.output.schema.details, [algo.id '.details']);

  items = out.items;
  res = struct();
  res.algorithm = out.label;
  res.exact = out.exact;
  res.proven_optimal = out.proven_optimal;
  res.value = sum(v(items));
  res.items = num2cell(items);
  res.weight = sum(w(items));
  res.feasible = res.weight <= C;
  res.is_optimal = false;
  res.gap_percent = NaN;

  cost = struct();
  cost.repeats = repeats;
  cost.wall_time_s = median(times);
  cost.wall_time_min_s = min(times);
  cost.cpu_time_s = cpu;
  cost.working_memory_bytes = out.working_memory_bytes;
  cost.process_memory_before_bytes = mem_before;
  cost.process_memory_after_bytes = mem_after;
  cost.process_memory_delta_bytes = mem_after - mem_before;
  cost.operations = out.operations;
  cost.operations_unit = out.operations_unit;
  res.cost = cost;
  res.details = out.details;
end
