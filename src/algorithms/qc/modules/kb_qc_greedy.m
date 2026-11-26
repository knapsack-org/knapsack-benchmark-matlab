function [items, info] = kb_qc_greedy(v, w, C, ~, ~, ~)
%KB_QC_GREEDY  Ratio greedy with a best-single-item fix, O(n log n).
%   Copy of kp_algo_greedy_main (algorithm folders never call each other, ADR 0010).
%   [ITEMS, INFO] = KB_QC_GREEDY(V, W, C) (settings, seed and phase marks are not used).
%   Sorts by v/w (decreasing, ties keep the index order), takes every item that still fits,
%   then returns the better of that packing and the single most valuable item that fits
%   (lowest index on ties): at least half of the optimum. ITEMS are 1-based.
%   INFO: operations (n items scanned), greedy_value, single_value, chose_single,
%   working_memory_bytes.
  v = v(:)';
  w = w(:)';
  n = numel(v);
  [~, order] = sort(-(v ./ w));          % stable sort: ties keep the index order
  take = false(1, n);
  room = C;
  for i = order
    if w(i) <= room
      take(i) = true;
      room = room - w(i);
    end
  end
  greedy_value = sum(v(take));

  fits = find(w <= C);
  single = 0;
  single_value = 0;
  if ~isempty(fits)
    [single_value, k] = max(v(fits));    % first maximum: lowest index on ties
    single = fits(k);
  end
  chose_single = single_value > greedy_value;
  if chose_single
    take = false(1, n);
    take(single) = true;
  end
  items = find(take);

  info = struct('operations', n, 'greedy_value', greedy_value, 'single_value', single_value, ...
                'chose_single', chose_single, 'working_memory_bytes', kb_bytes(v, w, order, take));
end
