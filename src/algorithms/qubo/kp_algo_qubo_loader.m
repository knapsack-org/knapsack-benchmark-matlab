function L = kp_algo_qubo_loader()
%KP_ALGO_QUBO_LOADER  Identity of 'qubo' for KB_DISCOVER_ALGORITHMS.
  L = struct();
  L.id = 'qubo';                    % must equal the folder name
  L.label = 'QUBO A + Tabu Search';
  L.description = ['Variant A. Heuristic: the knapsack written as a QUBO (capacity as a squared penalty ' ...
                   'with a binary-encoded slack), minimised by a multi-start tabu search, ' ...
                   'then decoded and repaired if infeasible.'];
  L.short_label = 'QUBO A';             % algorithm chip in Knapview
  L.exact = false;
  L.reference = false;
  L.available = @() true;
  L.environment = @() struct();         % nothing to add to environment.algorithms
end
