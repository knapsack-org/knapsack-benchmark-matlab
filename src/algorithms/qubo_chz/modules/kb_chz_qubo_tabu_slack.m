function [x, energy, stats] = kb_chz_qubo_tabu_slack(v, w, C, penalty, Q, c, d, opts)
%KB_CHZ_QUBO_TABU_SLACK  Tabu search on the knapsack QUBO with optimal slack bits.
%   [qubo_chz] Independent copy of the 'qubo' algorithm implementation, to be
%   modified separately; identical to the original when created (2026-11-14).
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

  v = v(:);
  w = w(:);
  n = numel(v);
  max_iter = opts.max_iter_factor * n;
  stall_limit = opts.stall_factor * n;
  tenure = opts.tenure_min + round(n / 10);
  state = kb_seed(opts.seed);

  best = zeros(n, 1);
  best_e = 0;                                 % empty knapsack
  total_iter = 0;

  for r = 1:opts.restarts
    [u, state] = kb_lcg(state, n);
    x = double(u(:) < 0.5);
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
    total_iter = total_iter + it;
  end

  Wb = w' * best;
  x = [best; kb_chz_encode_slack(max(0, C - Wb) * (Wb <= C), C)];
  energy = x' * Q * x + c' * x + d;
  stats = struct();
  stats.iterations = total_iter;
  stats.restarts = opts.restarts;
  stats.tenure = tenure;
  stats.move_evaluations = total_iter * n;      % one energy change computed per item bit per iteration
  vars = whos();
  stats.working_memory_bytes = sum([vars.bytes]);  % includes Q, c (inputs) and search vectors
end
