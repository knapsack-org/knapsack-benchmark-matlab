function L = kp_algo_bnb_loader()
%KP_ALGO_BNB_LOADER  Identity of 'bnb' for KB_DISCOVER_ALGORITHMS.
  L = struct();
  L.id = 'bnb';                         % must equal the folder name
  L.label = 'branch and bound (Dantzig bound, depth-first)';
  L.short_label = 'BnB';                % algorithm chip in Knapview
  L.exact = true;
  L.reference = false;
  L.available = @() true;
  L.environment = @() struct();         % nothing to add to environment.algorithms
end
