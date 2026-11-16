function test_p01()
%TEST_P01  Smoke test on the reference instance P01 (optimum 309, items 1 2 3 4 6):
%   DP, branch and bound, ILP, knapsack -> QUBO, tabu searches, slack encoding,
%   and the qubo_chz copy (must match qubo).
%   Run from the project root:  octave-cli --eval "addpath('tests'); test_p01"
  root = fileparts(fileparts(mfilename('fullpath')));
  addpath(root, genpath(fullfile(root, 'src')));

  w = [23 31 29 44 53 38 63 85 89 82];
  v = [92 57 49 68 60 43 67 84 87 72];
  C = 165;

  [best, items] = kb_knapsack_dp(v, w, C);
  assert(best == 309, 'DP optimum should be 309');
  assert(isequal(items, [1 2 3 4 6]), 'DP items should be 1 2 3 4 6');

  [best, items, info] = kb_knapsack_bnb(v, w, C);
  assert(best == 309 && isequal(items, [1 2 3 4 6]) && info.proven_optimal, 'B&B should find 309');

  [best, items] = kb_knapsack_bnb(v, w, C, 3);            % node limit -> not proven
  assert(best <= 309, 'B&B with node limit');

  if exist('glpk') > 0 || exist('intlinprog') > 0
    [best, items, info] = kb_knapsack_ilp(v, w, C);
    assert(best == 309 && isequal(items, [1 2 3 4 6]) && info.proven_optimal, ...
           'ILP should find 309');
  else
    disp('test_p01: no ILP solver, ILP check skipped');
  end

  % MathWorks knapsack2qubo example 1: 10 variables, constant 289, energy -16
  [Q, c, d] = kb_knapsack2qubo([5 2 8 4 3], [9 8 4 5 2], 17, 1);
  assert(numel(c) == 10 && d == 289, 'QUBO size/constant mismatch with MathWorks example');
  x = [1 0 1 0 1 0 1 0 0 0]';            % items 1,3,5 + slack 2 (bit weights 1 2 4 8 2)
  assert(x' * Q * x + c' * x + d == -16, 'QUBO energy of the known optimum should be -16');

  cfg = benchmark_config();
  opts = cfg.qubo.tabu;
  opts.seed = 1;
  [Q, c, d] = kb_knapsack2qubo(v, w, C, max(v) + 1);
  [x, f] = kb_qubo_tabu_slack(v, w, C, max(v) + 1, Q, c, d, opts);
  sol = kb_decode(x, v, w, C);
  assert(sol.feasible && sol.final_value == 309, 'slack-optimal tabu should reach 309 on P01');
  assert(f == -309, 'best QUBO energy should be -309');

  [x, f] = kb_qubo_tabu(Q, c, d, opts);         % plain all-bits tabu: must stay feasible
  sol = kb_decode(x, v, w, C);
  assert(sol.final_weight <= C && abs(x' * Q * x + c' * x + d - f) < 1e-9, ...
         'all-bits tabu returned an inconsistent solution');

  % qubo_chz copy must behave like the original
  [Qz, cz, dz] = kb_chz_knapsack2qubo(v, w, C, max(v) + 1);
  [Q, c, d] = kb_knapsack2qubo(v, w, C, max(v) + 1);
  assert(isequal(Qz, Q) && isequal(cz, c) && dz == d, 'qubo_chz model differs from qubo');
  [xz, fz] = kb_chz_qubo_tabu_slack(v, w, C, max(v) + 1, Qz, cz, dz, opts);
  [xq, fq] = kb_qubo_tabu_slack(v, w, C, max(v) + 1, Q, c, d, opts);
  assert(isequal(xz, xq) && fz == fq && fz == -309, 'qubo_chz tabu differs from qubo');
  solz = kb_chz_decode(xz, v, w, C);
  assert(solz.final_value == 309, 'qubo_chz should reach 309 on P01');

  for s = 0:17                                  % slack encoding round trip (M = 17)
    assert(sum(kb_encode_slack(s, 17)' .* [1 2 4 8 2]) == s, 'slack encoding');
    assert(isequal(kb_chz_encode_slack(s, 17), kb_encode_slack(s, 17)), 'qubo_chz slack encoding');
  end

  disp('test_p01: all checks passed');
end
