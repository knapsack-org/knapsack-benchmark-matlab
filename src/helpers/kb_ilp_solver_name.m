function name = kb_ilp_solver_name(algos)
%KB_ILP_SOLVER_NAME  'intlinprog' (MATLAB), 'glpk' (Octave) or '' when unavailable / not requested.
  name = '';
  if ~any(strcmp(algos, 'ilp'))
    return;
  end
  if exist('OCTAVE_VERSION', 'builtin') == 0 && exist('intlinprog') > 0 %#ok<EXIST>
    name = 'intlinprog';
  elseif exist('glpk') > 0 %#ok<EXIST>
    name = 'glpk';
  end
end
