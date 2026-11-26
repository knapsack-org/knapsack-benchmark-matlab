function sol = kb_qc_decode(x, v, w, C)
%KB_QC_DECODE  QUBO solution -> knapsack solution (counterpart of quboResult2knapsack).
%   Keeps the item part of X. If the packing is too heavy (possible with a
%   heuristic solver or a small penalty), a repair step removes the items with
%   the lowest value/weight ratio until it fits; both results are reported.
  n = numel(v);
  take = round(x(1:n))' > 0;
  sol = struct();
  sol.items = find(take);
  sol.value = sum(v(take));
  sol.weight = sum(w(take));
  sol.feasible = sol.weight <= C;
  sol.repaired = false;

  if ~sol.feasible
    sol.repaired = true;
    ratio = v ./ w;
    while sum(w(take)) > C
      idx = find(take);
      [~, worst] = min(ratio(idx));
      take(idx(worst)) = false;
    end
  end
  sol.final_items = find(take);
  sol.final_value = sum(v(take));
  sol.final_weight = sum(w(take));
end
