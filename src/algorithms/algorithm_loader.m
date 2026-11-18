function L = algorithm_loader()
%ALGORITHM_LOADER  Registry and loading functions of the benchmarked algorithms.
%   L = ALGORITHM_LOADER() returns a struct used by BENCHMARK_CONFIG, RUN_BENCHMARK
%   and KB_RUN_ALGORITHM:
%     L.ids               registry: algorithm ids in default run order (cell)
%     L.configs()         struct of the default settings blocks, one field per id
%                         (from src/algorithms/<id>/kb_config_<id>.m)
%     L.check(requested)  validated ids; error run_benchmark:unknownAlgorithm on an
%                         unknown id; drops 'ilp' (warning run_benchmark:noIlp)
%                         when no ILP solver exists
%     L.adapter(id)       handle to the benchmark adapter kb_algo_<id>
%   Each id has a folder src/algorithms/<id>/ with kb_config_<id>.m and
%   kb_algo_<id>.m. Add a new algorithm to L.ids below.
  L = struct();
  L.ids = {'dp', 'bnb', 'ilp', 'qubo', 'qubo_chz'};
  L.configs = @() default_configs(L.ids);
  L.check = @(requested) check_algorithms(L.ids, requested);
  L.adapter = @(id) str2func(['kb_algo_' id]);
end

function c = default_configs(ids)
  c = struct();
  for i = 1:numel(ids)
    c.(ids{i}) = feval(['kb_config_' ids{i}]);
  end
end

function algos = check_algorithms(known, requested)
  algos = {};
  for i = 1:numel(requested)
    name = requested{i};
    if ~any(strcmp(known, name))
      error('run_benchmark:unknownAlgorithm', 'Unknown algorithm "%s".', name);
    end
    if strcmp(name, 'ilp') && isempty(kb_ilp_solver_name({'ilp'}))
      warning('run_benchmark:noIlp', ['No ILP solver (intlinprog or glpk) found: ' ...
              'algorithm "ilp" skipped.']);
      continue;
    end
    algos{end + 1} = name; %#ok<AGROW>
  end
end
