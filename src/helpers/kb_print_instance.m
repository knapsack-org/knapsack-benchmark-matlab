function kb_print_instance(r, algos)
%KB_PRINT_INSTANCE  Print one line per instance: optimum, time and gap of each algorithm.
  line = sprintf('%3d %-20s n=%2d opt=%5d |', r.id, r.family, r.n, r.optimum);
  for a = 1:numel(algos)
    x = r.results.(algos{a});
    mark = '';
    if ~x.is_optimal
      mark = sprintf(' gap %.2f%%', x.gap_percent);
    end
    line = [line sprintf(' %s %8.4fs%s |', algos{a}, x.cost.wall_time_s, mark)]; %#ok<AGROW>
  end
  disp(line);
end
