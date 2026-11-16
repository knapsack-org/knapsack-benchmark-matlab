function state = kb_seed(seed)
%KB_SEED  Turn any integer seed into a valid KB_LCG state (1 .. 2^31-2).
  state = mod(floor(abs(seed)), 2147483646) + 1;
end
