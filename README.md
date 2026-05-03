# Single-Cycle RISC-V CPU Architecture (OUT OF DATE since 03/05-2026)

## Roadmap & Future Work

This CPU is in active development. Current work-in-progress features and planned architectural upgrades include:

* **Instruction Set Expansion:** Expanding the supported RV32I instruction set to include logical operations (`and`, `or`), subtraction (`sub`), and unconditional jumps (`jal`, `jalr`). This involves extending the opcode decoding logic and ALU control MUXes within the `top.sv` control unit.
* **Physical Silicon Synthesis (FPGA):** Synthesizing the SystemVerilog RTL onto a physical FPGA development board to demonstrate real-world hardware execution, utilizing open-source toolchains like Yosys and NextPNR.
* **Pipelined Datapath:** Upgrading the single-cycle architecture to a full 5-stage pipeline, requiring the implementation of pipeline registers, a hazard detection unit, and data forwarding logic to increase the maximum clock frequency.


A fully functional, single-cycle RISC-V (RV32I) microprocessor built from scratch in SystemVerilog.

This project implements the core 32-bit integer instruction set (RV32I) using a custom 5-stage datapath compressed into a single clock cycle. It is fully Turing-complete, capable of executing arithmetic, memory load/store operations, and conditional branch loops. The hardware is verified using a self-checking testbench and an automated cloud CI/CD pipeline.

---

## Hardware Architecture

This CPU implements a classic Von Neumann architecture with isolated instruction and data memory spaces. The datapath executes the standard 5 stag RISC-V lifecycle in a single clock tick:
1. **Instruction Fetch (IF):** The program counter(PC) addresses the instruction ROM to fetch the 32 bit machine code.
2. **Instruction Decode (ID):** The control unit (Glue Logic) slices the instruction into opcodes, extracts register addresses (`rs1`, `rs2`, `rd`), and uses an Immediate Generator to construct sign-extended values for I-Type, S-Type, and B-Type instructions.
3. **Execute (EX):** A arithmetic logic unit (ALU) performs 2's complement math, calculates memory offset addresses, and evaluates branch equality (`Zero Flag`).
4. **Memory (MEM):** Synchronous data RAM is accessed via load (`lw`) and store (`sw`) instructions, gated by highly specific write enable (`write_enable`) control signals to prevent data corruption.
5. **Writeback (WB):** A writeback MUX determines whether ALU execution results or cata RAM read outputs are routed back to be saved in the register file.

---

## Module Breakdown & Directory Structure

The silicon design is highly modular, mapped exactly to standard hardware components:

* `src/top.sv` - **The Motherboard / Control Unit:** Instantiates all sub-modules and routes the primary data buses and control logic (MUXes, Write Enables, ALU Control).
* `src/pc.sv` - **Program Counter:** Synchronous register holding the current execution address.
* `src/imem.sv` - **Instruction Memory:** Read-only memory (ROM) containing the compiled hexadecimal `.hex` program.
* `src/decoder.sv` - **Instruction Decoder:** Combinational logic translating 32-bit instructions into functional hardware signals.
* `src/regfile.sv` - **Register File:** 32x32-bit ultra-fast local scratchpad memory with synchronous write and asynchronous read ports.
* `src/alu.sv` - **Arithmetic Logic Unit:** The mathematical core handling addition, subtraction, and boolean flags.
* `src/dmem.sv` - **Data Memory:** 4KB synchronous random access memory (RAM) for dataset storage.
* `tb/top_tb.sv` - **Testbench:** The verification environment that drives the clock, loads instructions, and automatically asserts success/failure conditions.

---

## Supported Instruction Set (RV32I)

The CPU currently supports the critical subset of the RISC-V Base Integer architecture:
* **Arithmetic (I-Type/R-Type):** `add`, `addi`
* **Memory (I-Type/S-Type):** `lw` (Load Word), `sw` (Store Word)
* **Control Flow (B-Type):** `beq` (Branch if Equal)

---

## Verification & Cloud Automation (CI/CD)

Hardware verification is notoriously difficult. To prevent regressions, this repository utilizes **GitHub Actions** for Continuous Integration. 

On every push to the `main` branch:
1. An **Ubuntu Linux** cloud server provisions automatically.
2. The `iverilog` (Icarus Verilog) toolchain is installed.
3. The SystemVerilog RTL datapath is compiled.
4. A self-checking testbench executes, proving register states and memory operations natively in the cloud.

---

Quick Start (Local Simulation)

To compile and run the silicon simulation on your own Linux machine, ensure you have Icarus Verilog installed:
```bash
# 1. Install dependencies (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install iverilog

# 2. Compile the CPU
iverilog -o build/top_sim src/pc.sv src/imem.sv src/decoder.sv src/regfile.sv src/alu.sv src/dmem.sv src/top.sv tb/top_tb.sv

# 3. Execute the simulation
vvp build/top_sim
```
