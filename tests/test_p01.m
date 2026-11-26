function test_p01()
%TEST_P01  Smoke test on the reference instance P01 (optimum 309, items 1 2 3 4 6):
%   every discovered algorithm through its adapter (exact -> 309, heuristic ->
%   feasible, entry, config and details keys as in its kp_algo_<id>_output.schema.json),
%   run_benchmark('--describe'), a request + instances.json + shard round trip
%   (global seeds), then the algorithm-specific checks: DP, branch and bound, ILP,
%   knapsack -> QUBO, tabu searches, slack encoding.
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
    schema = jsondecode(fileread(A.schema_file));
    e = A.output.entry(cfg.(A.id), A.environment);
    conforms(out.details, schema.details, [A.id '.details']);
    conforms(e, schema.entry, A.id);
    conforms(e.config, schema.config, [A.id '.config']);
  end
  for s = 1:numel(skipped)
    fprintf('test_p01: %s not available here, skipped\n', skipped{s}.id);
  end

  % --describe: every algorithm with its default settings and schema files (knapsack-server catalog)
  d = jsondecode(evalc('run_benchmark(''--describe'');'));
  assert(strcmp(d.project, 'knapsack-benchmark-matlab') && numel(d.algorithms) == numel(algos), 'describe');
  assert(numel(algos) + numel(skipped) == 11, 'describe: 11 algorithm folders');
  assert(isequal(sort(fieldnames(d.algorithm_schemas))', sort({algos.id})), 'describe: one schema each');
  for i = 1:numel(algos)
    assert(all(isfield(d.algorithm_schemas.(algos(i).id), {'entry', 'config', 'details'})), 'describe: parts');
  end

  % request overrides, instances.json, and a shard with global ids gives the same results (P7)
  tmp = tempname();
  mkdir(tmp);
  write_text(fullfile(tmp, 'req.json'), ['{"seed": 7, "instances": {"count": 3, "max_items": 12},' ...
             ' "algorithms": ["sa"], "algorithm_config": {"sa": {"restarts": 1}}}']);
  run_benchmark(fullfile(tmp, 'req.json'), '', fullfile(tmp, 'full'));
  full = jsondecode(fileread(fullfile(tmp, 'full', 'raw.json')));
  iset = jsondecode(fileread(fullfile(tmp, 'full', 'instances.json')));
  assert(strcmp(full.format, 'knapsack-raw') && full.format_version == 1, 'raw format');
  assert(isequal(full.parameters.algorithms(:)', {'dp', 'sa'}) && full.parameters.sa.restarts == 1 ...
         && full.instance_config.seed == 7 && full.instance_config.max_items == 12, 'request applied');
  assert(strcmp(iset.format, 'knapsack-instances') && isequal([iset.instances.id], 1:3), 'instances.json');
  assert(~isfield(full.instances(1).results.sa, 'is_optimal'), 'raw results only');
  iset.instances = {iset.instances(2)};          % shard: instance 2 only
  write_text(fullfile(tmp, 'shard.json'), jsonencode(iset));
  write_text(fullfile(tmp, 'req2.json'), '{"algorithms": ["sa"], "algorithm_config": {"sa": {"restarts": 1}}}');
  run_benchmark(fullfile(tmp, 'req2.json'), fullfile(tmp, 'shard.json'), fullfile(tmp, 'shard'));
  part = jsondecode(fileread(fullfile(tmp, 'shard', 'raw.json')));
  assert(~exist(fullfile(tmp, 'shard', 'instances.json'), 'file'), 'no instances.json with an instances file');
  assert(part.parameters.seed == 7 && numel(part.instances) == 1 && part.instances(1).id == 2, 'shard');
  for id = {'dp', 'sa'}
    a = part.instances(1).results.(id{1});
    b = full.instances(2).results.(id{1});
    assert(a.value == b.value && isequal(a.items, b.items) && isequal(a.details, b.details), ...
           [id{1} ': shard result differs']);
  end
  try
    kb_discover_algorithms({'julia'});
    error('test_p01:accepted', 'unknown algorithm accepted');
  catch err
    assert(strcmp(err.identifier, 'kb_discover_algorithms:unknown'), err.message);
  end
  try
    kb_merge_settings(struct('repeats', 1), struct('nope', 1), 'sa');
    error('test_p01:accepted', 'unknown setting accepted');
  catch err
    assert(strcmp(err.identifier, 'kb_merge_settings:unknown'), err.message);
  end
  if exist('confirm_recursive_rmdir', 'builtin') || exist('confirm_recursive_rmdir', 'file')
    confirm_recursive_rmdir(false);
  end
  rmdir(tmp, 's');

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
    [~, info] = kp_algo_ilp_main(v, w, C, 10);
    assert(info.value == 309 && info.proven_optimal, 'ILP with a time limit should still find 309');
    % instance 69 of seed 2026, 10..100 items, ratio 0.7 (strongly correlated, n = 72): GLPK needed ~20 min
    hard = kb_generate_instances(100, 2026, 10, 100, 100, 0.7);
    hard = hard(69);
    assert(strcmp(hard.family, 'strongly_correlated') && numel(hard.weights) == 72, 'hard ILP instance');
    t = tic;
    [items, info] = kp_algo_ilp_main(hard.values, hard.weights, hard.capacity, 0.05);
    assert(~info.proven_optimal && toc(t) < 5 && sum(hard.weights(items)) <= hard.capacity, ...
           'ILP time limit');
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

  for s = 0:17                                  % slack encoding round trip (M = 17)
    assert(sum(kb_encode_slack(s, 17)' .* [1 2 4 8 2]) == s, 'slack encoding');
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

  % instance correlation settings (ADR 0023): defaults = the former generator, families, ratios
  ic = kb_config_instances();
  a = kb_generate_instances(30, 2026, 10, 20, 100, 0.5);
  b = kb_generate_instances(30, 2026, 10, 20, 100, 0.5, ic.correlation);
  assert(isequal(a, b) && isequal({a(1:3).family}, ic.correlation.families), 'correlation defaults');
  cs = ic.correlation;
  cs.families = {'strongly_correlated'};
  cs.strong_offset_ratio = 0.2;
  s6 = kb_generate_instances(6, 3, 5, 9, 50, 0.5, cs);
  assert(all(arrayfun(@(i) strcmp(i.family, 'strongly_correlated') && isequal(i.values, i.weights + 10), s6)), ...
         'strongly correlated only, offset 0.2');
  cw = ic.correlation;
  cw.families = 'weakly_correlated';               % one family as a string (jsondecode)
  cw.weak_noise_ratio = 0;
  w6 = kb_generate_instances(6, 3, 5, 9, 50, 0.5, cw);
  assert(all(arrayfun(@(i) isequal(i.values, i.weights), w6)), 'weak noise 0 -> v = w');
  co = ic.correlation;
  co.families = {'strongly_correlated'; 'uncorrelated'};
  o4 = kb_generate_instances(4, 3, 5, 9, 50, 0.5, co);
  assert(isequal({o4.family}, {'strongly_correlated', 'uncorrelated', 'strongly_correlated', 'uncorrelated'}), ...
         'families rotate in the given order');
  bad = {struct('families', {{}}), struct('families', {{'uncorrelated', 'uncorrelated'}}), ...
         struct('families', {{'anti_correlated'}}), struct('weak_noise_ratio', -0.1), ...
         struct('strong_offset_ratio', 1.5)};
  for k = 1:numel(bad)
    cb = kb_merge_settings(ic.correlation, bad{k}, 'correlation');
    try
      kb_generate_instances(3, 1, 5, 9, 50, 0.5, cb);
      error('test_p01:accepted', 'invalid correlation %d accepted', k);
    catch err
      assert(strcmp(err.identifier, 'kb_generate_instances:correlation'), err.message);
    end
  end
  assert(all(arrayfun(@(R) floor(0.1 * R) == floor(R / 10), 1:100000)), 'floor(0.1 R) = floor(R / 10)');

  % QUBO variant B and QC run the code of 'qubo': same items, energies and moves
  insts = kb_generate_instances(12, 2026, 10, 48, 100, 0.5);
  cases = [{struct('values', v, 'weights', w, 'capacity', C)}, num2cell(insts)];
  for k = 1:numel(cases)
    inst = cases{k};
    [ia, xa] = kp_algo_qubo_main(inst.values, inst.weights, inst.capacity, cfg.qubo, 2026 + k);
    [ib, xb] = kp_algo_qubo_b_main(inst.values, inst.weights, inst.capacity, cfg.qubo_b, 2026 + k);
    [iq, xq] = kp_algo_qc_main(inst.values, inst.weights, inst.capacity, cfg.qc, 2026 + k);
    assert(isequal(ia, ib, iq) && xa.energy == xb.energy && xa.energy == xq.energy ...
           && xa.move_evaluations == xq.move_evaluations, sprintf('qubo_b / qc differ from qubo (case %d)', k));
  end
  assert(isequal(cfg.qubo_b, cfg.qubo) && isequal(rmfield(cfg.qc, 'qaoa'), cfg.qubo), 'same settings');

  % QC greedy module = greedy algorithm
  for i = kb_generate_instances(12, 7, 5, 40, 100, 0.5)
    [g1, f1] = kb_qc_greedy(i.values, i.weights, i.capacity);
    [g2, f2] = kp_algo_greedy_main(i.values, i.weights, i.capacity);
    assert(isequal(g1, g2) && isequal(f1, f2), 'kb_qc_greedy differs from greedy');
  end

  % QAOA on the MathWorks example (same values as the Python port, tests/test_qc.py)
  vq = [5 2 8 4 3];
  wq = [9 8 4 5 2];
  [Q, c, d] = kb_qc_knapsack2qubo(vq, wq, 17, max(vq) + 1);
  o = cfg.qc.qaoa;
  o.seed = 1;
  [x, e, st] = kb_qc_qaoa(Q, c, d, o);
  assert(isequal(x', [0 0 1 1 1 0 1 1 0 0]) && e == -15 && x' * Q * x + c' * x + d == e, 'QAOA state');
  assert(max(abs(st.gamma - [3.46884188833873 7.00313362362725])) < 1e-12 ...
         && max(abs(st.beta - [2.81434341884086 3.01069295969022])) < 1e-12 ...
         && abs(st.expected_energy - 0.0232939696574762) < 1e-13 && st.iterations == 320, 'QAOA angles');
  sol = kb_qc_decode(x, vq, wq, 17);
  assert(sol.feasible && isequal(sol.final_items, [3 4 5]) && sol.final_value == 15, 'QAOA decode');
  [Q, c, d] = kb_qc_knapsack2qubo(v, w, C, max(v) + 1);       % P01: 10 items + 8 slack bits
  o.max_qubits = 17;
  try
    kb_qc_qaoa(Q, c, d, o);
    error('test_p01:accepted', 'QAOA above max_qubits accepted');
  catch err
    assert(strcmp(err.identifier, 'kb_qc_qaoa:tooLarge'), err.message);
  end

  disp('test_p01: all checks passed');
end

function conforms(x, schema, where)
%CONFORMS  X has the required fields of SCHEMA and, with additionalProperties false, no others (recursively).
  if ~isstruct(x) || ~isfield(schema, 'properties')
    return;
  end
  props = fieldnames(schema.properties);
  if isfield(schema, 'required')
    missing = setdiff(schema.required, fieldnames(x));
    assert(isempty(missing), sprintf('%s: missing %s', where, sprintf('%s ', missing{:})));
  end
  if isfield(schema, 'additionalProperties') && isequal(schema.additionalProperties, false)
    extra = setdiff(fieldnames(x), props);
    assert(isempty(extra), sprintf('%s: unexpected %s', where, sprintf('%s ', extra{:})));
  end
  for f = intersect(fieldnames(x), props)'
    conforms(x.(f{1}), schema.properties.(f{1}), [where '.' f{1}]);
  end
end

function write_text(file, txt)
  fid = fopen(file, 'w');
  fprintf(fid, '%s', txt);
  fclose(fid);
end
