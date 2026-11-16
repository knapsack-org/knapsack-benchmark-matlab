function out = kb_algo_dp(v, w, C, acfg, seed) %#ok<INUSD>
%KB_ALGO_DP  Benchmark adapter of 'dp': run KB_KNAPSACK_DP, return the common result struct.
%   OUT = KB_ALGO_DP(V, W, C, ACFG, SEED): ACFG = cfg.dp, SEED = cfg.seed + 1000 * k.
  [~, items, c] = kb_knapsack_dp(v, w, C);
  out = struct('label', 'dynamic programming 0-1', 'exact', true, 'proven_optimal', true, ...
               'items', items, 'working_memory_bytes', c.working_memory_bytes, ...
               'operations', c.operations, 'operations_unit', 'table cells');
  out.details = struct('table_cells', c.operations);
end
