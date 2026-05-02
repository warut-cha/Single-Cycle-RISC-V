module alu (
    input  wire [31:0] a, // 32-bit a
    input  wire [31:0] b, // 32-bit b
    input  wire [3:0]  alu_control, // 4-bit control signal to select the operation
    output reg  [31:0] result, // 32-bit result of the ALU operation
    output wire        zero // Zero flag, set to 1 if result is zero
);

    always @(*) begin
        case (alu_control)
            4'b0000: result = a + b; // ADD
            4'b0001: result = a - b; // SUB
            4'b0010: result = a & b; // AND
            4'b0011: result = a | b; // OR
            4'b0100: result = a ^ b; // XOR
            4'b0101: result = a * b; // MUL
            4'b0110: result = (a < b) ? 32'b1 : 32'b0; // SLT (Set Less Than)
            default: result = 32'b0; // DEFAULT
        endcase
    end

    assign zero = (result == 32'b0);

endmodule