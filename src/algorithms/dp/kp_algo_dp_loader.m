function L = kp_algo_dp_loader()
%KP_ALGO_DP_LOADER  Identity of 'dp' for KB_DISCOVER_ALGORITHMS.
  L = struct();
  L.id = 'dp';                          % must equal the folder name
  L.label = 'dynamic programming 0-1';
  L.short_label = 'DP';                 % algorithm chip in Knapview
  L.exact = true;
  L.reference = true;                   % its result is the optimum the others are compared with
  L.available = @() true;
  L.environment = @() struct();         % nothing to add to environment.algorithms
end
