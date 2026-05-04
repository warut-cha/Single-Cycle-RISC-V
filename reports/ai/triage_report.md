## Status Summary

- Simulation: **PASS**
- Linting: **PASS**
- Synthesis: **FAIL**


## Verilator Findings

- No Verilator warnings/errors detected.

## Simulation Log Excerpt

```text
 0
Time: 115000 | PC: 0000002c | Inst: 00120213 | Op: 13 | x0: 0 | x1: 4294967295 | x2: 1 | x3: 0
Time: 125000 | PC: 00000030 | Inst: 0ff00293 | Op: 13 | x0: 0 | x1: 4294967295 | x2: 1 | x3: 0
Time: 135000 | PC: 00000034 | Inst: f0f00313 | Op: 13 | x0: 0 | x1: 4294967295 | x2: 1 | x3: 0
Time: 145000 | PC: 00000038 | Inst: 0062f3b3 | Op: 33 | x0: 0 | x1: 4294967295 | x2: 1 | x3: 0
Time: 155000 | PC: 0000003c | Inst: 0062e433 | Op: 33 | x0: 0 | x1: 4294967295 | x2: 1 | x3: 0
Time: 165000 | PC: 00000040 | Inst: 405304b3 | Op: 33 | x0: 0 | x1: 4294967295 | x2: 1 | x3: 0
Time: 175000 | PC: 00000044 | Inst: 00448533 | Op: 33 | x0: 0 | x1: 4294967295 | x2: 1 | x3: 0
Time: 185000 | PC: 00000048 | Inst: 00000013 | Op: 13 | x0: 0 | x1: 4294967295 | x2: 1 | x3: 0
Time: 195000 | PC: 0000004c | Inst: 06400093 | Op: 13 | x0: 0 | x1: 4294967295 | x2: 1 | x3: 0
Time: 205000 | PC: 00000050 | Inst: 02a00113 | Op: 13 | x0: 0 | x1: 100 | x2: 1 | x3: 0
Time: 215000 | PC: 00000054 | Inst: 0020a023 | Op: 23 | x0: 0 | x1: 100 | x2: 42 | x3: 0
Time: 225000 | PC: 00000058 | Inst: 0000a183 | Op: 03 | x0: 0 | x1: 100 | x2: 42 | x3: 0
Time: 235000 | PC: 0000005c | Inst: 00500093 | Op: 13 | x0: 0 | x1: 100 | x2: 42 | x3: 42
Time: 245000 | PC: 00000060 | Inst: 00000113 | Op: 13 | x0: 0 | x1: 5 | x2: 42 | x3: 42
Time: 255000 | PC: 00000064 | Inst: 001101b3 | Op: 33 | x0: 0 | x1: 5 | x2: 0 | x3: 42
Cloud CI Verification
Executed math/mem. x3 = 42
Shutting down
tb/top_tb.sv:54: $finish called at 260000 (1ps)

```


## Suggested Debug Prio

1. Investigate X propagation in simulation and add strict `!==` checks.
2. Fix synthesis errors before trusting area/netlist reports.

## Recommended Regression Additions

- Add explicit PASS/FAIL checks in `tb/top_tb.sv`.
- Fail the test if any observed register is X/Z.
- Add one directed test for each supported instruction.
- Save VCD waveforms as CI artifacts only on failure.