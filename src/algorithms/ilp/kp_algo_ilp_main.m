function [items, info] = kp_algo_ilp_main(v, w, C, varargin)
%KP_ALGO_ILP_MAIN  Exact 0-1 knapsack as an integer linear program.
%   [ITEMS, INFO] = KP_ALGO_ILP_MAIN(V, W, C) (settings, seed and phase marks are accepted and not used;
%   no ~ placeholders: Octave would add an ans variable to the whos memory count).
%       max v'*x   s.t.  w'*x <= C,  x binary
%   MATLAB with Optimization Toolbox -> intlinprog (HiGHS since R2024a);
%   GNU Octave (or MATLAB without the toolbox but with glpk) -> glpk (GLPK).
%   INFO: value, solver, status, proven_optimal, nodes (intlinprog only, else NaN),
%   working_memory_bytes (problem data on the MATLAB side; the solver's
%   internal memory is not visible).  ITEMS are 1-based.

  v = v(:);
  w = w(:);
  n = numel(v);
  info = struct('solver', '', 'status', NaN, 'proven_optimal', false, 'nodes', NaN, ...
                'working_memory_bytes', 0);
  is_octave = exist('OCTAVE_VERSION', 'builtin') > 0;

  if ~is_octave && exist('intlinprog') > 0 %#ok<EXIST>
    % gap 0: prove optimality like glpk and scipy milp (default RelativeGapTolerance is 1e-4)
    opts = optimoptions('intlinprog', 'Display', 'off', 'RelativeGapTolerance', 0);
    [x, fval, exitflag, output] = intlinprog(-v, 1:n, w', C, [], [], zeros(n, 1), ...
                                             ones(n, 1), opts); %#ok<ASGLU>
    info.solver = 'intlinprog';
    info.status = exitflag;
    info.proven_optimal = (exitflag == 1);
    if isfield(output, 'numnodes')
      info.nodes = output.numnodes;
    end
  elseif exist('glpk') > 0 %#ok<EXIST>
    param = struct('msglev', 0);         % silent
    [x, fopt, errnum, extra] = glpk(v, w', C, zeros(n, 1), ones(n, 1), 'U', ...
                                    repmat('I', 1, n), -1, param); %#ok<ASGLU>
    info.solver = 'glpk';
    info.status = extra.status;
    info.proven_optimal = (errnum == 0 && extra.status == 5);   % 5 = optimal
  else
    error('kp_algo_ilp_main:noSolver', ...
          'No ILP solver: needs intlinprog (MATLAB Optimization Toolbox) or glpk (GNU Octave).');
  end

  take = round(x(:)') > 0;
  items = find(take);
  best = sum(v(take));
  vars = whos();
  info.working_memory_bytes = sum([vars.bytes]);
  info.value = best;
end
