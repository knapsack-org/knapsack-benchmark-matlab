function L = kp_algo_dp_loader()
%KP_ALGO_DP_LOADER  Identity of 'dp' for KB_DISCOVER_ALGORITHMS.
  L = struct();
  L.id = 'dp';                          % must equal the folder name
  L.label = 'Dynamic Programming 0-1';
  L.description = ['Exact table of the best value for the first i items and every capacity ' ...
                   'up to C, built row by row in O(n*C) time and memory; its optimum is the ' ...
                   'reference of the benchmark.'];
  L.short_label = 'DP';                 % algorithm chip in Knapview
  L.exact = true;
  L.reference = true;                   % its result is the optimum the others are compared with
  L.available = @() true;
  L.environment = @() struct();         % nothing to add to environment.algorithms
end
