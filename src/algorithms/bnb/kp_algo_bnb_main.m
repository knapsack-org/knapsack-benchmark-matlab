function [items, info] = kp_algo_bnb_main(v, w, C, acfg, varargin)
%KP_ALGO_BNB_MAIN  Exact 0-1 knapsack by depth-first branch and bound.
%   [ITEMS, INFO] = KP_ALGO_BNB_MAIN(V, W, C, ACFG): ACFG.max_nodes is the node
%   limit (default Inf when ACFG is omitted); seed and phase marks are accepted and
%   not used.
%   Items are sorted by value/weight ratio (decreasing). The search always
%   tries "take item k" before "skip item k" and prunes a node when its
%   Dantzig upper bound (LP relaxation: greedy fill + fraction of the critical
%   item, rounded down because values are integers) cannot beat the best
%   solution found so far. The greedy solution is the initial lower bound.
%   Iterative backtracking (no recursion), O(n) memory.
%
%   The node limit stops the search early; INFO.proven_optimal is then false
%   and INFO.value is the best solution found.
%   INFO: value, nodes, proven_optimal, working_memory_bytes. ITEMS are 1-based.

  if nargin < 4
    max_nodes = Inf;
  else
    max_nodes = acfg.max_nodes;
    clear acfg                           % keep working_memory_bytes to the search's own data
  end
  v = v(:)';
  w = w(:)';
  n = numel(v);
  [~, order] = sort(-(v ./ w));          % stable sort: ties keep the index order
  vs = v(order);
  ws = w(order);
  Wc = [0, cumsum(ws)];                  % Wc(i+1) = weight of the first i sorted items
  Vc = [0, cumsum(vs)];

  % greedy initial solution (lower bound)
  bx = zeros(1, n);
  load = 0;
  for i = 1:n
    if load + ws(i) <= C
      bx(i) = 1;
      load = load + ws(i);
    end
  end
  best = vs * bx';

  x = zeros(1, n);
  k = 1;                                 % next item to decide
  load = 0;
  val = 0;
  nodes = 0;
  proven = true;
  while true
    nodes = nodes + 1;
    if nodes > max_nodes
      proven = false;
      break;
    end
    if val > best
      best = val;
      bx = x;
    end

    back = false;
    if k > n
      back = true;
    else
      cap = C - load;
      over = find(Wc(k+1:n+1) - Wc(k) > cap, 1);
      if isempty(over)
        ub = val + Vc(n+1) - Vc(k);      % all remaining items fit
      else
        j = k + over - 1;                % critical item
        ub = val + Vc(j) - Vc(k) + vs(j) * (cap - (Wc(j) - Wc(k))) / ws(j);
      end
      if floor(ub + 1e-9) <= best
        back = true;                     % prune
      elseif load + ws(k) <= C
        x(k) = 1;                        % branch: take item k
        load = load + ws(k);
        val = val + vs(k);
        k = k + 1;
      else
        x(k) = 0;                        % item k does not fit: skip it
        k = k + 1;
      end
    end

    if back                              % undo the last "take" and try "skip"
      i = find(x(1:k-1), 1, 'last');
      if isempty(i)
        break;                           % search tree exhausted
      end
      x(i) = 0;
      load = load - ws(i);
      val = val - vs(i);
      k = i + 1;
    end
  end

  items = sort(order(bx > 0));
  info = struct();
  info.nodes = nodes;
  info.proven_optimal = proven;
  vars = whos();
  info.working_memory_bytes = sum([vars.bytes]);
  info.value = best;
end
