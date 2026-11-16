function p = kb_penalty(values, rule)
%KB_PENALTY  QUBO penalty: 'auto' (any char) -> max(values) + 1, else the given number.
  % 'auto' -> max(value) + 1: every infeasible packing then costs more than it gains,
  % so the QUBO minimum is the knapsack optimum.
  if ischar(rule)
    p = max(values) + 1;
  else
    p = rule;
  end
end
