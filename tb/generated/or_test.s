# Auto-suggested directed test for or
# Goal: Verify bitwise OR operation.

addi x1, x0, 12      # 0b1100
addi x2, x0, 10      # 0b1010
or x3, x1, x2        # expected 0b1110

# Expected:
# x3 = 14