function [Q, c, d, k] = kb_qubo_b_knapsack2qubo(v, w, M, penalty)
%KB_QUBO_B_KNAPSACK2QUBO  0-1 knapsack -> QUBO  f(x) = x'*Q*x + c'*x + d.
%   Same formulation as MATLAB's knapsack2qubo (Quantum Computing support
%   package, R2025b), rebuilt so it also runs in Octave:
%     f = -sum(v .* x) + penalty * (sum(w .* x) + s - M)^2
%   The slack s in 0..M is binary-encoded with K bits of weights
%   1, 2, 4, ..., M - (2^(K-1) - 1), so it can take every value 0..M.
%   x = [items (n); slack bits (K)].  Q is symmetric with a zero diagonal.
%   With penalty > max(v) the QUBO minimum is the knapsack optimum.

  if nargin < 4
    penalty = 1;
  end
  v = v(:);
  w = w(:);
  M = floor(M);
  k = max(1, ceil(log2(M + 1)));                 % number of slack bits
  b = [2 .^ (0:k-2), M - (2^(k-1) - 1)]';         % slack coefficients
  a = [w; b];                                     % constraint coefficients
  Q = penalty * (a * a');
  Q(1:size(Q, 1) + 1:end) = 0;                    % x_i^2 = x_i -> moved to c
  c = [-v; zeros(k, 1)] + penalty * (a .^ 2 - 2 * M * a);
  d = penalty * M ^ 2;
end
