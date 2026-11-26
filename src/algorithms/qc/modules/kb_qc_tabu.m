function [best_x, best_f, stats] = kb_qc_tabu(Q, c, d, opts)
%KB_QC_TABU  Multi-start tabu search for  min x'*Q*x + c'*x + d,  x binary.
%   Q must be symmetric with a zero diagonal (as built by KB_QC_KNAPSACK2QUBO).
%   Each restart starts from a random binary vector and repeatedly flips the
%   bit with the best (smallest) energy change that is not tabu; a tabu bit
%   is allowed if it gives a new overall best (aspiration). Recently flipped
%   bits stay tabu for TENURE iterations.
%   OPTS fields: restarts, max_iter_factor, stall_factor, tenure_min, seed.
%   Deterministic for a given seed (uses KB_LCG, not rand).

  N = numel(c);
  c = c(:);
  max_iter = opts.max_iter_factor * N;
  stall_limit = opts.stall_factor * N;
  tenure = opts.tenure_min + round(N / 10);
  state = kb_seed(opts.seed);

  best_x = zeros(N, 1);
  best_f = d;                                 % energy of x = 0
  total_iter = 0;

  for r = 1:opts.restarts
    [u, state] = kb_lcg(state, N);
    x = double(u(:) < 0.5);
    g = c + 2 * (Q * x);                      % flip gain of bit i: (1 - 2 x_i) * g_i
    f = x' * Q * x + c' * x + d;
    run_best = f;
    tabu_until = zeros(N, 1);
    stall = 0;

    for it = 1:max_iter
      delta = (1 - 2 * x) .* g;
      allowed = (tabu_until < it) | (f + delta < best_f);
      if ~any(allowed)
        allowed = true(N, 1);
      end
      delta(~allowed) = Inf;
      [dmin, j] = min(delta);

      s = 1 - 2 * x(j);                       % +1: 0 -> 1, -1: 1 -> 0
      x(j) = x(j) + s;
      f = f + dmin;
      g = g + 2 * s * Q(:, j);
      tabu_until(j) = it + tenure;

      if f < best_f
        best_f = f;
        best_x = x;
      end
      if f < run_best
        run_best = f;
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

  stats = struct();
  stats.iterations = total_iter;
  stats.restarts = opts.restarts;
  stats.tenure = tenure;
  stats.move_evaluations = total_iter * N;      % one energy change computed per bit per iteration
  vars = whos();
  stats.working_memory_bytes = sum([vars.bytes]);  % includes Q, c (inputs) and search vectors
end
