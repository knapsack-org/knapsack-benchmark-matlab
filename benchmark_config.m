function cfg = benchmark_config(request)
%BENCHMARK_CONFIG  Parameters of the knapsack algorithm benchmark.
%   CFG = BENCHMARK_CONFIG() returns the settings used by RUN_BENCHMARK:
%     cfg.seed        master seed (below)
%     cfg.instances   instance generator, from src/instances/kb_config_instances.m
%     cfg.algorithms  ids of the algorithm folders that run (alphabetical): all, or the
%                     request's algorithms plus the reference
%     cfg.<id>        settings of algorithm <id>, from
%                     src/algorithms/<id>/kp_algo_<id>_config.m (always has 'repeats')
%   CFG = BENCHMARK_CONFIG(REQUEST) applies a run request (struct, ADR 0014): it overrides
%   seed, fields of cfg.instances and, per algorithm, fields of cfg.<id>
%   (request.algorithm_config.<id>); an unknown field is an error. Everything else comes
%   from the settings files.
  addpath(genpath(fullfile(fileparts(mfilename('fullpath')), 'src')));
  if nargin < 1
    request = struct();
  end
  cfg = struct();
  cfg.seed = 2026;              % master seed: same seed -> same instances and results
  if isfield(request, 'seed')
    cfg.seed = request.seed;
  end
  cfg.instances = kb_config_instances();
  if isfield(request, 'instances')
    cfg.instances = kb_merge_settings(cfg.instances, request.instances, 'instances');
  end
  only = {};
  if isfield(request, 'algorithms')
    only = request.algorithms(:)';
  end
  overrides = struct();
  if isfield(request, 'algorithm_config')
    overrides = request.algorithm_config;
  end
  [algos, skipped] = kb_discover_algorithms(only);
  ids = sort([{algos.id}, cellfun(@(s) s.id, skipped, 'UniformOutput', false)]);
  cfg.algorithms = ids;
  for i = 1:numel(ids)
    cfg.(ids{i}) = feval(['kp_algo_' ids{i} '_config']);
    if isfield(overrides, ids{i})
      cfg.(ids{i}) = kb_merge_settings(cfg.(ids{i}), overrides.(ids{i}), ids{i});
    end
  end
end
