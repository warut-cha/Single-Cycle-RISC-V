# Auto-suggested directed test for add
# Goal: Verify ADD register-register operation.

addi x1, x0, 5
addi x2, x0, 10
add x3, x1, x2

# Expected:
# x1 = 5
# x2 = 10
# x3 = 15