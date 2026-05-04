# Auto-suggested directed test for addi_negative
# Goal: Verify ADDI with sign-extended negative immediate.

addi x1, x0, -1

# Expected:
# x1 = 0xffffffff