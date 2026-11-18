function [J, h, E0, slack_bits] = kb_ising_model(v, w, C, P)
%KB_ISING_MODEL  Ising Hamiltonian of the penalty form f = -sum(v x) + P (sum(w x) + s - C)^2.
%   [J, H, E0, K] = KB_ISING_MODEL(V, W, C, P): s is written on K = max(1, ceil(log2(C + 1)))
%   slack bits of weights 1, 2, 4, ... with the last one truncated so that the largest slack
%   is exactly C (same encoding as the 'qubo' algorithm). With z = [x; y], a = [w; b],
%     Q = P (a a' - diag(a.a)),  c = [-v; 0] + P (a.a - 2 C a),  d = P C^2
%   the QUBO is z'Qz + c'z + d. Substituting z = (1 + sigma) / 2, sigma in {-1, +1}^N, gives
%     H(sigma) = 1/2 sigma' J sigma + h' sigma + E0
%     J = Q / 2 (symmetric, zero diagonal),  h = Q 1 / 2 + c / 2,  E0 = d + 1'Q1 / 4 + 1'c / 2
%   and H(sigma) equals the QUBO energy of z. H is a column vector.
  v = v(:)';
  w = w(:)';
  K = max(1, ceil(log2(C + 1)));
  b = 2 .^ (0:K - 1);
  b(K) = C - (2^(K - 1) - 1);
  a = [w, b];
  c = [-v, zeros(1, K)] + P * (a .* a - 2 * C * a);
  Q = P * (a' * a - diag(a .* a));
  J = Q / 2;
  h = sum(Q, 2) / 2 + c' / 2;
  E0 = P * C * C + sum(Q(:)) / 4 + sum(c) / 2;
  slack_bits = K;
end
