function name = kb_interpreter()
%KB_INTERPRETER  'GNU Octave' or 'MATLAB'.
  if exist('OCTAVE_VERSION', 'builtin') > 0
    name = 'GNU Octave';
  else
    name = 'MATLAB';
  end
end
