function s = kb_human_bytes(b)
%KB_HUMAN_BYTES  Byte count as a short string (B, kB, MB; n/a for NaN).
  if isnan(b)
    s = 'n/a';
  elseif b >= 2^20
    s = sprintf('%.1fMB', b / 2^20);
  elseif b >= 2^10
    s = sprintf('%.1fkB', b / 2^10);
  else
    s = sprintf('%dB', round(b));
  end
end
