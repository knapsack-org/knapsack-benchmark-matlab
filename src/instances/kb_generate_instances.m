function instances = kb_generate_instances(count, seed, min_items, max_items, R, capacity_ratio, correlation)
%KB_GENERATE_INSTANCES  Reproducible 0-1 knapsack instances.
%   Families (classic Pisinger types) rotate in the order of CORRELATION.families:
%     uncorrelated            v ~ U(1, R)
%     weakly_correlated       v = w + U(-k, k), at least 1,  k = floor(weak_noise_ratio * R)
%     strongly_correlated     v = w + floor(strong_offset_ratio * R)
%   Weights w ~ U(1, R); capacity = floor(capacity_ratio * sum(w)).
%   The number of items grows linearly from MIN_ITEMS to MAX_ITEMS.
%   CORRELATION (block cfg.instances.correlation; default kb_config_instances().correlation):
%   families (cell of distinct names), weak_noise_ratio, strong_offset_ratio (both in [0, 1]).
%   Errors (identifier kb_generate_instances:correlation) on invalid correlation settings.
  if nargin < 7
    correlation = getfield(kb_config_instances(), 'correlation');
  end
  families = check_correlation(correlation);
  weak = floor(correlation.weak_noise_ratio * R);
  strong = floor(correlation.strong_offset_ratio * R);
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
        [noise, state] = kb_randi(state, -weak, weak, n);
        v = max(w + noise, 1);
      otherwise
        v = w + strong;
    end

    instances(k).id = k;                 % global instance id (also inside a shard)
    instances(k).family = family;
    instances(k).weights = w;
    instances(k).values = v;
    instances(k).capacity = floor(capacity_ratio * sum(w));
  end
end

function families = check_correlation(c)
  known = {'uncorrelated', 'weakly_correlated', 'strongly_correlated'};
  families = c.families;
  if ischar(families)
    families = {families};               % a one-element JSON array may decode as a string
  end
  families = families(:)';
  if isempty(families) || ~iscellstr(families) || ~all(ismember(families, known)) ...
     || numel(unique(families)) ~= numel(families)
    error('kb_generate_instances:correlation', ...
          'correlation.families: 1 to 3 distinct names among %s.', strjoin(known, ', '));
  end
  for f = {'weak_noise_ratio', 'strong_offset_ratio'}
    r = c.(f{1});
    if ~isnumeric(r) || ~isscalar(r) || ~(r >= 0 && r <= 1)
      error('kb_generate_instances:correlation', 'correlation.%s must be in [0, 1].', f{1});
    end
  end
end
