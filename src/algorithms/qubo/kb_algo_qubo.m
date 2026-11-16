function out = kb_algo_qubo(v, w, C, acfg, seed)
%KB_ALGO_QUBO  Benchmark adapter of 'qubo': build the QUBO, run the tabu search, decode.
%   OUT = KB_ALGO_QUBO(V, W, C, ACFG, SEED): ACFG = cfg.qubo, SEED = cfg.seed + 1000 * k.
  penalty = kb_penalty(v, acfg.penalty);
  tabu = acfg.tabu;
  tabu.seed = seed;

  t = tic;
  [Q, c, d, slack_bits] = kb_knapsack2qubo(v, w, C, penalty);
  t_build = toc(t);

  t = tic;
  if strcmp(tabu.mode, 'all-bits')
    [x, energy, stats] = kb_qubo_tabu(Q, c, d, tabu);
  else
    [x, energy, stats] = kb_qubo_tabu_slack(v, w, C, penalty, Q, c, d, tabu);
  end
  t_solve = toc(t);

  t = tic;
  sol = kb_decode(x, v, w, C);
  t_decode = toc(t);

  model_bytes = kb_bytes(Q, c, d);
  out = struct('label', ['QUBO + tabu search (' tabu.mode ')'], 'exact', false, ...
               'proven_optimal', false, 'items', sol.final_items, ...
               'working_memory_bytes', max(stats.working_memory_bytes, model_bytes), ...
               'operations', stats.move_evaluations, 'operations_unit', 'move evaluations');
  dt = struct();
  dt.penalty = penalty;
  dt.variables = numel(c);
  dt.slack_bits = slack_bits;
  dt.model_memory_bytes = model_bytes;
  dt.energy = energy;
  dt.iterations = stats.iterations;
  dt.raw_items = num2cell(sol.items);
  dt.raw_value = sol.value;
  dt.raw_weight = sol.weight;
  dt.feasible_before_repair = sol.feasible;
  dt.repaired = sol.repaired;
  dt.build_time_s = t_build;
  dt.solve_time_s = t_solve;
  dt.decode_time_s = t_decode;
  out.details = dt;
end
