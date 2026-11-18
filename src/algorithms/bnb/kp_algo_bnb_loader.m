function L = kp_algo_bnb_loader()
%KP_ALGO_BNB_LOADER  Identity of 'bnb' for KB_DISCOVER_ALGORITHMS.
  L = struct();
  L.id = 'bnb';                         % must equal the folder name
  L.label = 'Branch and Bound (Dantzig Bound, Depth-First)';
  L.description = ['Exact depth-first search over take/skip decisions, items sorted by ' ...
                   'value/weight; a node is pruned when its Dantzig bound (LP relaxation) ' ...
                   'cannot beat the best packing found, starting from the greedy packing.'];
  L.short_label = 'BnB';                % algorithm chip in Knapview
  L.exact = true;
  L.reference = false;
  L.available = @() true;
  L.environment = @() struct();         % nothing to add to environment.algorithms
end
