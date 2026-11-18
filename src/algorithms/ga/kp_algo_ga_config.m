function c = kp_algo_ga_config()
%KP_ALGO_GA_CONFIG  Settings of 'ga' (block cfg.ga of BENCHMARK_CONFIG).
  c = struct();
  c.pop_size = 30;              % individuals per generation (one elite kept)
  c.generations = 50;           % generations after the random start
  c.tournament = 2;             % individuals drawn per parent selection
  c.crossover_rate = 0.9;       % probability of uniform crossover (else copy of parent 1)
  c.mutation_factor = 1.0;      % per-bit flip probability = factor / n
  c.repeats = 1;                % randomised and slower: 1 run
end
