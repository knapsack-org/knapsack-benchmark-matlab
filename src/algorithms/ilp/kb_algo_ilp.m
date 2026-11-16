function out = kb_algo_ilp(v, w, C, acfg, seed) %#ok<INUSD>
%KB_ALGO_ILP  Benchmark adapter of 'ilp': run KB_KNAPSACK_ILP, return the common result struct.
%   OUT = KB_ALGO_ILP(V, W, C, ACFG, SEED): ACFG = cfg.ilp, SEED = cfg.seed + 1000 * k.
  [~, items, info] = kb_knapsack_ilp(v, w, C);
  out = struct('label', ['integer linear programming (' info.solver ')'], 'exact', true, ...
               'proven_optimal', info.proven_optimal, 'items', items, ...
               'working_memory_bytes', info.working_memory_bytes, ...
               'operations', info.nodes, 'operations_unit', 'nodes');
  out.details = struct('solver', info.solver, 'status', info.status);
end
