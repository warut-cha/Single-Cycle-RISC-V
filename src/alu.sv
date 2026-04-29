module alu (
    input  wire [31:0] a, // 32-bit a
    input  wire [31:0] b, // 32-bit b
    input  wire [2:0]  alu_control, // 3-bit control signal to select the operation
    output reg  [31:0] result, // 32-bit result of the ALU operation
    output wire        zero // Zero flag, set to 1 if result is zero
);

    always @(*) begin
        case (alu_control)
            3'b000: result = a + b; // ADD
            3'b001: result = a - b; // SUB
            3'b010: result = a & b; // AND
            3'b011: result = a | b; // OR
            default: result = 32'b0; // DEFAULT
        endcase
    end

    assign zero = (result == 32'b0);

endmodule