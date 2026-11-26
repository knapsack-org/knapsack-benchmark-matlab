function result = run_benchmark(varargin)
%RUN_BENCHMARK  Benchmark the knapsack algorithms of src/algorithms/ and write their raw results.
%   RAW = RUN_BENCHMARK() runs every algorithm found in src/algorithms/<id>/ (see
%   KB_DISCOVER_ALGORITHMS; an algorithm whose loader says it is not available here,
%   e.g. 'ilp' without a solver, is skipped with a warning) on every instance of
%   src/instances/kb_config_instances.m and writes (ADR 0014)
%       ./output/run-dd-mm-yy-hh-mm/raw.json        raw results (format knapsack-raw, version 1)
%       ./output/run-dd-mm-yy-hh-mm/instances.json  the instances (format knapsack-instances, version 1)
%   knapsack-output (knapsack-server) computes optimum, gaps, ratios and summary from them
%   and writes the run file (schema_version 4).
%
%   RAW = RUN_BENCHMARK(REQUEST_FILE, INSTANCES_FILE, OUT_DIR), each optional ('' = absent):
%     REQUEST_FILE    run request JSON: seed, instances, algorithms (the reference is always
%                     added), algorithm_config (partial settings per algorithm). Absent fields
%                     come from the settings files of BENCHMARK_CONFIG.
%     INSTANCES_FILE  instance set JSON used instead of the generator (no instances.json then);
%                     its seed applies when the request has none
%     OUT_DIR         output folder
%   D = RUN_BENCHMARK('--describe') prints the algorithms, their default settings and their
%   JSON Schemas (kp_algo_<id>_output.schema.json) as JSON.
%
%   stdout: one line per instance, and before and after each algorithm on each instance
%     @@progress {"instance":<id>,"algorithm":"<id>","event":"start"|"done"}
%
%   Runs in GNU Octave (>= 7, needs jsonencode) and in MATLAB (>= R2021a).
%   From a terminal:  octave-cli --eval "run_benchmark"
%                     octave-cli --eval "run_benchmark('req.json', 'shard.json', 'out')"
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
  args = [varargin, repmat({''}, 1, 3 - numel(varargin))];
  [request_file, instances_file, out_dir] = args{1:3};

  if strcmp(request_file, '--describe')
    cfg = benchmark_config();
    algos = kb_discover_algorithms();
    result = struct('project', 'knapsack-benchmark-matlab', 'environment', environment(algos), ...
                    'algorithms', {entries(algos, cfg)});
    disp(kb_write_json('', result, algos));
    return;
  end

  request = struct();
  if ~isempty(request_file)
    request = jsondecode(fileread(request_file));
  end
  if ~isempty(instances_file)
    iset = jsondecode(fileread(instances_file));
    if ~strcmp(iset.format, 'knapsack-instances') || iset.format_version ~= 1
      error('run_benchmark:instances', '%s: not a knapsack-instances v1 file.', instances_file);
    end
    instance_config = iset.instance_config;
    if ~isfield(request, 'seed')
      request.seed = instance_config.seed;
    end
  end
  cfg = benchmark_config(request);
  only = {};
  if isfield(request, 'algorithms')
    only = request.algorithms(:)';
  end
  [algos, skipped] = kb_discover_algorithms(only);
  for s = 1:numel(skipped)
    warning('run_benchmark:unavailable', 'Algorithm "%s" skipped: %s.', ...
            skipped{s}.id, skipped{s}.reason);
  end
  ids = {algos.id};
  ref = algos([algos.reference]).id;

  if ~isempty(instances_file)
    instances = iset.instances;
    cfg.instances = rmfield(instance_config, 'seed');
  else
    ic = cfg.instances;
    instances = kb_generate_instances(ic.count, cfg.seed, ic.min_items, ic.max_items, ...
                                      ic.max_coefficient, ic.capacity_ratio, ic.correlation);
    instance_config = cell2struct([{cfg.seed}; struct2cell(ic)], [{'seed'}; fieldnames(ic)]);
  end

  fprintf('knapsack-benchmark-matlab | %s | reference %s | %d instances | %s %s\n', ...
          strjoin(ids, ', '), ref, numel(instances), kb_interpreter(), version());

  order = [find([algos.reference]), find(~[algos.reference])];   % reference first, as before
  runs = cell(1, numel(instances));        % cell -> always a JSON array
  t_total = tic;
  for k = 1:numel(instances)
    inst = instances(k);
    v = inst.values(:)';                   % jsondecode gives columns
    w = inst.weights(:)';
    results = struct();
    for a = order
      kb_print_progress(inst.id, ids{a}, 'start');
      % per-instance seed from the global instance id, so a shard gives the same results (P7)
      results.(ids{a}) = kb_run_algorithm(algos(a), v, w, inst.capacity, cfg, inst.id);
      kb_print_progress(inst.id, ids{a}, 'done');
    end
    results = orderfields(results, ids);
    runs{k} = struct('id', inst.id, 'results', results);
    kb_print_instance(inst, results, ids, ref);
  end
  total_time = toc(t_total);

  result = struct();
  result.format = 'knapsack-raw';
  result.format_version = 1;
  result.project = 'knapsack-benchmark-matlab';
  result.created = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
  result.environment = environment(algos);
  result.algorithms = entries(algos, cfg);
  result.algorithm_schemas = struct();   % filled by kb_write_json from the schema files
  result.skipped_algorithms = skipped;
  result.reference_algorithm = ref;
  result.parameters = cfg;
  result.instance_config = instance_config;
  result.instances = runs;
  result.timing = struct('total_time_seconds', total_time);

  if isempty(out_dir)
    out_dir = fullfile(root, 'output', sprintf('run-%s', datestr(now, 'dd-mm-yy-HH-MM')));
  end
  if ~exist(out_dir, 'dir')
    mkdir(out_dir);
  end
  kb_write_json(fullfile(out_dir, 'raw.json'), result, algos);
  if isempty(instances_file)
    kb_write_json(fullfile(out_dir, 'instances.json'), instance_set(instances, instance_config));
  end
  fprintf('Total %.1f s\nOutput: %s\n', total_time, out_dir);
  result.output_dir = out_dir;
end

function env = environment(algos)
  env = struct('interpreter', kb_interpreter(), 'version', version(), ...
               'computer', computer(), ...
               'process_memory_available', ~isnan(kb_process_memory()));
  env_algos = struct();
  for a = 1:numel(algos)
    if ~isempty(fieldnames(algos(a).environment))
      env_algos.(algos(a).id) = algos(a).environment;
    end
  end
  if ~isempty(fieldnames(env_algos))
    env.algorithms = env_algos;
  end
end

function e = entries(algos, cfg)
  e = cell(1, numel(algos));               % cell -> always a JSON array
  for a = 1:numel(algos)
    e{a} = algos(a).output.entry(cfg.(algos(a).id), algos(a).environment);
  end
end

function s = instance_set(instances, instance_config)
  items = cell(1, numel(instances));       % cells -> always JSON arrays
  for k = 1:numel(instances)
    i = instances(k);
    items{k} = struct('id', i.id, 'family', i.family, 'n', numel(i.weights), 'capacity', i.capacity, ...
                      'weights', {num2cell(i.weights)}, 'values', {num2cell(i.values)});
  end
  s = struct('format', 'knapsack-instances', 'format_version', 1, ...
             'instance_config', instance_config, 'instances', {items});
end
