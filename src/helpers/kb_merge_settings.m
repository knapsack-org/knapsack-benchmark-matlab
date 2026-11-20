function out = kb_merge_settings(base, override, where)
%KB_MERGE_SETTINGS  BASE with the fields of OVERRIDE (nested structs merged).
%   An OVERRIDE field that BASE does not have is an error (identifier
%   kb_merge_settings:unknown); WHERE names BASE in the message, e.g. 'sa'.
  out = base;
  for f = fieldnames(override)'
    key = f{1};
    if ~isfield(base, key)
      error('kb_merge_settings:unknown', 'Unknown setting "%s.%s".', where, key);
    end
    if isstruct(base.(key)) && isstruct(override.(key))
      out.(key) = kb_merge_settings(base.(key), override.(key), [where '.' key]);
    else
      out.(key) = override.(key);
    end
  end
end
