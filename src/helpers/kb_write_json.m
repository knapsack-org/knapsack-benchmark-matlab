function kb_write_json(file, data)
%KB_WRITE_JSON  Write DATA as (pretty-printed) JSON to FILE.
%   Needs jsonencode: GNU Octave >= 7 or MATLAB >= R2016b
%   (pretty printing: Octave >= 7, MATLAB >= R2021a).
  if ~exist('jsonencode')
    error('kb_write_json:noJson', 'jsonencode is not available: use GNU Octave >= 7 or MATLAB >= R2016b.');
  end
  try
    txt = jsonencode(data, 'PrettyPrint', true);
  catch
    txt = jsonencode(data);
  end
  fid = fopen(file, 'w');
  if fid < 0
    error('kb_write_json:open', 'Cannot open %s for writing.', file);
  end
  fprintf(fid, '%s\n', txt);
  fclose(fid);
end
