function result = run_benchmark()
%RUN_BENCHMARK  Benchmark every knapsack algorithm of src/algorithms/ on every instance.
%   RESULT = RUN_BENCHMARK() generates the 0-1 knapsack instances of
%   src/instances/kb_config_instances.m and runs, on each one, every algorithm
%   found in src/algorithms/<id>/ (see KB_DISCOVER_ALGORITHMS; an algorithm
%   whose loader says it is not available here, e.g. 'ilp' without a solver,
%   is skipped with a warning). For each algorithm it records the solution, its
%   quality (gap to the optimum of the reference algorithm) and its execution
%   cost, then writes everything to
%       ./output/run-dd-mm-yy-hh-mm.json
%   It takes no argument: settings are changed in the files of BENCHMARK_CONFIG.
%
%   Runs in GNU Octave (>= 7, needs jsonencode) and in MATLAB (>= R2021a).
%   From a terminal:  octave-cli --eval "run_benchmark"
%
%   Cost measures (field "cost" of every algorithm result):
%     wall_time_s          median wall-clock time over the timing repeats (tic/toc)
%     wall_time_min_s      fastest repeat
%     cpu_time_s           CPU time per run (cputime)
%     working_memory_bytes bytes of the algorithm's own arrays (whos), as reported
%                          by its kp_algo_<id>_output
%     process_memory_*     process RAM before/after (memory(): Octave on Linux and
%                          Windows, MATLAB on Windows); null when unavailable.
%                          Process-wide snapshot: indicative only.
%     operations           counted by each algorithm, unit in operations_unit
%
%   See also BENCHMARK_CONFIG, KB_DISCOVER_ALGORITHMS, KB_RUN_ALGORITHM.

  root = fileparts(mfilename('fullpath'));
  addpath(genpath(fullfile(root, 'src')));

  cfg = benchmark_config();
  [algos, skipped] = kb_discover_algorithms();
  for s = 1:numel(skipped)
    warning('run_benchmark:unavailable', 'Algorithm "%s" skipped: %s.', ...
            skipped{s}.id, skipped{s}.reason);
  end
  ids = {algos.id};
  ref = algos([algos.reference]).id;

  ic = cfg.instances;
  instances = kb_generate_instances(ic.count, cfg.seed, ic.min_items, ic.max_items, ...
                                    ic.max_coefficient, ic.capacity_ratio);

  fprintf('knapsack-benchmark-matlab | %s | reference %s | %d instances | %s %s\n', ...
          strjoin(ids, ', '), ref, numel(instances), kb_interpreter(), version());

  runs = [];
  t_total = tic;
  for k = 1:numel(instances)
    inst = instances(k);
    v = inst.values;
    w = inst.weights;
    C = inst.capacity;

    % reference first: its value is the optimum the others are compared with
    ref_result = kb_run_algorithm(algos([algos.reference]), v, w, C, cfg, k);
    optimum = ref_result.value;
    results = struct();
    for a = 1:numel(algos)
      if algos(a).reference
        res = ref_result;
      else
        res = kb_run_algorithm(algos(a), v, w, C, cfg, k);
      end
      res.is_optimal = (res.value == optimum);
      if optimum > 0
        res.gap_percent = 100 * (optimum - res.value) / optimum;
      else
        res.gap_percent = 0;
      end
      results.(ids{a}) = res;
    end
    results = kb_add_ratios(results, ids, ref);

    r = struct();
    r.id = k;
    r.family = inst.family;
    r.n = numel(v);
    r.capacity = C;
    r.weights = num2cell(w);                 % cell -> always a JSON array
    r.values = num2cell(v);
    r.optimum = optimum;
    r.optimal_items = ref_result.items;
    r.results = results;

    if isempty(runs)
      runs = r;
    else
      runs(end + 1) = r; %#ok<AGROW>
    end
    kb_print_instance(r, ids);
  end
  total_time = toc(t_total);

  entries = cell(1, numel(algos));         % cell -> always a JSON array
  env_algos = struct();
  for a = 1:numel(algos)
    e = algos(a).output.entry(cfg.(ids{a}), algos(a).environment);
    kb_validate_schema(e, algos(a).output.schema.entry, ['algorithms.' ids{a}]);
    entries{a} = e;
    if ~isempty(fieldnames(algos(a).environment))
      env_algos.(ids{a}) = algos(a).environment;
    end
  end
  labels = cellfun(@(e) e.label, entries, 'UniformOutput', false);

  env = struct('interpreter', kb_interpreter(), 'version', version(), ...
               'computer', computer(), ...
               'process_memory_available', ~isnan(kb_process_memory()));
  if ~isempty(fieldnames(env_algos))
    env.algorithms = env_algos;
  end

  result = struct();
  result.project = 'knapsack-benchmark-matlab';
  result.schema_version = 3;   % version of this JSON structure; increase on any breaking change
  result.algorithms = entries;
  result.skipped_algorithms = skipped;
  result.instance_config = cell2struct([{cfg.seed}; struct2cell(ic)], [{'seed'}; fieldnames(ic)]);
  result.reference_algorithm = ref;
  result.description = sprintf(['0-1 knapsack: %s, compared on quality (gap to the %s ' ...
                                'optimum) and execution cost (time, CPU, memory, operations)'], ...
                               strjoin(labels, ', '), ref);
  result.created = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
  result.environment = env;
  result.parameters = cfg;
  result.summary = kb_summary(runs, ids, total_time);
  result.instances = runs;

  out_dir = fullfile(root, 'output');
  if ~exist(out_dir, 'dir')
    mkdir(out_dir);
  end
  out_file = fullfile(out_dir, sprintf('run-%s.json', datestr(now, 'dd-mm-yy-HH-MM')));
  kb_write_json(out_file, result);

  kb_print_summary(result.summary, ids, total_time, out_file);
  result.output_file = out_file;
end
