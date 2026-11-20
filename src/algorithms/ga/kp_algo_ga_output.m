function O = kp_algo_ga_output()
%KP_ALGO_GA_OUTPUT  Benchmark adapter and JSON description of 'ga'.
%   O.run(v, w, C, acfg, seed)  runs KP_ALGO_GA_MAIN, returns the common result struct
%   O.entry(acfg, env)          entry of the JSON "algorithms" array
%   JSON Schema of both: kp_algo_ga_output.schema.json (next to this file)
  O = struct('run', @run_algo, 'entry', @build_entry);
end

function out = run_algo(v, w, C, acfg, seed)
  [items, info] = kp_algo_ga_main(v, w, C, acfg, seed);
  out = struct('label', label(), 'exact', false, 'proven_optimal', false, ...
               'items', items, 'working_memory_bytes', info.working_memory_bytes, ...
               'operations', info.evaluations, 'operations_unit', 'fitness evaluations');
  out.details = struct('evaluations', info.evaluations, 'generations', info.generations);
end

function e = build_entry(acfg, env) %#ok<INUSD>
  L = kp_algo_ga_loader();
  e = struct('id', L.id, 'label', label(), 'description', L.description, 'short_label', L.short_label, 'exact', L.exact, ...
             'reference', L.reference, 'config', acfg);
end

function s = label()
  L = kp_algo_ga_loader();
  s = L.label;
end
