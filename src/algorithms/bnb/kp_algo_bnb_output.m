function O = kp_algo_bnb_output()
%KP_ALGO_BNB_OUTPUT  Benchmark adapter and JSON description of 'bnb'.
%   O.run(v, w, C, acfg, seed)  runs KP_ALGO_BNB_MAIN, returns the common result struct
%   O.entry(acfg, env)          entry of the JSON "algorithms" array
%   JSON Schema of both: kp_algo_bnb_output.schema.json (next to this file)
  O = struct('run', @run_algo, 'entry', @build_entry);
end

function out = run_algo(v, w, C, acfg, seed) %#ok<INUSD>
  [items, info] = kp_algo_bnb_main(v, w, C, acfg);   % seed not used (it would count in whos)
  L = kp_algo_bnb_loader();
  out = struct('label', L.label, 'exact', true, 'proven_optimal', info.proven_optimal, ...
               'items', items, 'working_memory_bytes', info.working_memory_bytes, ...
               'operations', info.nodes, 'operations_unit', 'nodes');
  out.details = struct('nodes', info.nodes, 'node_limit', acfg.max_nodes, ...
                       'node_limit_reached', ~info.proven_optimal);
end

function e = build_entry(acfg, env) %#ok<INUSD>
  L = kp_algo_bnb_loader();
  e = struct('id', L.id, 'label', L.label, 'description', L.description, ...
             'short_label', L.short_label, 'exact', L.exact, ...
             'reference', L.reference, 'config', acfg);
end
