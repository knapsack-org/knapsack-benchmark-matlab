function c = kp_algo_qc_config()
%KP_ALGO_QC_CONFIG  Settings of 'qc' (block cfg.qc of BENCHMARK_CONFIG).
  c = struct();
  c.penalty = 'auto';           % 'auto' = max(values) + 1, or a number
  tabu = struct();
  tabu.mode = 'slack-optimal';  % 'slack-optimal' (flip item bits, slack bits set optimally)
                                % or 'all-bits' (plain single-bit-flip tabu on the whole QUBO)
  tabu.restarts = 20;           % independent tabu searches from random starts
  tabu.max_iter_factor = 100;   % iterations per restart = factor * N (N = searched bits)
  tabu.stall_factor = 20;       % stop a restart after factor * N iterations without improvement
  tabu.tenure_min = 10;         % tabu tenure = tenure_min + round(N / 10)
  c.tabu = tabu;
  qaoa = struct();              % used only by the (commented) QAOA call of kp_algo_qc_main
  qaoa.layers = 2;              % QAOA depth p (cost + mixer layers)
  qaoa.shots = 200;             % states sampled from the final state vector
  qaoa.grid = 12;               % grid points per angle in the layer-by-layer search
  qaoa.refine = 4;              % rounds of +-h coordinate moves (h halved each round)
  qaoa.max_qubits = 20;         % N = items + slack bits; 2^N amplitudes (20 -> ~16 MB)
  c.qaoa = qaoa;
  c.repeats = 1;                % deterministic and slow: 1 run
end
