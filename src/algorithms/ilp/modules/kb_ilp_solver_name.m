function name = kb_ilp_solver_name()
%KB_ILP_SOLVER_NAME  'intlinprog' (MATLAB), 'glpk' (Octave) or '' when no ILP solver exists.
  name = '';
  if exist('OCTAVE_VERSION', 'builtin') == 0 && exist('intlinprog') > 0 %#ok<EXIST>
    name = 'intlinprog';
  elseif exist('glpk') > 0 %#ok<EXIST>
    name = 'glpk';
  end
end
