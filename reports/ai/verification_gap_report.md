# Verification Gap Report

## Detected Test Coverage From Existing Files

- `add` appears to be covered or mentioned.
- `and` appears to be covered or mentioned.
- `mul` appears to be covered or mentioned.
- `or` appears to be covered or mentioned.
- `sub` appears to be covered or mentioned.
- `xor` appears to be covered or mentioned.

## Suggested Directed Tests

### Strengthen coverage: `add`
- Goal: Verify ADD register-register operation.
- Program:
```asm
addi x1, x0, 5
addi x2, x0, 10
add x3, x1, x2
```
- Expected:
  - `x1 = 5`
  - `x2 = 10`
  - `x3 = 15`

### Strengthen coverage: `sub`
- Goal: Verify SUB register-register operation.
- Program:
```asm
addi x1, x0, 10
addi x2, x0, 5
sub x3, x1, x2
```
- Expected:
  - `x1 = 10`
  - `x2 = 5`
  - `x3 = 5`

### Strengthen coverage: `and`
- Goal: Verify bitwise AND operation.
- Program:
```asm
addi x1, x0, 15      # 0b1111
addi x2, x0, 10      # 0b1010
and x3, x1, x2       # expected 0b1010
```
- Expected:
  - `x3 = 10`

### Strengthen coverage: `or`
- Goal: Verify bitwise OR operation.
- Program:
```asm
addi x1, x0, 12      # 0b1100
addi x2, x0, 10      # 0b1010
or x3, x1, x2        # expected 0b1110
```
- Expected:
  - `x3 = 14`

### Strengthen coverage: `xor`
- Goal: Verify bitwise XOR operation.
- Program:
```asm
addi x1, x0, 12      # 0b1100
addi x2, x0, 10      # 0b1010
xor x3, x1, x2       # expected 0b0110
```
- Expected:
  - `x3 = 6`

### Strengthen coverage: `mul`
- Goal: Verify MUL operation.
- Program:
```asm
addi x1, x0, 5
addi x2, x0, 10
mul x3, x1, x2
```
- Expected:
  - `x3 = 50`

### Missing or weak coverage: `slt_true`
- Goal: Verify SLT when rs1 < rs2.
- Program:
```asm
addi x1, x0, 5
addi x2, x0, 10
slt x3, x1, x2
```
- Expected:
  - `x3 = 1`

### Missing or weak coverage: `slt_false`
- Goal: Verify SLT when rs1 >= rs2.
- Program:
```asm
addi x1, x0, 10
addi x2, x0, 5
slt x3, x1, x2
```
- Expected:
  - `x3 = 0`

### Missing or weak coverage: `slt_signed`
- Goal: Verify signed SLT behavior with a negative operand.
- Program:
```asm
addi x1, x0, -1
addi x2, x0, 1
slt x3, x1, x2
```
- Expected:
  - `x3 = 1`

### Missing or weak coverage: `addi_positive`
- Goal: Verify ADDI with positive immediate.
- Program:
```asm
addi x1, x0, 42
```
- Expected:
  - `x1 = 42`

### Missing or weak coverage: `addi_negative`
- Goal: Verify ADDI with sign-extended negative immediate.
- Program:
```asm
addi x1, x0, -1
```
- Expected:
  - `x1 = 0xffffffff`

### Missing or weak coverage: `lw_sw`
- Goal: Verify SW followed by LW.
- Program:
```asm
addi x1, x0, 100
addi x2, x0, 42
sw x2, 0(x1)
lw x3, 0(x1)
```
- Expected:
  - `x3 = 42`

### Missing or weak coverage: `x0_write_protection`
- Goal: Verify attempted write to x0 is ignored.
- Program:
```asm
addi x0, x0, 123
addi x1, x0, 5
```
- Expected:
  - `x0 = 0`
  - `x1 = 5`

## Recommended Testbench Improvements

- Replace final print-only checks with strict `if (...) $fatal;` checks.
- Use `!==` instead of `!=` to catch X/Z values.
- Add separate tests for ADD, SUB, AND, OR, XOR, MUL, SLT, ADDI, LW, SW, reset, and x0 behavior.
- Add separate tests for ALU operations, memory operations, reset behavior, and x0 write protection.
- Add a helper task like `check_reg(reg_id, expected_value)`.
- Add VCD waveform dumping only when debugging or when CI fails.