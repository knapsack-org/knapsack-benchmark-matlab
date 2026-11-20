function [items, info] = kp_algo_ga_main(v, w, C, acfg, seed, ~)
%KP_ALGO_GA_MAIN  Generational genetic algorithm with greedy repair, one elite per generation.
%   [ITEMS, INFO] = KP_ALGO_GA_MAIN(V, W, C, ACFG, SEED): ACFG = cfg.ga, SEED = cfg.seed + 1000*k.
%   Repair of every chromosome (start, child): while overweight drop the taken item with the
%   lowest v/w, then add, in decreasing v/w, every item that still fits. All chromosomes are
%   therefore feasible and the fitness is the packing value. Parent selection: tournament of
%   ACFG.tournament random individuals (best value wins, first drawn on ties); uniform crossover
%   with probability crossover_rate (else the child copies the first parent); each bit flips with
%   probability mutation_factor / n. Each child uses 2 * tournament + 1 + 2 * n consecutive numbers
%   of the portable LCG: 2 * tournament selection draws, 1 crossover draw, n mask draws, n mutation
%   draws (all drawn even if unused).
%   Speed (same results): the run draws a fixed count of numbers, all taken from KB_LCG_STATES at
%   once; the children of a generation are independent, so selection, crossover, mutation and the
%   repair are done on all of them at once (matrix rows; all sums are exact integers).
%   INFO: evaluations (fitness evaluations), generations, working_memory_bytes. ITEMS 1-based.
  v = v(:)';
  w = w(:)';
  n = numel(v);
  [~, order] = sort(-(v ./ w));          % decreasing ratio, ties keep the index order
  drop_order = fliplr(order);
  siz = acfg.pop_size;
  tour = acfg.tournament;
  mrate = acfg.mutation_factor / n;
  K = siz - 1;                           % children per generation (one elite kept)
  D = 2 * tour + 1 + 2 * n;              % numbers drawn per child
  U = kb_lcg_states(kb_seed(seed), siz * n + acfg.generations * K * D) / 2147483647;

  [pop, fit] = repair(reshape(U(1:siz * n), n, siz)' < 0.5, v, w, C, order, drop_order);
  evaluations = siz;
  [~, best] = max(fit);
  best_x = pop(best, :);
  best_v = fit(best);
  rows = (1:K)';
  for g = 1:acfg.generations
    u = reshape(U(siz * n + (g - 1) * K * D + (1:K * D)), D, K)';   % row k: the draws of child k
    cand = min(floor(u(:, 1:2 * tour) * siz), siz - 1) + 1;
    f = reshape(fit(cand), K, 2 * tour);
    [~, i1] = max(f(:, 1:tour), [], 2);  % best value wins, first drawn on ties
    [~, i2] = max(f(:, tour + 1:end), [], 2);
    a = pop(cand(rows + K * (i1 - 1)), :);
    b = pop(cand(rows + K * (tour + i2 - 1)), :);
    off = 2 * tour;
    x = a;
    cross = (u(:, off + 1) < acfg.crossover_rate) & (u(:, off + 2:off + 1 + n) >= 0.5);
    x(cross) = b(cross);
    mut = u(:, off + n + 2:end) < mrate;
    x(mut) = ~x(mut);
    [x, fx] = repair(x, v, w, C, order, drop_order);
    new_pop = [pop(best, :); x];                                  % elite first
    new_fit = [fit(best), fx];
    evaluations = evaluations + K;
    pop = new_pop;
    fit = new_fit;
    [~, best] = max(fit);
    if fit(best) > best_v
      best_x = pop(best, :);
      best_v = fit(best);
    end
  end
  items = find(best_x);
  info = struct('evaluations', evaluations, 'generations', acfg.generations, ...
                'working_memory_bytes', kb_bytes(v, w, pop, new_pop));
end

function [x, val] = repair(x, v, w, C, order, drop_order)
%REPAIR  Every row: while overweight drop the taken item with the lowest v/w, then add, in
%   decreasing v/w, every item that still fits; VAL = row values (row vector).
  W = double(x) * w';
  xd = x(:, drop_order);
  wd = w(drop_order);
  cw = cumsum(xd .* wd, 2);              % weight removed if every taken item up to here goes
  drop = xd & ([W, W - cw(:, 1:end - 1)] > C);   % taken and still overweight before it
  x(:, drop_order) = xd & ~drop;
  W = W - sum(drop .* wd, 2);
  xo = x(:, order);
  wo = w(order);
  woc = wo(:);
  free = ~xo;                            % items that may still be added
  col = 1:numel(order);
  while true
    [ok, k] = max(free & (W + wo <= C), [], 2);   % first item that fits in each row
    r = find(ok);
    if isempty(r)
      break;
    end
    xo(r + size(xo, 1) * (k(r) - 1)) = true;
    W(r) = W(r) + woc(k(r));
    free(r, :) = free(r, :) & (col > k(r));      % the earlier ones never fit again (W grows)
  end
  x(:, order) = xo;
  val = (double(x) * v')';
end
