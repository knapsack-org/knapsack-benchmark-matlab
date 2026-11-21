function O = kp_algo_ilp_output()
%KP_ALGO_ILP_OUTPUT  Benchmark adapter and JSON description of 'ilp'.
%   O.run(v, w, C, acfg, seed)  runs KP_ALGO_ILP_MAIN, returns the common result struct
%   O.entry(acfg, env)          entry of the JSON "algorithms" array (env = loader environment)
%   JSON Schema of both: kp_algo_ilp_output.schema.json (next to this file)
  O = struct('run', @run_algo, 'entry', @build_entry);
end

function out = run_algo(v, w, C, acfg, seed) %#ok<INUSD>
  [items, info] = kp_algo_ilp_main(v, w, C, acfg.time_limit_s);   % only the limit: arguments count in whos
  out = struct('label', label(info.solver), 'exact', true, ...
               'proven_optimal', info.proven_optimal, 'items', items, ...
               'working_memory_bytes', info.working_memory_bytes, ...
               'operations', info.nodes, 'operations_unit', 'nodes');
  out.details = struct('solver', info.solver, 'status', info.status);
end

function e = build_entry(acfg, env)
  L = kp_algo_ilp_loader();
  e = struct('id', L.id, 'label', label(env.solver), 'description', L.description, ...
             'short_label', L.short_label, ...
             'exact', L.exact, 'reference', L.reference, 'config', acfg);
end

function s = label(solver)
  L = kp_algo_ilp_loader();
  s = [L.label ' (' solver ')'];
end
