function kb_print_progress(instance, algorithm, event)
%KB_PRINT_PROGRESS  Progress line read by the knapsack-server worker-agent:
%   @@progress {"instance":<id>,"algorithm":"<id>","event":"start"|"done"}
  fprintf('@@progress {"instance":%d,"algorithm":"%s","event":"%s"}\n', instance, algorithm, event);
  if exist('OCTAVE_VERSION', 'builtin') > 0
    fflush(stdout);   % stdout is a pipe under the agent: send each line at once
  end
end
