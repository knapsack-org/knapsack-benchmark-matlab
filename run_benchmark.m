function result = run_benchmark(opts)
%RUN_BENCHMARK  Benchmark knapsack algorithms: DP, branch and bound, ILP, QUBO, QUBO CHZ.
%   RESULT = RUN_BENCHMARK() generates 100 reproducible 0-1 knapsack instances
%   and runs, on each one, the algorithms listed in cfg.algorithms:
%     dp    dynamic programming 0-1          exact, reference optimum
%     bnb   branch and bound (Dantzig bound)  exact
%     ilp   integer linear programming        exact (intlinprog in MATLAB, glpk in Octave)
%     qubo  knapsack -> QUBO -> tabu search   heuristic
%     qubo_chz  independent copy of qubo (src/algorithms/qubo_chz/kb_chz_*.m, settings cfg.qubo_chz)
%   For each algorithm it records the solution, its quality (gap to the DP
%   optimum) and its execution cost, then writes everything to
%       ./output/run-dd-mm-yy-hh-mm.json
%
%   RESULT = RUN_BENCHMARK(OPTS) overrides the defaults of BENCHMARK_CONFIG, e.g.
%       run_benchmark(struct('instances', struct('count', 10)))
%       run_benchmark(struct('algorithms', {{'dp', 'bnb'}}))   % note the double braces
%
%   Runs in GNU Octave (>= 7, needs jsonencode) and in MATLAB (>= R2021a).
%   From a terminal:  octave-cli --eval "run_benchmark"
%
%   Cost measures (field "cost" of every algorithm result):
%     wall_time_s          median wall-clock time over the timing repeats (tic/toc)
%     wall_time_min_s      fastest repeat
%     cpu_time_s           CPU time per run (cputime)
%     working_memory_bytes bytes of the algorithm's own arrays (whos): comparable.
%                          For ILP only the problem data is visible, not the
%                          solver's internal memory.
%     process_memory_*     process RAM before/after (memory(): Octave on Linux and
%                          Windows, MATLAB on Windows); null when unavailable.
%                          Process-wide snapshot: indicative only.
%     operations           dp: table cells | bnb: nodes | ilp: B&B nodes
%                          (intlinprog only, else null) | qubo, qubo_chz: move evaluations
%
%   See also BENCHMARK_CONFIG, KB_KNAPSACK_DP, KB_KNAPSACK_BNB, KB_KNAPSACK_ILP,
%   KB_KNAPSACK2QUBO, KB_QUBO_TABU_SLACK, KB_CHZ_KNAPSACK2QUBO, KB_CHZ_QUBO_TABU_SLACK.

  root = fileparts(mfilename('fullpath'));
  addpath(genpath(fullfile(root, 'src')));

  if nargin < 1
    opts = struct();
  end
  cfg = benchmark_config(opts);
  loader = algorithm_loader();
  algos = loader.check(cfg.algorithms);

  ic = cfg.instances;
  instances = kb_generate_instances(ic.count, cfg.seed, ic.min_items, ic.max_items, ...
                                    ic.max_coefficient, ic.capacity_ratio);

  fprintf('knapsack-benchmark-matlab | %s | %d instances | %s %s\n', ...
          strjoin(algos, ', '), numel(instances), kb_interpreter(), version());

  runs = [];
  t_total = tic;
  for k = 1:numel(instances)
    inst = instances(k);
    v = inst.values;
    w = inst.weights;
    C = inst.capacity;

    % reference optimum (not timed here; DP is also benchmarked as 'dp')
    [optimum, opt_items] = kb_knapsack_dp(v, w, C);

    results = struct();
    for a = 1:numel(algos)
      results.(algos{a}) = kb_run_algorithm(algos{a}, v, w, C, cfg, k, optimum);
    end
    results = kb_add_ratios_vs_dp(results, algos);

    r = struct();
    r.id = k;
    r.family = inst.family;
    r.n = numel(v);
    r.capacity = C;
    r.weights = num2cell(w);                 % cell -> always a JSON array
    r.values = num2cell(v);
    r.optimum = optimum;
    r.optimal_items = num2cell(opt_items);
    r.results = results;

    if isempty(runs)
      runs = r;
    else
      runs(end + 1) = r; %#ok<AGROW>
    end
    kb_print_instance(r, algos);
  end
  total_time = toc(t_total);

  result = struct();
  result.project = 'knapsack-benchmark-matlab';
  result.schema_version = 2;   % version of this JSON structure; increase on any breaking change
  result.algorithms = algos;   % replaced below by {id, label, exact, config} objects
  result.instance_config = cell2struct([{cfg.seed}; struct2cell(ic)], [{'seed'}; fieldnames(ic)]);
  result.reference_algorithm = 'dp';
  result.description = ['0-1 knapsack: dynamic programming, branch and bound, integer linear ' ...
                        'programming, QUBO + tabu search and its independent copy QUBO CHZ, ' ...
                        'compared on quality (gap to the DP optimum) and execution cost ' ...
                        '(time, CPU, memory, operations)'];
  result.created = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
  result.environment = struct('interpreter', kb_interpreter(), 'version', version(), ...
                              'computer', computer(), ...
                              'process_memory_available', ~isnan(kb_process_memory()), ...
                              'ilp_solver', kb_ilp_solver_name(algos));
  result.parameters = cfg;
  result.summary = kb_summary(runs, algos, total_time);
  result.instances = runs;

  info = cell(1, numel(algos));  % cell -> always a JSON array
  for a = 1:numel(algos)
    p = result.summary.algorithms.(algos{a});
    info{a} = struct('id', algos{a}, 'label', p.algorithm, 'exact', p.exact, ...
                     'config', cfg.(algos{a}));
  end
  result.algorithms = info;

  out_dir = fullfile(root, 'output');
  if ~exist(out_dir, 'dir')
    mkdir(out_dir);
  end
  out_file = fullfile(out_dir, sprintf('run-%s.json', datestr(now, 'dd-mm-yy-HH-MM')));
  kb_write_json(out_file, result);

  kb_print_summary(result.summary, algos, total_time, out_file);
  result.output_file = out_file;
end
