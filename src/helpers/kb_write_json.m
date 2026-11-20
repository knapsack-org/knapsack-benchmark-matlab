function txt = kb_write_json(file, data, algos)
%KB_WRITE_JSON  Write DATA as (pretty-printed) JSON to FILE and return the text ('' = no file).
%   KB_WRITE_JSON(FILE, DATA, ALGOS): DATA.algorithm_schemas becomes the content of the
%   kp_algo_<id>_output.schema.json files of ALGOS (from KB_DISCOVER_ALGORITHMS), inserted
%   verbatim (jsondecode would rename their "$schema" key).
%   Needs jsonencode: GNU Octave >= 7 or MATLAB >= R2016b
%   (pretty printing: Octave >= 7, MATLAB >= R2021a).
  if ~exist('jsonencode')
    error('kb_write_json:noJson', 'jsonencode is not available: use GNU Octave >= 7 or MATLAB >= R2016b.');
  end
  marker = '@@algorithm_schemas@@';
  if nargin > 2
    data.algorithm_schemas = marker;
  end
  try
    txt = jsonencode(data, 'PrettyPrint', true);
  catch
    txt = jsonencode(data);
  end
  if nargin > 2
    parts = arrayfun(@(a) sprintf('"%s": %s', a.id, strtrim(fileread(a.schema_file))), algos, ...
                     'UniformOutput', false);
    txt = strrep(txt, ['"' marker '"'], ['{' strjoin(parts, ', ') '}']);
  end
  if isempty(file)
    return;
  end
  fid = fopen(file, 'w');
  if fid < 0
    error('kb_write_json:open', 'Cannot open %s for writing.', file);
  end
  fprintf(fid, '%s\n', txt);
  fclose(fid);
end
