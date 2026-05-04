# Auto-suggested directed test for lw_sw
# Goal: Verify SW followed by LW.

addi x1, x0, 256
addi x2, x0, 42
sw   x2, 0(x1)
lw x3, 0(x1)

# Expected:
# x3 = 42