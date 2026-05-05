module regfile (
    input wire clk,
    input wire rst, // Added reset input
    input wire write_enable,
    input wire [4:0] rs1_add, // Source register 1
    input wire [4:0] rs2_add, // Source register 2
    input wire [4:0] rd_add,  // Destination register
    input wire [31:0] rd_data, // Data to write to the destination register
    output wire [31:0] rs1_data, // Data from source register 1
    output wire [31:0] rs2_data  // Data from source register 2
);

    reg[31:0] registers[31:0]; // 32 registers, each 32 bits wide

    //Reading (No clock needed for reading)
    assign rs1_data = (rs1_add == 5'd0) ? 32'd0 : registers[rs1_add]; // Register x0 is always 0
    assign rs2_data = (rs2_add == 5'd0) ? 32'd0 : registers[rs2_add]; // Register x0 is always 0

    //Writing (Synchronous with clock)
    always @(posedge clk or posedge rst) begin // Added reset to sensitivity list
        integer i; // Declare i here for the loop
        if (rst == 1'b1) begin // Active high reset
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0; // Reset all registers
            end
        end else if (write_enable == 1'b1 && rd_add != 5'd0) begin
            registers[rd_add] <= rd_data;
        end
    end

    // Assertion to ensure x0 is always zero
    `ifndef __ICARUS__
    `ifndef SYNTHESIS
    property p_x0_is_always_zero;
        @(posedge clk) (write_enable == 1'b1 && rd_add == 5'b00000) |-> (registers[0] == 32'b0);
    endproperty

    assert_x0_zero: assert property(p_x0_is_always_zero) 
        else $fatal(1, "Attempted to overwrite x0 with non-zero value");
    `endif
    `endif

endmodule
