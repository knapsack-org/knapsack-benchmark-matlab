function [x, energy, stats] = kb_qc_qaoa(Q, c, d, opts)
%KB_QC_QAOA  QAOA on the QUBO f(x) = x'*Q*x + c'*x + d, simulated on a state vector.
%   [X, ENERGY, STATS] = KB_QC_QAOA(Q, C, D, OPTS) (same outputs as KB_QC_TABU):
%     - E(z) = f(z) for every basis state z of the N = numel(C) qubits (bit j of z-1 = x(j+1));
%     - start |+>^N; each layer l applies the cost phase exp(-1i*gamma(l)*Es) with the energies
%       scaled to Es = (E - min E) / (max E - min E) in [0, 1], then the mixer exp(-1i*beta(l)*X)
%       on every qubit;
%     - angles: deterministic search of the expected Es (no fminsearch, so MATLAB = Python):
%       layer by layer a GRID x GRID search of (gamma, beta) on (0, 2*pi) x (0, pi) with the
%       earlier layers fixed, then REFINE rounds of +-h coordinate moves on every angle (h halved
%       after each round); a move or grid point is taken only if it improves by more than 1e-12;
%     - SHOTS states sampled with KB_LCG from the final state; X is the sampled state of lowest
%       E (first sampled on ties), ENERGY = f(X).
%   OPTS fields: layers, shots, grid, refine, max_qubits, seed.
%   STATS: iterations (objective evaluations), move_evaluations (same), working_memory_bytes,
%          gamma, beta, expected_energy (scaled, of the chosen angles).
%   2^N complex amplitudes: N > OPTS.max_qubits is an error (identifier kb_qc_qaoa:tooLarge).
  c = c(:);
  N = numel(c);
  if N > opts.max_qubits
    error('kb_qc_qaoa:tooLarge', 'QAOA: %d qubits > max_qubits = %d (2^N amplitudes).', ...
          N, opts.max_qubits);
  end
  S = 2 ^ N;
  idx = (0:S - 1)';
  B = false(S, N);                       % B(z, j) = bit j-1 of z-1
  for j = 1:N
    B(:, j) = mod(floor(idx / 2 ^ (j - 1)), 2) == 1;
  end
  E = d + zeros(S, 1);                   % integer energies: exact in doubles
  for j = 1:N
    bj = double(B(:, j));
    E = E + (c(j) + Q(j, j)) * bj;
    for i = 1:j - 1
      if Q(i, j) + Q(j, i) ~= 0
        E = E + (Q(i, j) + Q(j, i)) * (double(B(:, i)) .* bj);
      end
    end
  end
  lo = min(E);
  span = max(E) - lo;
  if span == 0
    span = 1;
  end
  Es = (E - lo) / span;

  evals = 0;
  G = opts.grid;
  gamma = zeros(1, opts.layers);
  beta = zeros(1, opts.layers);
  best_f = Inf;
  for l = 1:opts.layers                  % layer by layer, earlier layers fixed
    best_f = Inf;
    g_best = 0;
    b_best = 0;
    for gi = 1:G
      for bi = 1:G
        gamma(l) = 2 * pi * (gi - 0.5) / G;
        beta(l) = pi * (bi - 0.5) / G;
        f = expected(gamma(1:l), beta(1:l));
        evals = evals + 1;
        if f < best_f - 1e-12
          best_f = f;
          g_best = gamma(l);
          b_best = beta(l);
        end
      end
    end
    gamma(l) = g_best;
    beta(l) = b_best;
  end
  h = [2 * pi / G, pi / G];               % step for gamma, beta
  for r = 1:opts.refine
    for l = 1:opts.layers
      for kind = 1:2
        for s = [1, -1]
          g = gamma;
          b = beta;
          if kind == 1
            g(l) = g(l) + s * h(1);
          else
            b(l) = b(l) + s * h(2);
          end
          f = expected(g, b);
          evals = evals + 1;
          if f < best_f - 1e-12
            best_f = f;
            gamma = g;
            beta = b;
          end
        end
      end
    end
    h = h / 2;
  end

  psi = evolve(gamma, beta);
  p = abs(psi) .^ 2;
  cp = cumsum(p);
  u = kb_lcg(kb_seed(opts.seed), opts.shots);
  best_z = 0;
  energy = Inf;
  for k = 1:opts.shots
    z = find(cp >= u(k) * cp(end), 1);
    if isempty(z)
      z = S;
    end
    if E(z) < energy
      energy = E(z);
      best_z = z;
    end
  end
  x = double(B(best_z, :))';
  stats = struct('iterations', evals, 'move_evaluations', evals, ...
                 'working_memory_bytes', kb_bytes(B, E, Es, psi, cp), ...
                 'gamma', gamma, 'beta', beta, 'expected_energy', best_f);

  function f = expected(g, b)
    q = evolve(g, b);
    f = sum((abs(q) .^ 2) .* Es);
  end

  function q = evolve(g, b)
    q = complex(ones(S, 1) / sqrt(S));
    for t = 1:numel(g)
      q = q .* exp(-1i * g(t) * Es);
      cb = cos(b(t));
      sb = -1i * sin(b(t));
      for j = 1:N                       % exp(-1i*beta*X) on qubit j: pairs (bit 0, bit 1)
        R = reshape(q, 2 ^ (j - 1), 2, []);
        a0 = R(:, 1, :);
        a1 = R(:, 2, :);
        R(:, 1, :) = cb * a0 + sb * a1;
        R(:, 2, :) = sb * a0 + cb * a1;
        q = R(:);
      end
    end
  end
end
