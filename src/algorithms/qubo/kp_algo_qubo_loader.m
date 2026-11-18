function L = kp_algo_qubo_loader()
%KP_ALGO_QUBO_LOADER  Identity of 'qubo' for KB_DISCOVER_ALGORITHMS.
  L = struct();
  L.id = 'qubo';                    % must equal the folder name
  L.label = 'QUBO + tabu search';
  L.short_label = 'QUBO';             % algorithm chip in Knapview
  L.exact = false;
  L.reference = false;
  L.available = @() true;
  L.environment = @() struct();         % nothing to add to environment.algorithms
end
