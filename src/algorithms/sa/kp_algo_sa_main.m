function [items, info] = kp_algo_sa_main(v, w, C, acfg, seed, ~)
%KP_ALGO_SA_MAIN  Single-bit-flip simulated annealing on the item bits.
%   [ITEMS, INFO] = KP_ALGO_SA_MAIN(V, W, C, ACFG, SEED): ACFG = cfg.sa, SEED = cfg.seed + 1000*k.
%   Energy E(x) = -V(x) + P * max(0, W(x) - C)^2, P = penalty ('auto' = max(v) + 1).
%   Each restart starts from x_i = [u_i < 0.5] and runs steps = steps_factor * n proposals:
%   a proposal flips item j = floor(u * n) + 1 and is accepted if dE <= 0 or u < exp(-dE / T).
%   T falls geometrically from t0_factor * max(v) to t_end_factor * max(v).
%   The best FEASIBLE packing seen (the empty packing at least) is returned (1-based ITEMS).
%   The uniforms come from the portable LCG (KB_LCG), inlined in the loop for speed: the same
%   sequence as the Python port.
%   INFO: penalty, proposals, accepted, t_start, t_end, working_memory_bytes.
  v = v(:)';
  w = w(:)';
  n = numel(v);
  if ischar(acfg.penalty)
    P = max(v) + 1;
  else
    P = acfg.penalty;
  end
  m = 2147483647;
  steps = floor(acfg.steps_factor * n);
  vmax = max(v);
  t0 = acfg.t0_factor * vmax;
  t1 = acfg.t_end_factor * vmax;
  if steps > 1
    alpha = (t1 / t0) ^ (1 / (steps - 1));
  else
    alpha = 1;
  end
  state = kb_seed(seed);
  best_v = 0;
  best_x = false(1, n);
  proposals = 0;
  accepted = 0;
  for r = 1:acfg.restarts
    [u, state] = kb_lcg(state, n);
    x = u < 0.5;
    W = sum(w(x));
    V = sum(v(x));
    E = -V + P * max(0, W - C)^2;
    if W <= C && V > best_v
      best_v = V;
      best_x = x;
    end
    T = t0;
    for s = 1:steps
      state = mod(16807 * state, m);
      j = min(floor(state / m * n), n - 1) + 1;
      if x(j)
        W2 = W - w(j);
        V2 = V - v(j);
      else
        W2 = W + w(j);
        V2 = V + v(j);
      end
      dE = (-V2 + P * max(0, W2 - C)^2) - E;
      proposals = proposals + 1;
      ok = dE <= 0;
      if ~ok
        state = mod(16807 * state, m);
        ok = state / m < exp(-dE / T);
      end
      if ok
        x(j) = ~x(j);
        W = W2;
        V = V2;
        E = E + dE;
        accepted = accepted + 1;
        if W <= C && V > best_v
          best_v = V;
          best_x = x;
        end
      end
      T = T * alpha;
    end
  end
  items = find(best_x);
  info = struct('penalty', P, 'proposals', proposals, 'accepted', accepted, ...
                't_start', t0, 't_end', t1, 'working_memory_bytes', kb_bytes(v, w, x, best_x));
end
