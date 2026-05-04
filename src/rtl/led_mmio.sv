module led_mmio (
    input wire clk,
    input wire rst,
    input wire write_enable,
    input wire [31:0] address,
    input wire [31:0] write_data,
    output reg [7:0] led_out
);

    localparam LED_ADDR = 32'h0000_0100;
    wire unused_write_data_bits = |write_data[31:8];
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            led_out <= 8'b0;
        end else if (write_enable && address == LED_ADDR) begin
            led_out <= write_data[7:0];
        end
    end

endmodule
