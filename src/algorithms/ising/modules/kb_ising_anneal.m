function [s_best, H_best, stats] = kb_ising_anneal(J, h, E0, acfg, seed, scale)
%KB_ISING_ANNEAL  Single-spin-flip simulated annealing of H(s) = 1/2 s'Js + h's + E0.
%   [S, H, STATS] = KB_ISING_ANNEAL(J, H, E0, ACFG, SEED, SCALE). Flipping spin j changes H by
%   -2 s_j g_j, where g = h + J s is the local field (updated in O(N) after an accepted flip).
%   Each restart starts from s_i = +1 if u_i < 0.5 else -1 and runs steps_factor * N proposals
%   (j = floor(u * N) + 1); a proposal is accepted if dH <= 0 or u < exp(-dH / T); T falls
%   geometrically from t0_factor * SCALE to t_end_factor * SCALE
%   (SCALE = P * max(w), the energy of flipping one heavy item). The uniforms come from the
%   portable LCG (KB_LCG), inlined in the loop for speed: the same sequence as the Python port.
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
  state = kb_seed(seed);
  H_best = Inf;
  s_best = [];
  proposals = 0;
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
    T = t0;
    for k = 1:steps
      state = mod(16807 * state, m);
      j = min(floor(state / m * N), N - 1) + 1;
      dH = -2 * s(j) * g(j);
      proposals = proposals + 1;
      ok = dH <= 0;
      if ~ok
        state = mod(16807 * state, m);
        ok = state / m < exp(-dH / T);
      end
      if ok
        g = g + (-2 * s(j)) * J(:, j);
        s(j) = -s(j);
        H = H + dH;
        accepted = accepted + 1;
        if H < H_best
          H_best = H;
          s_best = s;
        end
      end
      T = T * alpha;
    end
  end
  stats = struct('proposals', proposals, 'accepted', accepted, 't_start', t0, 't_end', t1);
end
