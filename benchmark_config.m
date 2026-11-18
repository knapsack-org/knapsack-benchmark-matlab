function cfg = benchmark_config()
%BENCHMARK_CONFIG  Parameters of the knapsack algorithm benchmark.
%   CFG = BENCHMARK_CONFIG() returns the settings used by RUN_BENCHMARK:
%     cfg.seed        master seed (below)
%     cfg.instances   instance generator, from src/instances/kb_config_instances.m
%     cfg.algorithms  ids of every folder of src/algorithms/ (alphabetical)
%     cfg.<id>        settings of algorithm <id>, from
%                     src/algorithms/<id>/kp_algo_<id>_config.m (always has 'repeats')
%   There are no run-time overrides: to change a setting, edit the file that
%   defines it.
  addpath(genpath(fullfile(fileparts(mfilename('fullpath')), 'src')));
  cfg = struct();
  cfg.seed = 2026;              % master seed: same seed -> same instances and results
  cfg.instances = kb_config_instances();
  [algos, skipped] = kb_discover_algorithms();
  ids = sort([{algos.id}, cellfun(@(s) s.id, skipped, 'UniformOutput', false)]);
  cfg.algorithms = ids;
  for i = 1:numel(ids)
    cfg.(ids{i}) = feval(['kp_algo_' ids{i} '_config']);
  end
end
