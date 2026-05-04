# Auto-suggested directed test for and
# Goal: Verify bitwise AND operation.

addi x1, x0, 15      # 0b1111
addi x2, x0, 10      # 0b1010
and x3, x1, x2       # expected 0b1010

# Expected:
# x3 = 10