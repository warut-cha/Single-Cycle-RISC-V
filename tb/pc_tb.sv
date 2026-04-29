`timescale 1ns/1ps

module pc_tb;

    reg clk_tb;
    reg rst_tb;
    reg [31:0] next_pc_tb;
    wire [31:0] current_pc_tb;

    // Instantiate the pc module
    pc dut (
        .clk(clk_tb),
        .rst(rst_tb),
        .next_pc(next_pc_tb),
        .current_pc(current_pc_tb)
    );

    always begin
        #5 clk_tb = ~clk_tb;
    end

    initial begin
        $dumpfile("build/pc_waves.vcd");
        $dumpvars(0, pc_tb);

        clk_tb = 0;
        rst_tb = 1;
        next_pc_tb = 32'd0;

        $display("Holding Reset");
        #10;

        //Release Reset and set the next intruction to address 4
        rst_tb = 0;
        next_pc_tb = 32'd4; 
        $display("Time 10:Releasing Reset, setting next_pc to 4");
        #10;

        // Set the next instruction to address 8
        next_pc_tb = 32'd8;
        $display("Time 20: Setting next_pc to 8");
        #10;

        // Set the next instruction to address 12
        next_pc_tb = 32'd12;
        $display("Time 30: Setting next_pc to 12");
        #10;

        $finish;
    end

    initial begin
        $monitor("Time: %0t | rst: %b | next_pc: %d | current_pc: %d", $time, rst_tb, next_pc_tb, current_pc_tb);
    end

endmodule