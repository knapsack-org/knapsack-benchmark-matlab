function c = kp_algo_bnb_config()
%KP_ALGO_BNB_CONFIG  Settings of 'bnb' (block cfg.bnb of BENCHMARK_CONFIG).
  c = struct();
  c.max_nodes = 5e6;            % node limit (then the result is not proven optimal)
  c.repeats = 1;                % can explode on strongly correlated instances: 1 run
end
