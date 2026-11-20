function O = kp_algo_sa_output()
%KP_ALGO_SA_OUTPUT  Benchmark adapter and JSON description of 'sa'.
%   O.run(v, w, C, acfg, seed)  runs KP_ALGO_SA_MAIN, returns the common result struct
%   O.entry(acfg, env)          entry of the JSON "algorithms" array
%   JSON Schema of both: kp_algo_sa_output.schema.json (next to this file)
  O = struct('run', @run_algo, 'entry', @build_entry);
end

function out = run_algo(v, w, C, acfg, seed)
  [items, info] = kp_algo_sa_main(v, w, C, acfg, seed);
  out = struct('label', label(), 'exact', false, 'proven_optimal', false, ...
               'items', items, 'working_memory_bytes', info.working_memory_bytes, ...
               'operations', info.proposals, 'operations_unit', 'move evaluations');
  out.details = struct('penalty', info.penalty, 'proposals', info.proposals, ...
                       'accepted', info.accepted, 't_start', info.t_start, 't_end', info.t_end);
end

function e = build_entry(acfg, env) %#ok<INUSD>
  L = kp_algo_sa_loader();
  e = struct('id', L.id, 'label', label(), 'description', L.description, 'short_label', L.short_label, 'exact', L.exact, ...
             'reference', L.reference, 'config', acfg);
end

function s = label()
  L = kp_algo_sa_loader();
  s = L.label;
end
