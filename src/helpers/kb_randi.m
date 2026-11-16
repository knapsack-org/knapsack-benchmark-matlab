function [r, state] = kb_randi(state, lo, hi, count)
%KB_RANDI  COUNT integers uniformly drawn from LO..HI with KB_LCG.
  if nargin < 4
    count = 1;
  end
  [u, state] = kb_lcg(state, count);
  r = lo + floor(u * (hi - lo + 1));
  r = min(r, hi);
end
