function bits = kb_qubo_b_encode_slack(s, M)
%KB_QUBO_B_ENCODE_SLACK  Binary slack bits (as used by KB_QUBO_B_KNAPSACK2QUBO) for value S in 0..M.
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
