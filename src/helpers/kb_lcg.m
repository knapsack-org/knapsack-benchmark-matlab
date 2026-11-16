function [u, state] = kb_lcg(state, count)
%KB_LCG  Portable pseudo-random numbers (Park-Miller minimal standard LCG).
%   [U, STATE] = KB_LCG(STATE, COUNT) returns COUNT numbers in (0, 1) and the
%   updated STATE (integer in 1 .. 2^31-2).
%   Used instead of rand() so MATLAB, Octave and Python produce exactly the
%   same instances and runs (all products stay below 2^53, so doubles are exact).
  if nargin < 2
    count = 1;
  end
  m = 2147483647;
  u = zeros(1, count);
  for i = 1:count
    state = mod(16807 * state, m);
    u(i) = state / m;
  end
end
