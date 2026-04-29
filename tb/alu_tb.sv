`timescale 1ns/1ps

module alu_tb;

    // Inputs to the module are 'reg' so we can assign them values
    reg  [31:0] a_tb;
    reg  [31:0] b_tb;
    reg  [2:0]  control_tb;
    
    // Outputs from the module are 'wire'
    wire [31:0] result_tb;
    wire        zero_tb;

    alu dut (
        .a(a_tb),
        .b(b_tb),
        .alu_control(control_tb),
        .result(result_tb),
        .zero(zero_tb)
    );

    initial begin
        $dumpfile("build/alu_waves.vcd");
        $dumpvars(0, alu_tb);

        // Test case 1: ADD
        a_tb = 32'd10;
        b_tb = 32'd5;
        control_tb = 3'b000;
        #10;
        $display("ADD Test: %0d + %0d = %0d", a_tb, b_tb, result_tb);

        // Test case 2: SUB
        a_tb = 32'd20;
        b_tb = 32'd20;
        control_tb = 3'b001;
        #10;
        $display("SUB Test: %0d - %0d = %0d (Zero Flag is: %b)", a_tb, b_tb, result_tb, zero_tb);

        #10 $finish;
    end

endmodule