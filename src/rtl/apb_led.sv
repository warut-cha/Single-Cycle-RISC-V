module apb_led(
    input wire pclk,
    input wire presetn,
    input wire psel,
    input wire penable,
    input wire pwrite,
    input wire [31:0] paddress,
    input wire [31:0] pwrite_data,
    output reg [31:0] pread_data,
    output wire pready,
    output wire pslverr,
    output reg [7:0] led_out
);

    localparam LED_ADDR = 32'h000_0100;
    wire apb_write;
    wire apb_read;
    wire led_access;

    assign apb_write  = psel && penable && pwrite;
    assign apb_read   = psel && penable && !pwrite;
    assign led_access = (paddress == LED_ADDR);
    assign pready = 1'b1;
    assign pslverr = 1'b0;

    wire unused_pwdata_bits = |pwrite_data[31:8];

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            led_out <= 8'b0;
        end else if (apb_write && led_access) begin
            led_out <= pwrite_data[7:0];
        end
    end

    always @(*) begin
        if (apb_read && led_access) begin
            pread_data = {24'b0, led_out};
        end else begin 
            pread_data = 32'b0;
        end
    end
endmodule
