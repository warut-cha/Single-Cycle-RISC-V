module pc(
    input wire clk, // Clock signal
    input wire rst, // Reset signal
    input wire [31:0] next_pc, // Next PC value to be loaded
    output reg [31:0] current_pc // Current PC value
);

    always@(posedge clk or posedge rst) begin
        if (rst == 1'b1) begin
            current_pc <= 32'b0; // Reset PC to 0
        end else begin
            current_pc <= next_pc; // Update PC with next value
        end
    end
    
endmodule