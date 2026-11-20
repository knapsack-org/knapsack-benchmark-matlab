function kb_print_instance(inst, results, algos, ref)
%KB_PRINT_INSTANCE  Print one line per instance: optimum (value of REF), time and gap of each algorithm.
  opt = results.(ref).value;
  line = sprintf('%3d %-20s n=%2d opt=%5d |', inst.id, inst.family, numel(inst.weights), opt);
  for a = 1:numel(algos)
    x = results.(algos{a});
    mark = '';
    if x.value ~= opt
      gap = 0;
      if opt > 0
        gap = 100 * (opt - x.value) / opt;
      end
      mark = sprintf(' gap %.2f%%', gap);
    end
    line = [line sprintf(' %s %8.4fs%s |', algos{a}, x.cost.wall_time_s, mark)]; %#ok<AGROW>
  end
  disp(line);
end
