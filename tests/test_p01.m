function test_p01()
%TEST_P01  Smoke test on the reference instance P01 (optimum 309, items 1 2 3 4 6):
%   every discovered algorithm through its adapter (exact -> 309, heuristic ->
%   feasible, entry and details valid against its JSON Schema), then the
%   algorithm-specific checks: DP, branch and bound, ILP, knapsack -> QUBO, tabu
%   searches, slack encoding, and the qubo_chz copy (must match qubo).
%   Run from the project root:  octave-cli --eval "addpath('tests'); test_p01"
  root = fileparts(fileparts(mfilename('fullpath')));
  addpath(root, genpath(fullfile(root, 'src')));

  w = [23 31 29 44 53 38 63 85 89 82];
  v = [92 57 49 68 60 43 67 84 87 72];
  C = 165;

  % every algorithm of src/algorithms/, as the benchmark runs it (no edit needed for a new one)
  cfg = benchmark_config();
  [algos, skipped] = kb_discover_algorithms();
  assert(sum([algos.reference]) == 1, 'exactly one reference algorithm');
  for a = 1:numel(algos)
    A = algos(a);
    out = A.output.run(v, w, C, cfg.(A.id), cfg.seed);
    value = sum(v(out.items));
    assert(sum(w(out.items)) <= C, sprintf('%s: infeasible packing on P01', A.id));
    if A.exact
      assert(value == 309, sprintf('%s: exact algorithm should find 309, got %g', A.id, value));
    end
    kb_validate_schema(out.details, A.output.schema.details, [A.id '.details']);
    kb_validate_schema(A.output.entry(cfg.(A.id), A.environment), A.output.schema.entry, A.id);
  end
  for s = 1:numel(skipped)
    fprintf('test_p01: %s not available here, skipped\n', skipped{s}.id);
  end

  % the schema validator rejects what it must
  sch = jsondecode(['{"type": "object", "additionalProperties": false, "required": ["a"],' ...
                    ' "properties": {"a": {"type": "integer", "minimum": 0}}}']);
  kb_validate_schema(struct('a', 2), sch);
  bad = {struct('a', -1), struct('a', 1.5), struct('b', 1), struct('a', 1, 'b', 2), {1}};
  for i = 1:numel(bad)
    try
      kb_validate_schema(bad{i}, sch);
      error('test_p01:accepted', 'validator accepted bad value %d', i);
    catch err
      assert(strcmp(err.identifier, 'kb_validate_schema:invalid'), err.message);
    end
  end

  [items, info] = kp_algo_dp_main(v, w, C);
  assert(info.value == 309, 'DP optimum should be 309');
  assert(isequal(items, [1 2 3 4 6]), 'DP items should be 1 2 3 4 6');

  [items, info] = kp_algo_bnb_main(v, w, C);
  assert(info.value == 309 && isequal(items, [1 2 3 4 6]) && info.proven_optimal, 'B&B should find 309');

  [items, info] = kp_algo_bnb_main(v, w, C, struct('max_nodes', 3));   % node limit -> not proven
  assert(info.value <= 309, 'B&B with node limit');

  if ~isempty(kb_ilp_solver_name())
    [items, info] = kp_algo_ilp_main(v, w, C);
    assert(info.value == 309 && isequal(items, [1 2 3 4 6]) && info.proven_optimal, ...
           'ILP should find 309');
  else
    disp('test_p01: no ILP solver, ILP check skipped');
  end

  % MathWorks knapsack2qubo example 1: 10 variables, constant 289, energy -16
  [Q, c, d] = kb_knapsack2qubo([5 2 8 4 3], [9 8 4 5 2], 17, 1);
  assert(numel(c) == 10 && d == 289, 'QUBO size/constant mismatch with MathWorks example');
  x = [1 0 1 0 1 0 1 0 0 0]';            % items 1,3,5 + slack 2 (bit weights 1 2 4 8 2)
  assert(x' * Q * x + c' * x + d == -16, 'QUBO energy of the known optimum should be -16');

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

  % greedy: feasible, at least half of the optimum
  [items, info] = kp_algo_greedy_main(v, w, C);
  assert(sum(w(items)) <= C && sum(v(items)) >= 309 / 2 && info.operations == 10, 'greedy on P01');

  % FPTAS: value >= (1 - epsilon) * 309 for several epsilon, items feasible
  for eps = [0.05 0.2 0.5 1]
    items = kp_algo_fptas_main(v, w, C, struct('epsilon', eps));
    assert(sum(w(items)) <= C && sum(v(items)) >= (1 - eps) * 309, 'fptas guarantee on P01');
  end
  items = kp_algo_fptas_main(v, w, C, struct('epsilon', 0.01));
  assert(isequal(items, [1 2 3 4 6]), 'fptas with a tiny epsilon should be exact on P01');

  % Ising model: H(sigma) = QUBO energy of z = (1 + sigma) / 2 (MathWorks example 1 data)
  [Q, c, d] = kb_knapsack2qubo([5 2 8 4 3], [9 8 4 5 2], 17, 1);
  [J, h, E0, K] = kb_ising_model([5 2 8 4 3], [9 8 4 5 2], 17, 1);
  assert(K == 5 && isequal(J, J') && all(diag(J) == 0), 'ising model shape');
  for t = 1:50
    z = double(rand(10, 1) < 0.5);
    s = 2 * z - 1;
    assert(abs((0.5 * s' * J * s + h' * s + E0) - (z' * Q * z + c' * z + d)) < 1e-9, ...
           'Ising energy differs from the QUBO energy');
  end

  % sa, ga, ising: reproducible for a given seed, feasible packing
  for id = {'sa', 'ga', 'ising'}
    f = str2func(['kp_algo_' id{1} '_main']);
    a1 = f(v, w, C, cfg.(id{1}), 7);
    a2 = f(v, w, C, cfg.(id{1}), 7);
    assert(isequal(a1, a2) && sum(w(a1)) <= C, [id{1} ': not reproducible or infeasible']);
  end

  disp('test_p01: all checks passed');
end
