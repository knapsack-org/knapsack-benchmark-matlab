function [best, items, cost] = kb_knapsack_dp(v, w, C)
%KB_KNAPSACK_DP  Exact 0-1 knapsack by dynamic programming, O(n*C).
%   Integer weights and capacity required. ITEMS are 1-based indices.
%   COST.operations = table cells computed (n * (C + 1));
%   COST.working_memory_bytes = bytes of the function's arrays (DP table included).
  n = numel(v);
  C = floor(C);
  M = zeros(n + 1, C + 1);                 % M(i+1, j+1): first i items, capacity j
  for i = 1:n
    M(i + 1, :) = M(i, :);
    if w(i) <= C
      j = w(i):C;
      M(i + 1, j + 1) = max(M(i, j + 1), M(i, j + 1 - w(i)) + v(i));
    end
  end
  best = M(n + 1, C + 1);
  take = false(1, n);
  j = C;
  for i = n:-1:1
    if M(i + 1, j + 1) ~= M(i, j + 1)
      take(i) = true;
      j = j - w(i);
    end
  end
  items = find(take);

  if nargout > 2
    cost = struct();
    cost.operations = n * (C + 1);
    vars = whos();
    cost.working_memory_bytes = sum([vars.bytes]);
  end
end
