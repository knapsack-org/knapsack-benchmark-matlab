function x = kb_lcg_states(state, count)
%KB_LCG_STATES  The next COUNT states of KB_LCG from STATE, in O(log COUNT) vector operations.
%   X = KB_LCG_STATES(STATE, COUNT): X(k) = 16807^k * STATE mod (2^31 - 1) is the state after k
%   draws (row vector), so X / (2^31 - 1) are the numbers that COUNT calls of KB_LCG return and
%   X(k) is the generator state after k of them. The powers of 16807 are built by doubling;
%   products are split (MULMOD) so every double stays below 2^47 (exact).
  m = 2147483647;
  x = zeros(1, count);
  x(1:min(count, 1)) = 16807;
  k = 1;
  while k < count                      % x(k + i) = 16807^(k + i) = x(i) * x(k)
    c = min(k, count - k);
    x(k + 1:k + c) = mulmod(x(1:c), x(k), m);
    k = k + c;
  end
  x = mulmod(x, state, m);
end

function r = mulmod(a, b, m)
  bh = floor(b / 32768);               % b = bh * 2^15 + bl; a, b < 2^31
  r = mod(mod(a * bh, m) * 32768 + a * (b - bh * 32768), m);
end
