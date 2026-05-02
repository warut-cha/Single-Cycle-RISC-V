`timescale 1ns/1ps

module top_tb;

    reg clk_tb;
    reg rst_tb;
    wire [31:0] instruction_tb;
    wire [6:0] op_tb;
    wire [4:0] rd_tb;
    wire [2:0] funct3_tb;
    wire [4:0] rs1_tb;
    wire [4:0] rs2_tb;

    //Top-lvl motherboard
    top dut(
        .clk(clk_tb),
        .rst(rst_tb),
        .fct(instruction_tb),
        .opcode_out(op_tb),
        .rd_out(rd_tb),
        .funct3_out(funct3_tb),
        .rs1_out(rs1_tb),
        .rs2_out(rs2_tb)
    );

    always begin
        #5 clk_tb = ~clk_tb; // Toggle clock every 5ns
    end

    initial begin
        $dumpfile("build/top_waves.vcd");
        $dumpvars(0, top_tb);

        //Intialize reset
        clk_tb = 0;
        rst_tb = 1; // Assert reset
        $display("Booting");
        #10; // Wait for 10ns

        //Release reset and let the CPU run
        rst_tb = 0; // Deassert reset

        #250; //wait 3 clock cycles (10ns each)

        $display("Cloud CI Verification");
        if (dut.regfile_instance.registers[3] !== 32'd0) begin
            $display("Executed math/mem. x3 = %0d", dut.regfile_instance.registers[3]);
        end else begin
            $display("Error: x3 is 0. The data path failed.");
            $fatal(1);
        end

        $display("Shutting down");
        $finish; // End simulation
    end

    initial begin
        $monitor("Time: %0t | PC: %h | Instruction: %h | Opcode: %h | RD: %h | Funct3: %h | RS1: %h | RS2: %h", $time, dut.current_pc_wire, instruction_tb, op_tb, rd_tb, funct3_tb, rs1_tb, rs2_tb);
    end

    initial begin
        $monitor("Time: %0t | PC: %h | Inst: %h | Op: %h | x1: %0d | x2: %0d | x3: %0d",
                $time,
                dut.current_pc_wire,
                instruction_tb,
                op_tb,
                dut.regfile_instance.registers[1],
                dut.regfile_instance.registers[2],
                dut.regfile_instance.registers[3]
        );
    end
endmodule