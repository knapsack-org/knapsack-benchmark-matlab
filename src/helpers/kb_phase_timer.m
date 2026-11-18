function [mark, times] = kb_phase_timer()
%KB_PHASE_TIMER  Phase timer passed to kp_algo_<id>_main as its MARK argument.
%   [MARK, TIMES] = KB_PHASE_TIMER() starts the clock. Each call MARK('name')
%   stores in TIMES('name') the seconds since the previous mark (or since the
%   start) and restarts the clock. TIMES is a containers.Map (handle object).
  times = containers.Map();
  times('_t') = tic;
  mark = @(name) lap(times, name);
end

function lap(times, name)
  times(name) = toc(times('_t'));
  times('_t') = tic;
end
