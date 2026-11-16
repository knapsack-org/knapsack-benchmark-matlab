function cfg = benchmark_config(overrides)
%BENCHMARK_CONFIG  Default parameters of the knapsack algorithm benchmark.
%   CFG = BENCHMARK_CONFIG() returns the defaults.
%   CFG = BENCHMARK_CONFIG(OVERRIDES) replaces any field given in the struct
%   OVERRIDES; nested structs are merged field by field, e.g.
%       struct('qubo_chz', struct('tabu', struct('restarts', 50)))
%   only changes qubo_chz.tabu.restarts.
%
%   Each algorithm has its own settings block cfg.<id>, whose defaults come from
%   src/algorithms/<id>/kb_config_<id>.m (ids listed in KB_ALGORITHM_IDS); the
%   instance generator's block cfg.instances comes from src/instances/kb_config_instances.m.

  addpath(genpath(fullfile(fileparts(mfilename('fullpath')), 'src')));
  cfg = struct();
  cfg.seed = 2026;              % master seed: same seed -> same instances and results
  cfg.instances = kb_config_instances();   % instance generator: src/instances/kb_config_instances.m
  ids = kb_algorithm_ids();
  cfg.algorithms = ids;         % benchmarked, in this order (dp = reference)
                                % dp        dynamic programming 0-1 (exact)
                                % bnb       branch and bound (exact)
                                % ilp       integer linear programming: intlinprog or glpk (exact)
                                % qubo      QUBO + tabu search (heuristic)
                                % qubo_chz  independent copy of qubo (own code and settings)
  for i = 1:numel(ids)          % settings blocks cfg.dp, cfg.bnb, ... (each has 'repeats')
    cfg.(ids{i}) = feval(['kb_config_' ids{i}]);
  end

  if nargin < 1 || isempty(overrides)
    return;
  end
  cfg = merge(cfg, overrides, '');
end

function base = merge(base, over, prefix)
%MERGE  Copy the fields of OVER into BASE, recursing into nested structs.
  names = fieldnames(over);
  for i = 1:numel(names)
    key = names{i};
    if ~isfield(base, key)
      error('benchmark_config:unknownOption', 'Unknown option "%s%s".', prefix, key);
    end
    if isstruct(base.(key)) && isstruct(over.(key))
      base.(key) = merge(base.(key), over.(key), [prefix key '.']);
    else
      base.(key) = over.(key);
    end
  end
end
