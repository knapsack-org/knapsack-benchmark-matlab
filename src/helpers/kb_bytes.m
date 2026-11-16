function b = kb_bytes(varargin)
%KB_BYTES  Total memory (bytes) of the given arrays, as reported by whos.
  b = 0;
  for i = 1:numel(varargin)
    item = varargin{i}; %#ok<NASGU>
    s = whos('item');
    b = b + s.bytes;
  end
end
