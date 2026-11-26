function L = kp_algo_qc_loader()
%KP_ALGO_QC_LOADER  Identity of 'qc' for KB_DISCOVER_ALGORITHMS.
  L = struct();
  L.id = 'qc';                    % must equal the folder name
  L.label = 'QC (QUBO + Tabu Search)';
  L.description = ['Heuristic (quantum computing experiments): today the QUBO variant B code, the ' ...
                   'knapsack written as a QUBO minimised by a multi-start tabu search, then decoded ' ...
                   'and repaired. Its modules also hold a simulated QAOA and a ratio greedy.'];
  L.short_label = 'QC';             % algorithm chip in Knapview
  L.exact = false;
  L.reference = false;
  L.available = @() true;
  L.environment = @() struct();         % nothing to add to environment.algorithms
end
