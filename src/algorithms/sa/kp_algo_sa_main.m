function [items, info] = kp_algo_sa_main(v, w, C, acfg, seed, ~)
%KP_ALGO_SA_MAIN  Single-bit-flip simulated annealing on the item bits.
%   [ITEMS, INFO] = KP_ALGO_SA_MAIN(V, W, C, ACFG, SEED): ACFG = cfg.sa, SEED = cfg.seed + 1000*k.
%   Energy E(x) = -V(x) + P * max(0, W(x) - C)^2, P = penalty ('auto' = max(v) + 1).
%   Each restart starts from x_i = [u_i < 0.5] and runs steps = steps_factor * n proposals:
%   a proposal flips item j = floor(u * n) + 1 and is accepted if dE <= 0 or u < exp(-dE / T).
%   T falls geometrically from t0_factor * max(v) to t_end_factor * max(v).
%   The best FEASIBLE packing seen (the empty packing at least) is returned (1-based ITEMS).
%   The uniforms come from the portable LCG: the same sequence as the Python port.
%   Speed (same results): the uniforms of a restart come from KB_LCG_STATES and the temperatures
%   from CUMPROD (the same roundings as T = T * alpha). The energy change dE of every item is kept
%   in a vector (recomputed after an accepted flip with the scalar formula, elementwise) and the
%   next accepted proposal is found by a vectorised scan: until then every proposal is an uphill
%   rejection that uses 2 numbers, so the candidates of a scan are known in advance.
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
  accepted = 0;
  Ts = cumprod([t0, repmat(alpha, 1, steps - 1)]);
  mTs = -Ts(1:steps);                      % -T of each step: exp(dE / -T) = exp(-dE / T)
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
    X = kb_lcg_states(state, 2 * steps);   % a restart draws at most 2 numbers per step
    U = X / m;
    JJ = min(floor(U * n), n - 1) + 1;     % item of a proposal drawn at each position
    U1 = [U(2:end), 1];                    % its acceptance number (next position)
    sw = (1 - 2 * x) .* w;                 % weight change of flipping each item
    sv = (1 - 2 * x) .* v;
    dEv = (-(V + sv) + P * max(0, (W + sw) - C) .^ 2) - E;
    t = 1;                                 % next step
    q = 1;                                 % next draw
    while t <= steps
      L = 64;
      if t + L > steps
        L = steps - t + 1;
      end
      qq = q + (0:2:2 * L - 2);            % positions while every proposal is rejected
      cj = JJ(qq);
      cd = dEv(cj);
      k = find(cd <= 0 | U1(qq) < exp(cd ./ mTs(t:t + L - 1)), 1);
      if isempty(k)                        % L uphill rejections
        t = t + L;
        q = q + 2 * L;
        continue;
      end
      j = cj(k);                           % step t + k - 1 accepts item j
      dE = cd(k);
      t = t + k;
      q = qq(k) + 1 + (dE > 0);
      x(j) = ~x(j);
      W = W + sw(j);
      V = V + sv(j);
      E = E + dE;
      sw(j) = -sw(j);
      sv(j) = -sv(j);
      accepted = accepted + 1;
      if W <= C && V > best_v
        best_v = V;
        best_x = x;
      end
      dEv = (-(V + sv) + P * max(0, (W + sw) - C) .^ 2) - E;
    end
    if q > 1
      state = X(q - 1);
    end
  end
  proposals = acfg.restarts * steps;
  items = find(best_x);
  info = struct('penalty', P, 'proposals', proposals, 'accepted', accepted, ...
                't_start', t0, 't_end', t1, 'working_memory_bytes', kb_bytes(v, w, x, best_x));
end
