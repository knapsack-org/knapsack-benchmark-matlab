function [s_best, H_best, stats] = kb_ising_anneal(J, h, E0, acfg, seed, scale, a, P)
%KB_ISING_ANNEAL  Single-spin-flip simulated annealing of H(s) = 1/2 s'Js + h's + E0.
%   [S, H, STATS] = KB_ISING_ANNEAL(J, H, E0, ACFG, SEED, SCALE, A, P). Flipping spin j changes H by
%   -2 s_j g_j, where g = h + J s is the local field. Each restart starts from s_i = +1 if
%   u_i < 0.5 else -1 and runs steps_factor * N proposals (j = floor(u * N) + 1); a proposal is
%   accepted if dH <= 0 or u < exp(-dH / T); T falls geometrically from t0_factor * SCALE to
%   t_end_factor * SCALE (SCALE = P * max(w), the energy of flipping one heavy item). The uniforms
%   come from the portable LCG: the same sequence as the Python port.
%   Speed (same results): the uniforms of a restart come from KB_LCG_STATES and the temperatures
%   from CUMPROD (the same roundings as T = T * alpha). J = P/2 (A A' - diag(A.A)) (KB_ISING_MODEL),
%   so dH_i = s_i (-2 h_i - P A_i S) + P A_i^2 with S = A's: when P, A and 2h are integers, A > 0
%   and P (sum A)^2 < 2^48 (always within the request limits) every term is an exact integer, and
%   an accepted flip of j changes every dH_i by 2 P (A_i s_i) (A_j s_j) (one vector operation
%   instead of the update of g). Otherwise g is updated as before.
%   Returns the best spins (column of +-1) and their H; STATS: proposals, accepted, t_start, t_end.
  N = numel(h);
  m = 2147483647;
  steps = floor(acfg.steps_factor * N);
  t0 = acfg.t0_factor * scale;
  t1 = acfg.t_end_factor * scale;
  if steps > 1
    alpha = (t1 / t0) ^ (1 / (steps - 1));
  else
    alpha = 1;
  end
  Ts = cumprod([t0, repmat(alpha, 1, steps - 1)]);
  Ts = Ts(1:steps);
  a = a(:);
  fast = P == round(P) && all(a == round(a)) && all(a > 0) && all(2 * h == round(2 * h)) ...
         && P * sum(a)^2 < 2^48;
  P2 = 2 * P;
  state = kb_seed(seed);
  H_best = Inf;
  s_best = [];
  accepted = 0;
  for r = 1:acfg.restarts
    [u, state] = kb_lcg(state, N);
    s = ones(N, 1);
    s(u(:) >= 0.5) = -1;
    g = h + J * s;
    H = 0.5 * (s' * (g + h)) + E0;
    if H < H_best
      H_best = H;
      s_best = s;
    end
    X = kb_lcg_states(state, 2 * steps);     % a restart draws at most 2 numbers per step
    U = X / m;
    JJ = min(floor(U * N), N - 1) + 1;
    p = 0;                                     % draws used in this restart
    if fast
      dHv = -2 * s .* g;                       % dH of every spin
      as = a .* s;
      for T = Ts
        p = p + 1;
        j = JJ(p);
        dH = dHv(j);
        if dH > 0
          p = p + 1;
          if ~(U(p) < exp(-dH / T))
            continue;
          end
        end
        asj = as(j);
        dHv = dHv + (P2 * asj) * as;
        dHv(j) = -dH;
        as(j) = -asj;
        H = H + dH;
        accepted = accepted + 1;
        if H < H_best
          H_best = H;
          s_best = as ./ a;
        end
      end
    else
      for T = Ts
        p = p + 1;
        j = JJ(p);
        dH = -2 * s(j) * g(j);
        if dH > 0
          p = p + 1;
          if ~(U(p) < exp(-dH / T))
            continue;
          end
        end
        g = g + (-2 * s(j)) * J(:, j);
        s(j) = -s(j);
        H = H + dH;
        accepted = accepted + 1;
        if H < H_best
          H_best = H;
          s_best = s;
        end
      end
    end
    if p > 0
      state = X(p);
    end
  end
  stats = struct('proposals', acfg.restarts * steps, 'accepted', accepted, 't_start', t0, 't_end', t1);
end
