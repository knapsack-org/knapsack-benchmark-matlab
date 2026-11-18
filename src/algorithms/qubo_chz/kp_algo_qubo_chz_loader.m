function L = kp_algo_qubo_chz_loader()
%KP_ALGO_QUBO_CHZ_LOADER  Identity of 'qubo_chz' for KB_DISCOVER_ALGORITHMS.
  L = struct();
  L.id = 'qubo_chz';                % must equal the folder name
  L.label = 'QUBO CHZ + tabu search';
  L.short_label = 'QUBO CHZ';         % algorithm chip in Knapview
  L.exact = false;
  L.reference = false;
  L.available = @() true;
  L.environment = @() struct();         % nothing to add to environment.algorithms
end
