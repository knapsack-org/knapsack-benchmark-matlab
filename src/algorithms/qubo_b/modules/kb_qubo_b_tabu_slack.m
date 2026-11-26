function [x, energy, stats] = kb_qubo_b_tabu_slack(v, w, C, penalty, Q, c, d, opts)
%KB_QUBO_B_TABU_SLACK  Tabu search on the knapsack QUBO with optimal slack bits.
%   For fixed item bits, the slack bits that minimise the QUBO are known in
%   closed form: slack = C - W if the packing weight W fits, 0 otherwise.
%   Minimising over them exactly leaves
%       E(items) = -V + penalty * max(0, W - C)^2
%   so the tabu search moves on the item bits only (one flip per iteration)
%   while every visited point stays a valid QUBO assignment. This avoids the
%   deep local minima that single-bit flips meet on the slack bits.
%   Returns the full QUBO vector X = [items; slack bits] and its energy
%   computed from Q, c, d (so it can be checked against the model).
%   OPTS fields: restarts, max_iter_factor, stall_factor, tenure_min, seed.
%   STATS: iterations, move_evaluations, working_memory_bytes, ...
%   Speed (same results): the restarts only depend on each other through best_e in the
%   aspiration test. They are all searched at once (LANES, one column each) without aspiration;
%   a restart where no tabu move would have won by aspiration against the best energy of the
%   earlier restarts has exactly the sequential search, the others (a few) are searched again
%   sequentially (RESTART).

  v = v(:);
  w = w(:);
  n = numel(v);
  max_iter = opts.max_iter_factor * n;
  stall_limit = opts.stall_factor * n;
  tenure = opts.tenure_min + round(n / 10);
  starts = double(reshape(kb_lcg_states(kb_seed(opts.seed), opts.restarts * n), n, []) ...
                  / 2147483647 < 0.5);       % restart r starts from column r (n numbers each)
  [lane_e, lane_x, lane_it, lane_asp] = lanes(starts, v, w, C, penalty, max_iter, stall_limit, tenure);

  best = zeros(n, 1);
  best_e = 0;                                 % empty knapsack
  total_iter = 0;
  for r = 1:opts.restarts
    if lane_asp(r) >= best_e                  % same search as the sequential run
      it = lane_it(r);
      if lane_e(r) < best_e
        best_e = lane_e(r);
        best = lane_x(:, r);
      end
    else
      [best_e, best, it] = restart(starts(:, r), best_e, best, v, w, C, penalty, max_iter, ...
                                   stall_limit, tenure);
    end
    total_iter = total_iter + it;
  end

  Wb = w' * best;
  x = [best; kb_qubo_b_encode_slack(max(0, C - Wb) * (Wb <= C), C)];
  energy = x' * Q * x + c' * x + d;
  stats = struct();
  stats.iterations = total_iter;
  stats.restarts = opts.restarts;
  stats.tenure = tenure;
  stats.move_evaluations = total_iter * n;      % one energy change computed per item bit per iteration
  vars = whos();
  stats.working_memory_bytes = sum([vars.bytes]);  % includes Q, c (inputs) and search vectors
end

function [best_e, best, it] = restart(x, best_e, best, v, w, C, penalty, max_iter, stall_limit, tenure)
%RESTART  One restart of the sequential search from X, with the global best (BEST_E, BEST).
  n = numel(v);
  W = w' * x;
  V = v' * x;
  e = -V + penalty * max(0, W - C)^2;
  run_best = e;
  if e < best_e
    best_e = e;
    best = x;
  end
  tabu_until = zeros(n, 1);
  stall = 0;

  for it = 1:max_iter
    s = 1 - 2 * x;                          % +1 add item, -1 remove item
    W2 = W + s .* w;
    V2 = V + s .* v;
    delta = (-V2 + penalty * max(0, W2 - C) .^ 2) - e;
    allowed = (tabu_until < it) | (e + delta < best_e);
    if ~any(allowed)
      allowed = true(n, 1);
    end
    delta(~allowed) = Inf;
    [dmin, j] = min(delta);

    x(j) = x(j) + s(j);
    W = W2(j);
    V = V2(j);
    e = e + dmin;
    tabu_until(j) = it + tenure;

    if e < best_e
      best_e = e;
      best = x;
    end
    if e < run_best
      run_best = e;
      stall = 0;
    else
      stall = stall + 1;
      if stall > stall_limit
        break;
      end
    end
  end
end

function [lane_e, lane_x, lane_it, lane_asp] = lanes(x, v, w, C, penalty, max_iter, stall_limit, tenure)
%LANES  Every restart at once, column r from STARTS(:, r), moving on the moves that are not tabu
%   (on all of them when every move is tabu), as RESTART without aspiration, column by column.
%   LANE_E / LANE_X: best energy of each run and the vector where it was first reached;
%   LANE_IT: iterations; LANE_ASP: smallest e + delta of a tabu move that beats the chosen one
%   and the run's own best (the aspiration test with best_e = own best), +Inf if none. When
%   LANE_ASP is not below the best energy of the earlier restarts, the sequential run allows no
%   such move either: same search.
  [n, R] = size(x);
  lane_e = zeros(1, R);
  lane_x = x;
  lane_it = zeros(1, R);
  lane_asp = Inf(1, R);
  id = 1:R;                                   % restarts still searching (columns below)
  W = w' * x;
  V = v' * x;
  e = -V + penalty * max(0, W - C) .^ 2;
  run_best = e;
  own_e = e;                                  % own best energy, first reached at own_x
  own_x = x;
  asp = Inf(1, R);
  tabu_until = zeros(n, R);
  stall = zeros(1, R);
  for it = 1:max_iter
    s = 1 - 2 * x;
    W2 = W + s .* w;
    V2 = V + s .* v;
    delta = (-V2 + penalty * max(0, W2 - C) .^ 2) - e;
    [dall, k] = min(delta, [], 1);            % best move of all (first on ties)
    k = k + n * (0:numel(id) - 1);
    tabu = tabu_until >= it;
    none = all(tabu, 1);                      % every move tabu: all allowed
    a = tabu(k) & ~none & (e + dall < own_e); % a tabu move would win by aspiration
    asp(a) = min(asp(a), e(a) + dall(a));
    delta(tabu & ~none) = Inf;
    [dmin, k] = min(delta, [], 1);
    k = k + n * (0:numel(id) - 1);            % chosen move of each column

    x(k) = x(k) + s(k);
    W = W2(k);
    V = V2(k);
    e = e + dmin;
    tabu_until(k) = it + tenure;

    b = e < own_e;
    own_e(b) = e(b);
    own_x(:, b) = x(:, b);
    b = e < run_best;
    run_best(b) = e(b);
    stall(b) = 0;
    stall(~b) = stall(~b) + 1;
    b = stall > stall_limit;                  % these runs stop here
    if any(b)
      lane_e(id(b)) = own_e(b);
      lane_x(:, id(b)) = own_x(:, b);
      lane_it(id(b)) = it;
      lane_asp(id(b)) = asp(b);
      b = ~b;
      id = id(b);
      if isempty(id)
        return;
      end
      x = x(:, b);
      W = W(b);
      V = V(b);
      e = e(b);
      run_best = run_best(b);
      own_e = own_e(b);
      own_x = own_x(:, b);
      asp = asp(b);
      tabu_until = tabu_until(:, b);
      stall = stall(b);
    end
  end
  lane_e(id) = own_e;                         % runs that used every iteration
  lane_x(:, id) = own_x;
  lane_it(id) = floor(max_iter);
  lane_asp(id) = asp;
end
