# Auto-suggested directed test for sub
# Goal: Verify SUB register-register operation.

addi x1, x0, 10
addi x2, x0, 5
sub x3, x1, x2

# Expected:
# x1 = 10
# x2 = 5
# x3 = 5