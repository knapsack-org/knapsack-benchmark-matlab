function L = kp_algo_sa_loader()
%KP_ALGO_SA_LOADER  Identity of 'sa' for KB_DISCOVER_ALGORITHMS.
  L = struct();
  L.id = 'sa';                      % must equal the folder name
  L.label = 'Simulated Annealing';
  L.description = 'Random single-item flips accepted with probability exp(-dE/T) on the penalised energy -V + P*max(0, W-C)^2, with a geometric cooling and several restarts; returns the best feasible packing seen.';
  L.short_label = 'SA';               % algorithm chip in Knapview
  L.exact = false;
  L.reference = false;
  L.available = @() true;
  L.environment = @() struct();         % nothing to add to environment.algorithms
end
