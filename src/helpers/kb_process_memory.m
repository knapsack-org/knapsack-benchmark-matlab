function bytes = kb_process_memory()
%KB_PROCESS_MEMORY  Memory currently used by the Octave/MATLAB process (bytes).
%   Uses memory(): GNU Octave on Linux and Windows, MATLAB on Windows only.
%   Returns NaN (written as null in the JSON) when it is not available.
%   This is a process-wide snapshot, not the peak of one call: use it as an
%   indication only; the per-algorithm working memory comes from KB_BYTES.
  bytes = NaN;
  try
    user = memory();
    if isfield(user, 'ram_used_octave')
      bytes = user.ram_used_octave;          % Octave: physical RAM of the process
    elseif isfield(user, 'MemUsedMATLAB')
      bytes = user.MemUsedMATLAB;            % MATLAB (Windows)
    end
  catch
    bytes = NaN;
  end
end
