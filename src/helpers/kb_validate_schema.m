function kb_validate_schema(x, schema, where)
%KB_VALIDATE_SCHEMA  Check a MATLAB value against a JSON Schema (subset); error if it does not match.
%   KB_VALIDATE_SCHEMA(X, SCHEMA, WHERE): SCHEMA is a struct, usually from
%   jsondecode of the schema text in kp_algo_<id>_output. WHERE names X in the
%   error message (default '$'). Supported keywords: type (object, array,
%   string, number, integer, boolean, null, or a list of them), enum, minimum,
%   properties, required, additionalProperties (false only), items.
%   Values are checked as they will be written by jsonencode: arrays must be
%   cells (num2cell), NaN and [] are null.
  if nargin < 3
    where = '$';
  end
  if isfield(schema, 'type')
    types = schema.type;
    if ischar(types)
      types = {types};
    end
    if ~any(cellfun(@(t) is_type(x, t), types))
      fail(where, sprintf('expected %s, got %s', strjoin(types(:)', ' or '), class(x)));
    end
  end
  if isfield(schema, 'enum')
    allowed = schema.enum;
    if ischar(allowed)
      allowed = {allowed};
    elseif ~iscell(allowed)
      allowed = num2cell(allowed);
    end
    if ~any(cellfun(@(e) isequal(e, x), allowed))
      fail(where, 'value not in enum');
    end
  end
  if isfield(schema, 'minimum') && isnumeric(x) && isscalar(x) && x < schema.minimum
    fail(where, sprintf('%g < minimum %g', x, schema.minimum));
  end
  if isstruct(x) && isscalar(x)
    if isfield(schema, 'required')
      req = schema.required;
      if ischar(req)
        req = {req};
      end
      for i = 1:numel(req)
        if ~isfield(x, req{i})
          fail(where, ['missing required field "' req{i} '"']);
        end
      end
    end
    props = struct();
    if isfield(schema, 'properties')
      props = schema.properties;
    end
    closed = isfield(schema, 'additionalProperties') && isequal(schema.additionalProperties, false);
    names = fieldnames(x);
    for i = 1:numel(names)
      if isfield(props, names{i})
        kb_validate_schema(x.(names{i}), props.(names{i}), [where '.' names{i}]);
      elseif closed
        fail(where, ['unexpected field "' names{i} '"']);
      end
    end
  end
  if iscell(x) && isfield(schema, 'items')
    for i = 1:numel(x)
      kb_validate_schema(x{i}, schema.items, sprintf('%s[%d]', where, i));
    end
  end
end

function ok = is_type(x, t)
  num = isnumeric(x) && isscalar(x) && isreal(x) && ~isnan(x);
  switch t
    case 'object',  ok = isstruct(x) && isscalar(x);
    case 'array',   ok = iscell(x);
    case 'string',  ok = ischar(x) && (isrow(x) || isempty(x));
    case 'boolean', ok = islogical(x) && isscalar(x);
    case 'number',  ok = num;
    case 'integer', ok = num && x == round(x);
    case 'null',    ok = isnumeric(x) && (isempty(x) || (isscalar(x) && isnan(x)));
    otherwise
      error('kb_validate_schema:keyword', 'Unsupported type "%s".', t);
  end
end

function fail(where, msg)
  error('kb_validate_schema:invalid', '%s: %s', where, msg);
end
