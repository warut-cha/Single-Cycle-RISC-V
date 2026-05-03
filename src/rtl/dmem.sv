module dmem (
    input wire clk,
    input wire write_enable,
    input wire [31:0] address,
    input wire [31:0] write_data,
    output wire [31:0] read_data
);

    reg [31:0] ram[0:1023]; // 1924 memory slots (4kb RAM)

    // same need 10 bits
    wire unused_address_bits = |{address[31:12], address[1:0]}; // Check if any of the upper bits are used
    assign read_data = ram[address[11:2]]; // Address is word-aligned, so we ignore the 2 least significant bits
    always @(posedge clk) begin
        if(write_enable == 1'b1) begin
            ram[address[11:2]] <= write_data;
        end
    end
endmodule
