function s = kb_summary(runs, algos, total_time)
%KB_SUMMARY  Per-algorithm and per-family summary statistics of a benchmark run.
  s = struct();
  s.num_instances = numel(runs);
  s.total_time_seconds = total_time;
  R = [runs.results];
  fam_all = {runs.family};

  per = struct();
  med_time = zeros(1, numel(algos));
  for a = 1:numel(algos)
    name = algos{a};
    res = [R.(name)];
    cost = [res.cost];
    ratio = [res.cost_ratio_vs_reference];
    gaps = [res.gap_percent];
    t = [cost.wall_time_s];
    m = [cost.working_memory_bytes];

    p = struct();
    p.algorithm = res(1).algorithm;
    p.exact = res(1).exact;
    p.num_optimal = sum([res.is_optimal]);
    p.num_proven_optimal = sum([res.proven_optimal]);
    p.num_feasible = sum([res.feasible]);
    p.mean_gap_percent = mean(gaps);
    p.max_gap_percent = max(gaps);
    p.total_wall_time_s = sum(t);
    p.mean_wall_time_s = mean(t);
    p.median_wall_time_s = median(t);
    p.max_wall_time_s = max(t);
    p.mean_cpu_time_s = mean([cost.cpu_time_s]);
    p.mean_working_memory_bytes = mean(m);
    p.median_working_memory_bytes = median(m);
    p.max_working_memory_bytes = max(m);
    p.mean_operations = mean([cost.operations]);
    p.max_operations = max([cost.operations]);
    p.operations_unit = cost(1).operations_unit;
    p.median_time_ratio_vs_reference = median([ratio.time]);
    p.median_memory_ratio_vs_reference = median([ratio.memory]);

    families = unique(fam_all);
    by = [];
    for f = 1:numel(families)
      sel = strcmp(fam_all, families{f});
      b = struct('family', families{f}, 'count', sum(sel), ...
                 'num_optimal', sum([res(sel).is_optimal]), ...
                 'mean_gap_percent', mean(gaps(sel)), ...
                 'mean_wall_time_s', mean(t(sel)), ...
                 'max_wall_time_s', max(t(sel)), ...
                 'mean_working_memory_bytes', mean(m(sel)));
      if isempty(by)
        by = b;
      else
        by(end + 1) = b; %#ok<AGROW>
      end
    end
    p.by_family = by;

    per.(name) = p;
    med_time(a) = p.median_wall_time_s;
  end
  s.algorithms = per;
  [~, order] = sort(med_time);
  s.ranking_by_median_time = algos(order);
end
