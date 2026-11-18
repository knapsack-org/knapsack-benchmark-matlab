function L = kp_algo_ilp_loader()
%KP_ALGO_ILP_LOADER  Identity of 'ilp' for KB_DISCOVER_ALGORITHMS.
%   Available only when an ILP solver exists (intlinprog in MATLAB, glpk in Octave).
  L = struct();
  L.id = 'ilp';                         % must equal the folder name
  L.label = 'Integer Linear Programming';
  L.description = ['Exact integer linear program: maximise the packed value subject to the ' ...
                   'capacity, with binary variables, solved by a MILP solver (glpk or ' ...
                   'intlinprog in MATLAB, HiGHS in Python).'];
  L.short_label = 'ILP';                % algorithm chip in Knapview
  L.exact = true;
  L.reference = false;
  L.available = @() ~isempty(kb_ilp_solver_name());
  L.environment = @() struct('solver', kb_ilp_solver_name());   % -> environment.algorithms.ilp
end
