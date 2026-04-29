module regfile (
    input wire clk,
    input wire write_enable,
    input wire [4:0] rs1_add, // Source register 1
    input wire [4:0] rs2_add, // Source register 2
    input wire [4:0] rd_add,  // Destination register
    input wire [31:0] rd_data, // Data to write to the destination register
    output wire [31:0] rs1_data, // Data from source register 1
    output wire [31:0] rs2_data  // Data from source register 2
);

    reg[31:0] registers[31:0]; // 32 registers, each 32 bits wide
    // Init all registers
    integer i;
    initial begin
        for (i = 0; i<32; i = i + 1) begin
            registers[i] = 32'd0;
        end
    end

    //Reading (No clock needed for reading)
    assign rs1_data = (rs1_add == 5'd0) ? 32'd0 : registers[rs1_add]; // Register x0 is always 0
    assign rs2_data = (rs2_add == 5'd0) ? 32'd0 : registers[rs2_add]; // Register x0 is always 0

    //Writing (Synchronous with clock)
    always @(posedge clk) begin
        //Only write IF the write Enable flag is turned on AND so we are not trying to overwrite x0
        if (write_enable == 1'b1 && rd_add != 5'd0) begin
            registers[rd_add] <= rd_data;
        end
    end
endmodule