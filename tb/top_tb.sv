`timescale 1ns/1ps

module top_tb;

    reg clk_tb;
    reg rst_tb;

    wire [31:0] instruction_tb;
    wire [6:0]  op_tb;
    wire [4:0]  rd_tb;
    wire [2:0]  funct3_tb;
    wire [6:0]  funct7_tb;
    wire [4:0]  rs1_tb;
    wire [4:0]  rs2_tb;
    wire [7:0]  led_out;

    top dut (
        .clk(clk_tb),
        .rst(rst_tb),
        .fct(instruction_tb),
        .opcode_out(op_tb),
        .rd_out(rd_tb),
        .funct3_out(funct3_tb),
        .funct7_out(funct7_tb),
        .rs1_out(rs1_tb),
        .rs2_out(rs2_tb),
        .led_out(led_out)
    );

    always begin
        #5 clk_tb = ~clk_tb;
    end

    initial begin
        $dumpfile("build/top_waves.vcd");
        $dumpvars(0, top_tb);

        clk_tb = 0;
        rst_tb = 1;

        $display("Booting");

        #10;
        rst_tb = 0;

        #250;

        $display("Cloud CI Verification");

        if (dut.regfile_instance.registers[0] !== 32'd0) begin
            $display("SIM FAIL: x0 was modified. x0 = %0d",
                     dut.regfile_instance.registers[0]);
            $fatal(1);
        end

        if (dut.regfile_instance.registers[3] !== 32'd42) begin
            $display("SIM FAIL: APB read expected x3 = 42, got %0d",
            dut.regfile_instance.registers[3]);
            $fatal(1);
        end else begin
            $display("APB read PASS: x3 = %0d",
            dut.regfile_instance.registers[3]);
        end

        if (led_out !== 8'd42) begin
            $display("SIM FAIL: APB write expected led_out = 42, got %0d", led_out);
            $fatal(1);
        end else begin
            $display("APB write PASS: led_out = %0d", led_out);
        end
        $display("SIM PASS: led_out = %0d", led_out);
        $display("Shutting down");
        $finish;
    end

    initial begin
        $monitor(
            "Time: %0t | PC: %h | Inst: %h | Op: %h | x0: %0d | x1: %0d | x2: %0d | x3: %0d | led_out: %0d",
            $time,
            dut.current_pc_wire,
            instruction_tb,
            op_tb,
            dut.regfile_instance.registers[0],
            dut.regfile_instance.registers[1],
            dut.regfile_instance.registers[2],
            dut.regfile_instance.registers[3],
            led_out
        );
    end

endmodule