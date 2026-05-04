# RTL Code Review Report

## Rule-Based Style Findings

- No simple rule-based RTL style findings detected.

## Recommended SystemVerilog Assertions

Add these to a simulation-only assertion file such as `tb/assertions.sv`.

```systemverilog
    // PC should always be word-aligned.
    assert property (@(posedge clk) disable iff (rst)
        pc_out[1:0] == 2'b00
    );

    // Register x0 must remain zero.
    assert property (@(posedge clk) disable iff (rst)
        dut.regfile_instance.registers[0] == 32'b0
    );

    // Data memory write enable should only be active for store instructions.
    assert property (@(posedge clk) disable iff (rst)
        ram_write_enable |-> opcode_out == 7'b0100011
    );

    // Register writeback data should not be unknown when write enable is active.
    assert property (@(posedge clk) disable iff (rst)
        reg_write_enable |-> !$isunknown(write_data)
    );
    ```

## Manual Review Checklist

- Confirm `ADD`, `SUB`, and `MUL` decode use correct RISC-V `funct7` values.
- Confirm memories use `address[11:2]` for a 1024-word word-addressed memory.
- Confirm all combinational decode blocks have default assignments.
- Confirm all sequential logic uses non-blocking assignments.
- Confirm `x0` writes are ignored in the register file.
- Confirm reset behavior is documented and tested.