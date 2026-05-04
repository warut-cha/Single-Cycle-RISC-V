# Auto-suggested directed test for slt_signed
# Goal: Verify signed SLT behavior with a negative operand.

addi x1, x0, -1
addi x2, x0, 1
slt x3, x1, x2

# Expected:
# x3 = 1