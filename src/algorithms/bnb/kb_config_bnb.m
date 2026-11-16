function c = kb_config_bnb()
%KB_CONFIG_BNB  Default settings of 'bnb' (block cfg.bnb of BENCHMARK_CONFIG).
  c = struct();
  c.max_nodes = 5e6;            % node limit (then the result is not proven optimal)
  c.repeats = 1;                % can explode on strongly correlated instances: 1 run
end
