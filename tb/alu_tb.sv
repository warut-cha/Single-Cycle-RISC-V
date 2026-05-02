`timescale 1ns/1ps

module alu_tb;

    // Inputs to the module are 'reg' so we can assign them values
    reg  [31:0] a_tb;
    reg  [31:0] b_tb;
    reg  [3:0]  control_tb;
    
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
        control_tb = 4'b0000;
        #10;
        $display("ADD Test: %0d + %0d = %0d", a_tb, b_tb, result_tb);

        // Test case 2: SUB
        a_tb = 32'd20;
        b_tb = 32'd20;
        control_tb = 4'b0001;
        #10;
        $display("SUB Test: %0d - %0d = %0d (Zero Flag is: %b)", a_tb, b_tb, result_tb, zero_tb);

        // Test case 3: MUL
        a_tb = 32'd5;
        b_tb = 32'd10;
        control_tb = 4'b0101; //MUL
        #10;
        $display("MUL Test: %0d * %0d = %0d", a_tb, b_tb, result_tb);

        // Test case 4: SLT
        a_tb = 32'd5;
        b_tb = 32'd10;
        control_tb = 4'b0110; //SLT
        #10;
        $display("SLT Test: %0d < %0d = %0d", a_tb, b_tb, result_tb);
        
         // Test case 5: AND
        a_tb = 32'b1010; // 10 in binary
        b_tb = 32'b1100; // 12 in binary
        control_tb = 4'b1000; //AND
        #10;
        $display("AND Test: %0d & %0d = %0d", a_tb, b_tb, result_tb);

        // Test case 6: OR
        a_tb = 32'b1010; // 10 in binary
        b_tb = 32'b1100; // 12 in binary
        control_tb = 4'b1001; //OR
        #10;
        $display("OR Test: %0d | %0d = %0d", a_tb, b_tb, result_tb);

        // Test case 7: XOR
        a_tb = 32'b1010; // 10 in binary
        b_tb = 32'b1100; // 12 in binary
        control_tb = 4'b1010; //XOR
        #10;
        $display("XOR Test: %0d ^ %0d = %0d", a_tb, b_tb, result_tb);
        
        #10 $finish;
    end

endmodule