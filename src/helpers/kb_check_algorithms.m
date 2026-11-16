function algos = kb_check_algorithms(requested)
%KB_CHECK_ALGORITHMS  Validate requested algorithm ids; drop ilp when no solver exists.
  known = kb_algorithm_ids();
  algos = {};
  for i = 1:numel(requested)
    name = requested{i};
    if ~any(strcmp(known, name))
      error('run_benchmark:unknownAlgorithm', 'Unknown algorithm "%s".', name);
    end
    if strcmp(name, 'ilp') && isempty(kb_ilp_solver_name({'ilp'}))
      warning('run_benchmark:noIlp', ['No ILP solver (intlinprog or glpk) found: ' ...
              'algorithm "ilp" skipped.']);
      continue;
    end
    algos{end + 1} = name; %#ok<AGROW>
  end
end
