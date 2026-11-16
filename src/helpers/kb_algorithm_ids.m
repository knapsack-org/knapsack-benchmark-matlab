function ids = kb_algorithm_ids()
%KB_ALGORITHM_IDS  Registry of the benchmarked algorithms, in default run order.
%   Each id has a folder src/algorithms/<id>/ with kb_config_<id>.m (settings)
%   and kb_algo_<id>.m (benchmark adapter). Add a new algorithm here.
  ids = {'dp', 'bnb', 'ilp', 'qubo', 'qubo_chz'};
end
