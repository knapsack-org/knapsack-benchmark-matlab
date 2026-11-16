function bits = kb_chz_encode_slack(s, M)
%KB_CHZ_ENCODE_SLACK  Binary slack bits (as used by KB_CHZ_KNAPSACK2QUBO) for value S in 0..M.
%   [qubo_chz] Independent copy of the 'qubo' algorithm implementation, to be
%   modified separately; identical to the original when created (2026-11-14).
%   Bit weights are 1, 2, 4, ..., 2^(K-2) and R = M - (2^(K-1) - 1).
  k = max(1, ceil(log2(M + 1)));
  r = M - (2^(k-1) - 1);
  bits = zeros(k, 1);
  if s > 2^(k-1) - 1
    bits(k) = 1;
    s = s - r;
  end
  for j = 1:k-1
    bits(j) = mod(floor(s / 2^(j-1)), 2);
  end
end
