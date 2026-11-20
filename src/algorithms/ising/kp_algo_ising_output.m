function O = kp_algo_ising_output()
%KP_ALGO_ISING_OUTPUT  Benchmark adapter and JSON description of 'ising'.
%   O.run(v, w, C, acfg, seed)  runs KP_ALGO_ISING_MAIN, times its phases (build, solve,
%                               decode), returns the common result struct
%   O.entry(acfg, env)          entry of the JSON "algorithms" array
%   JSON Schema of both: kp_algo_ising_output.schema.json (next to this file)
  O = struct('run', @run_algo, 'entry', @build_entry);
end

function out = run_algo(v, w, C, acfg, seed)
  [mark, t] = kb_phase_timer();
  [items, info] = kp_algo_ising_main(v, w, C, acfg, seed, mark);
  sol = info.sol;
  out = struct('label', label(), 'exact', false, 'proven_optimal', false, 'items', items, ...
               'working_memory_bytes', info.working_memory_bytes, ...
               'operations', info.proposals, 'operations_unit', 'move evaluations');
  dt = struct();
  dt.penalty = info.penalty;
  dt.variables = info.variables;
  dt.slack_bits = info.slack_bits;
  dt.model_memory_bytes = info.model_memory_bytes;
  dt.energy = info.energy;
  dt.proposals = info.proposals;
  dt.accepted = info.accepted;
  dt.raw_items = num2cell(sol.items);
  dt.raw_value = sol.value;
  dt.raw_weight = sol.weight;
  dt.feasible_before_repair = sol.feasible;
  dt.repaired = sol.repaired;
  dt.build_time_s = t('build');
  dt.solve_time_s = t('solve');
  dt.decode_time_s = t('decode');
  out.details = dt;
end

function e = build_entry(acfg, env) %#ok<INUSD>
  L = kp_algo_ising_loader();
  e = struct('id', L.id, 'label', label(), 'description', L.description, 'short_label', L.short_label, 'exact', L.exact, ...
             'reference', L.reference, 'config', acfg);
end

function s = label()
  L = kp_algo_ising_loader();
  s = L.label;
end
