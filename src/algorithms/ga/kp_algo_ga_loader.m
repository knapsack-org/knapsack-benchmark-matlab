function L = kp_algo_ga_loader()
%KP_ALGO_GA_LOADER  Identity of 'ga' for KB_DISCOVER_ALGORITHMS.
  L = struct();
  L.id = 'ga';                      % must equal the folder name
  L.label = 'Genetic Algorithm (Greedy Repair)';
  L.description = 'Population of bit strings evolved by tournament selection, uniform crossover and bit-flip mutation; every child is repaired by dropping the lowest value/weight items and refilling by ratio, one elite is kept.';
  L.short_label = 'GA';               % algorithm chip in Knapview
  L.exact = false;
  L.reference = false;
  L.available = @() true;
  L.environment = @() struct();         % nothing to add to environment.algorithms
end
