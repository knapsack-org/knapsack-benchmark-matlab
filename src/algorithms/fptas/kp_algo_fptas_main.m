function [items, info] = kp_algo_fptas_main(v, w, C, acfg, ~, ~)
%KP_ALGO_FPTAS_MAIN  FPTAS for the 0-1 knapsack: dynamic programming on scaled profits.
%   [ITEMS, INFO] = KP_ALGO_FPTAS_MAIN(V, W, C, ACFG): ACFG.epsilon in (0, 1].
%   With nf the items that fit alone and vmax their largest value, every value is scaled to
%   s_i = floor(v_i * nf / (epsilon * vmax)); minw(p + 1) = least weight reaching scaled profit p
%   (table over the items, strict improvement only, so the lowest-index set wins). The packing
%   with the largest p such that minw <= C is returned; its value is at least
%   (1 - epsilon) times the optimum. Items with s_i = 0 are never taken. ITEMS are 1-based.
%   INFO: operations (table cells), scale (= epsilon * vmax / nf), scaled_total,
%   working_memory_bytes.
  v = v(:)';
  w = w(:)';
  epsilon = acfg.epsilon;
  fit = find(w <= C);
  nf = numel(fit);
  if nf == 0
    items = zeros(1, 0);
    info = struct('operations', 0, 'scale', 0, 'scaled_total', 0, 'working_memory_bytes', 0);
    return;
  end
  vmax = max(v(fit));
  scaled = floor(v(fit) * nf / (epsilon * vmax));
  total = sum(scaled);
  minw = inf(1, total + 1);
  minw(1) = 0;
  take = false(nf, total + 1);
  for k = 1:nf
    s = scaled(k);
    if s == 0
      continue;
    end
    cand = minw(1:total + 1 - s) + w(fit(k));
    seg = minw(s + 1:end);
    better = cand < seg;
    take(k, s + 1:end) = better;
    seg(better) = cand(better);
    minw(s + 1:end) = seg;
  end
  p = find(minw <= C, 1, 'last') - 1;
  items = zeros(1, 0);
  for k = nf:-1:1
    if take(k, p + 1)
      items(end + 1) = fit(k); %#ok<AGROW>
      p = p - scaled(k);
    end
  end
  items = sort(items);
  info = struct('operations', nf * (total + 1), 'scale', epsilon * vmax / nf, ...
                'scaled_total', total, 'working_memory_bytes', kb_bytes(v, w, minw, take));
end
