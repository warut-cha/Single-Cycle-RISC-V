# Auto-suggested directed test for xor
# Goal: Verify bitwise XOR operation.

addi x1, x0, 12      # 0b1100
addi x2, x0, 10      # 0b1010
xor x3, x1, x2       # expected 0b0110

# Expected:
# x3 = 6