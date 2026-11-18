function L = kp_algo_fptas_loader()
%KP_ALGO_FPTAS_LOADER  Identity of 'fptas' for KB_DISCOVER_ALGORITHMS.
  L = struct();
  L.id = 'fptas';                   % must equal the folder name
  L.label = 'FPTAS (Profit Scaling)';
  L.description = 'Values are scaled down by epsilon*vmax/n and a minimum-weight table over the scaled profits is filled; the packing found is at least (1 - epsilon) times the optimum.';
  L.short_label = 'FPTAS';            % algorithm chip in Knapview
  L.exact = false;
  L.reference = false;
  L.available = @() true;
  L.environment = @() struct();         % nothing to add to environment.algorithms
end
