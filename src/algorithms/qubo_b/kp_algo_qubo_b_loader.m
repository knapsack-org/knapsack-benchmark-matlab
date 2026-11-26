function L = kp_algo_qubo_b_loader()
%KP_ALGO_QUBO_B_LOADER  Identity of 'qubo_b' for KB_DISCOVER_ALGORITHMS.
  L = struct();
  L.id = 'qubo_b';                    % must equal the folder name
  L.label = 'QUBO B + Tabu Search';
  L.description = ['Variant B (same code as variant A for now). Heuristic: the knapsack written as a QUBO (capacity as a squared penalty ' ...
                   'with a binary-encoded slack), minimised by a multi-start tabu search, ' ...
                   'then decoded and repaired if infeasible.'];
  L.short_label = 'QUBO B';             % algorithm chip in Knapview
  L.exact = false;
  L.reference = false;
  L.available = @() true;
  % TODO(knapsack2qubo) step 2: once the build uses MathWorks knapsack2qubo, write
  %   L.available = @() exist('knapsack2qubo', 'file') == 2;
  % so GNU Octave (no Quantum Computing support package) lists qubo_b in
  % skipped_algorithms instead of failing, and let L.environment report the package:
  %   L.environment = @() struct('support_package', 'MATLAB Support Package for Quantum Computing');
  L.environment = @() struct();         % nothing to add to environment.algorithms
end
