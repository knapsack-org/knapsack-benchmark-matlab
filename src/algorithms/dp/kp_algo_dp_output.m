function O = kp_algo_dp_output()
%KP_ALGO_DP_OUTPUT  Benchmark adapter and JSON description of 'dp'.
%   O.run(v, w, C, acfg, seed)  runs KP_ALGO_DP_MAIN, returns the common result struct
%   O.entry(acfg, env)          entry of the JSON "algorithms" array
%   JSON Schema of both: kp_algo_dp_output.schema.json (next to this file)
  O = struct('run', @run_algo, 'entry', @build_entry);
end

function out = run_algo(v, w, C, acfg, seed) %#ok<INUSD>
  [items, info] = kp_algo_dp_main(v, w, C);   % uses no settings (extra arguments would count in whos)
  out = struct('label', label(), 'exact', true, 'proven_optimal', true, ...
               'items', items, 'working_memory_bytes', info.working_memory_bytes, ...
               'operations', info.operations, 'operations_unit', 'table cells');
  out.details = struct('table_cells', info.operations);
end

function e = build_entry(acfg, env) %#ok<INUSD>
  L = kp_algo_dp_loader();
  e = struct('id', L.id, 'label', label(), 'description', L.description, ...
             'short_label', L.short_label, 'exact', L.exact, ...
             'reference', L.reference, 'config', acfg);
end

function s = label()
  L = kp_algo_dp_loader();
  s = L.label;
end
