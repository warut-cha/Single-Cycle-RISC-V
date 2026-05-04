# Auto-suggested directed test for slt_false
# Goal: Verify SLT when rs1 >= rs2.

addi x1, x0, 10
addi x2, x0, 5
slt x3, x1, x2

# Expected:
# x3 = 0