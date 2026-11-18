function [items, info] = kp_algo_dp_main(v, w, C, varargin)
%KP_ALGO_DP_MAIN  Exact 0-1 knapsack by dynamic programming, O(n*C).
%   [ITEMS, INFO] = KP_ALGO_DP_MAIN(V, W, C) (settings, seed and phase marks are accepted and not used;
%   no ~ placeholders: Octave would add an ans variable to the whos memory count).
%   Integer weights and capacity required. ITEMS are 1-based indices.
%   INFO.value = optimum; INFO.operations = table cells computed (n * (C + 1));
%   INFO.working_memory_bytes = bytes of the function's arrays (DP table included).
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

  if nargout > 1
    info = struct();
    info.operations = n * (C + 1);
    vars = whos();
    info.working_memory_bytes = sum([vars.bytes]);
    info.value = best;
  end
end
