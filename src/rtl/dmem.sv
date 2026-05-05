module dmem (
    input wire clk,
    input wire write_enable,
    input wire [31:0] address,
    input wire [31:0] write_data,
    output wire [31:0] read_data
);

    // 1024 x 32-bit words = 4096 bytes = 4 KiB RAM
    reg [31:0] ram [0:1023];

    wire unused_address_bits = |{address[31:12], address[1:0]};

    // Asynchronous read for simple single-cycle CPU behavior
    assign read_data = ram[address[11:2]];

    initial begin
        for (int i = 0; i < 1024; i++) begin
            ram[i] = 32'b0;
        end
    end

    always @(posedge clk) begin
        if (write_enable) begin
            ram[address[11:2]] <= write_data;
        end
    end

endmodule
