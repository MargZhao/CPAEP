# CPAEP Project 
- This project template contains 3 structure: 4x4x4, 4x16 and 1x64, where the last number indicates the number of input to each PE(parfor K).
- Our final design is 4x4x4, but feel free to play with the other 2 :)


# Quick Start
The testbench of the 3 structure is tb_444_mac_gemm,  tb_mac_2D_gemm,  tb_one_mac_gemm. The corresponding top module and submodule can be find in \rtl folder

To run the simulation, 
```bash
make TEST_MODULE=tb_444_mac_gemm questasim-run
```

To run with a GUI do:

```bash
make TEST_MODULE=tb_444_mac_gemm questasim-run-gui
```

You can modify the NumTests parameter in the tb to do more test.

```bash
Some long log of the previous tests.
...
# Test number: 8
# M: 9, K: 13, N: 10
# GEMM operation completed in 1170 cycles
# Result matrix C verification passed!
# Test number: 9
# M: 11, K: 16, N: 3
# GEMM operation completed in 528 cycles
# Result matrix C verification passed!
# All test tasks completed successfully!
# ** Note: $finish    : tb/tb_one_mac_gemm.sv(286)
#    Time: 410816 ns  Iteration: 0  Instance: /tb_one_mac_gemm
# End time: 10:12:59 on Nov 27,2025, Elapsed time: 0:00:01
# Errors: 0, Warnings: 3
```
