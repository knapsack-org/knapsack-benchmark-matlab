function L = kp_algo_ising_loader()
%KP_ALGO_ISING_LOADER  Identity of 'ising' for KB_DISCOVER_ALGORITHMS.
  L = struct();
  L.id = 'ising';                   % must equal the folder name
  L.label = 'Ising Hamiltonian + Simulated Annealing';
  L.description = 'The penalty/slack QUBO rewritten as an Ising Hamiltonian on n + K spins and minimised by single-spin-flip annealing; the best spins are decoded and repaired if overweight.';
  L.short_label = 'Ising';            % algorithm chip in Knapview
  L.exact = false;
  L.reference = false;
  L.available = @() true;
  L.environment = @() struct();         % nothing to add to environment.algorithms
end
