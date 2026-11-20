function O = kp_algo_greedy_output()
%KP_ALGO_GREEDY_OUTPUT  Benchmark adapter and JSON description of 'greedy'.
%   O.run(v, w, C, acfg, seed)  runs KP_ALGO_GREEDY_MAIN, returns the common result struct
%   O.entry(acfg, env)          entry of the JSON "algorithms" array
%   JSON Schema of both: kp_algo_greedy_output.schema.json (next to this file)
  O = struct('run', @run_algo, 'entry', @build_entry);
end

function out = run_algo(v, w, C, acfg, seed)
  [items, info] = kp_algo_greedy_main(v, w, C, acfg, seed);
  out = struct('label', label(), 'exact', false, 'proven_optimal', false, ...
               'items', items, 'working_memory_bytes', info.working_memory_bytes, ...
               'operations', info.operations, 'operations_unit', 'items scanned');
  out.details = struct('greedy_value', info.greedy_value, 'single_value', info.single_value, ...
                       'chose_single', info.chose_single);
end

function e = build_entry(acfg, env) %#ok<INUSD>
  L = kp_algo_greedy_loader();
  e = struct('id', L.id, 'label', label(), 'description', L.description, 'short_label', L.short_label, 'exact', L.exact, ...
             'reference', L.reference, 'config', acfg);
end

function s = label()
  L = kp_algo_greedy_loader();
  s = L.label;
end
