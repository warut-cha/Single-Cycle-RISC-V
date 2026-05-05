`timescale 1ns/1ps

module alu_tb;

    reg  [31:0] a_tb;
    reg  [31:0] b_tb;
    reg  [3:0]  control_tb;

    wire [31:0] result_tb;
    wire        zero_tb;

    alu dut (
        .a(a_tb),
        .b(b_tb),
        .alu_control(control_tb),
        .result(result_tb),
        .zero(zero_tb)
    );

    task check;
        input [3:0] control;
        input [31:0] a;
        input [31:0] b;
        input [31:0] expected;
        input [127:0] test_name;
        begin
            a_tb = a;
            b_tb = b;
            control_tb = control;
            #10;

            if (result_tb !== expected) begin
                $display("ALU FAIL: %0s expected %h, got %h",
                         test_name, expected, result_tb);
                $fatal(1);
            end else begin
                $display("ALU PASS: %0s result = %h",
                         test_name, result_tb);
            end
        end
    endtask

    initial begin
        $dumpfile("build/alu_waves.vcd");
        $dumpvars(0, alu_tb);

        check(4'b0000, 32'd10, 32'd5,  32'd15, "ADD");
        check(4'b0001, 32'd20, 32'd5,  32'd15, "SUB");
        check(4'b0010, 32'h0000_000a, 32'h0000_000c, 32'h0000_0008, "AND");
        check(4'b0011, 32'h0000_000a, 32'h0000_000c, 32'h0000_000e, "OR");
        check(4'b0100, 32'h0000_000a, 32'h0000_000c, 32'h0000_0006, "XOR");
        check(4'b0101, 32'd5,  32'd10, 32'd50, "MUL");
        check(4'b0110, 32'd5,  32'd10, 32'd1,  "SLT true");
        check(4'b0110, 32'd10, 32'd5,  32'd0,  "SLT false");

        // Zero flag check
        check(4'b0001, 32'd20, 32'd20, 32'd0, "SUB zero");

        if (zero_tb !== 1'b1) begin
            $display("ALU FAIL: zero flag expected 1, got %b", zero_tb);
            $fatal(1);
        end else begin
            $display("ALU PASS: zero flag");
        end

        $display("ALU UNIT TEST PASS");
        $finish;
    end

endmodule