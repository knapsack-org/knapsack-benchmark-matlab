function L = kp_algo_greedy_loader()
%KP_ALGO_GREEDY_LOADER  Identity of 'greedy' for KB_DISCOVER_ALGORITHMS.
  L = struct();
  L.id = 'greedy';                  % must equal the folder name
  L.label = 'Greedy by Value/Weight Ratio + Best Single Item';
  L.description = 'Takes the items in decreasing value/weight order while they fit, then returns the better of that packing and the most valuable single item; one pass of O(n log n), at least half of the optimum.';
  L.short_label = 'Greedy';           % algorithm chip in Knapview
  L.exact = false;
  L.reference = false;
  L.available = @() true;
  L.environment = @() struct();         % nothing to add to environment.algorithms
end
