# Auto-suggested directed test for x0_write_protection
# Goal: Verify attempted write to x0 is ignored.

addi x0, x0, 123
addi x1, x0, 5

# Expected:
# x0 = 0
# x1 = 5