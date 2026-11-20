function instances = kb_generate_instances(count, seed, min_items, max_items, R, capacity_ratio)
%KB_GENERATE_INSTANCES  Reproducible 0-1 knapsack instances.
%   Families rotate between the classic Pisinger types:
%     uncorrelated            v ~ U(1, R)
%     weakly_correlated       v = w + U(-R/10, R/10), at least 1
%     strongly_correlated     v = w + R/10
%   Weights w ~ U(1, R); capacity = floor(capacity_ratio * sum(w)).
%   The number of items grows linearly from MIN_ITEMS to MAX_ITEMS.

  families = {'uncorrelated', 'weakly_correlated', 'strongly_correlated'};
  state = kb_seed(seed);
  instances = struct('id', {}, 'family', {}, 'weights', {}, 'values', {}, 'capacity', {});

  for k = 1:count
    if count > 1
      n = round(min_items + (max_items - min_items) * (k - 1) / (count - 1));
    else
      n = min_items;
    end
    family = families{mod(k - 1, numel(families)) + 1};

    [w, state] = kb_randi(state, 1, R, n);
    switch family
      case 'uncorrelated'
        [v, state] = kb_randi(state, 1, R, n);
      case 'weakly_correlated'
        [noise, state] = kb_randi(state, -floor(R / 10), floor(R / 10), n);
        v = max(w + noise, 1);
      otherwise
        v = w + floor(R / 10);
    end

    instances(k).id = k;                 % global instance id (also inside a shard)
    instances(k).family = family;
    instances(k).weights = w;
    instances(k).values = v;
    instances(k).capacity = floor(capacity_ratio * sum(w));
  end
end
