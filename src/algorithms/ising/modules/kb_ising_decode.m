function sol = kb_ising_decode(s, v, w, C)
%KB_ISING_DECODE  Spin solution -> knapsack solution.
%   Item i is taken when s_i = +1 (the slack spins are ignored). If the packing is too heavy,
%   a repair step removes, one at a time, the taken item with the lowest value/weight ratio
%   (lowest index on ties) until it fits; both results are reported.
  v = v(:)';
  w = w(:)';
  n = numel(v);
  take = s(1:n)' > 0;
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
