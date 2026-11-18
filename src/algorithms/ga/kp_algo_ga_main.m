function [items, info] = kp_algo_ga_main(v, w, C, acfg, seed, ~)
%KP_ALGO_GA_MAIN  Generational genetic algorithm with greedy repair, one elite per generation.
%   [ITEMS, INFO] = KP_ALGO_GA_MAIN(V, W, C, ACFG, SEED): ACFG = cfg.ga, SEED = cfg.seed + 1000*k.
%   Repair of every chromosome (start, child): while overweight drop the taken item with the
%   lowest v/w, then add, in decreasing v/w, every item that still fits. All chromosomes are
%   therefore feasible and the fitness is the packing value. Parent selection: tournament of
%   ACFG.tournament random individuals (best value wins, first drawn on ties); uniform crossover
%   with probability crossover_rate (else the child copies the first parent); each bit flips with
%   probability mutation_factor / n. Each child uses ONE call of KB_LCG: 2 * tournament selection
%   draws, 1 crossover draw, n mask draws, n mutation draws (all drawn even if unused).
%   INFO: evaluations (fitness evaluations), generations, working_memory_bytes. ITEMS 1-based.
  v = v(:)';
  w = w(:)';
  n = numel(v);
  [~, order] = sort(-(v ./ w));          % decreasing ratio, ties keep the index order
  drop_order = fliplr(order);
  siz = acfg.pop_size;
  tour = acfg.tournament;
  mrate = acfg.mutation_factor / n;
  state = kb_seed(seed);

  pop = false(siz, n);
  fit = zeros(1, siz);
  [u, state] = kb_lcg(state, siz * n);
  for k = 1:siz
    [x, fit(k)] = repair(u((k - 1) * n + 1:k * n) < 0.5, v, w, C, order, drop_order);
    pop(k, :) = x;
  end
  evaluations = siz;
  [~, best] = max(fit);
  best_x = pop(best, :);
  best_v = fit(best);
  for g = 1:acfg.generations
    new_pop = false(siz, n);
    new_fit = zeros(1, siz);
    new_pop(1, :) = pop(best, :);                                % elite
    new_fit(1) = fit(best);
    for k = 2:siz
      [u, state] = kb_lcg(state, 2 * tour + 1 + 2 * n);
      parents = zeros(1, 2);
      for p = 0:1
        cand = min(floor(u(p * tour + 1:(p + 1) * tour) * siz), siz - 1) + 1;
        win = cand(1);
        for c = cand(2:end)
          if fit(c) > fit(win)
            win = c;
          end
        end
        parents(p + 1) = win;
      end
      a = pop(parents(1), :);
      b = pop(parents(2), :);
      off = 2 * tour;
      if u(off + 1) < acfg.crossover_rate
        mask = u(off + 2:off + 1 + n);
        x = a;
        x(mask >= 0.5) = b(mask >= 0.5);
      else
        x = a;
      end
      mut = u(off + n + 2:end);
      x(mut < mrate) = ~x(mut < mrate);
      [x, new_fit(k)] = repair(x, v, w, C, order, drop_order);
      new_pop(k, :) = x;
      evaluations = evaluations + 1;
    end
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
  W = sum(w(x));
  if W > C
    for i = drop_order
      if x(i)
        x(i) = false;
        W = W - w(i);
        if W <= C
          break;
        end
      end
    end
  end
  for i = order
    if ~x(i) && W + w(i) <= C
      x(i) = true;
      W = W + w(i);
    end
  end
  val = sum(v(x));
end
