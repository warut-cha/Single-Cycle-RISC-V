module top (
    input wire clk,
    input wire rst,
    output wire [31:0] fct, //fetch instruction
    output wire [6:0] opcode_out,
    output wire [4:0] rd_out,
    output wire [2:0] funct3_out,
    output wire [6:0] funct7_out,
    output wire [4:0] rs1_out,
    output wire [4:0] rs2_out
);

    // Declare wires to connect our chips
    wire [31:0] current_pc_wire;
    wire [31:0] next_pc_wire;
    wire is_load;
    wire is_store;
    wire [31:0] imm_i = {{20{fct[31]}}, fct[31:20]}; // Immediate for I-type instructions (sign-extended)
    wire [31:0] imm_s = {{20{fct[31]}}, fct[31:25], fct[11:7]}; // Immediate for S-type instructions (sign-extended)
    wire [31:0] imm_ext; // Select the correct immediate based on instruction type
    wire [31:0] imm_b;
    wire use_imm;
    wire reg_write_enable;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] alu_results; // wire comes from the ALU at the bottom
    wire [31:0] alu_b_input;
    wire zero_flag;
    wire ram_write_enable;
    wire [31:0] ram_read_data;
    wire [31:0] write_back_data;
    wire is_branch = (opcode_out == 7'h63); // beq, bne, etc.
    wire take_branch;

    logic [3:0] alu_control;

    // PC Adder
    assign is_load = (opcode_out == 7'h03); //lw
    assign is_store = (opcode_out == 7'h23); //sw
    assign imm_ext = (is_store) ? imm_s : imm_i; // Select the correct immediate based on instruction type
    assign use_imm = (opcode_out == 7'h13)||is_load||is_store; // Use immediate for I-type instructions and load/store instructions
    assign reg_write_enable = (opcode_out == 7'h13) || (opcode_out == 7'h33) || is_load; // Enable register write for R-type and I-type instructions, and load instructions
    assign alu_b_input = (use_imm) ? imm_ext : rs2_data; // Select between immediate value and register data for ALU input
    assign write_back_data = (is_load) ? ram_read_data : alu_results; // For load instructions, we want to write back the data read from RAM, otherwise we write back the ALU results
    assign imm_b = {{20{fct[31]}}, fct[7], fct[30:25], fct[11:8], 1'b0}; // Immediate for B-type instructions (sign-extended)
    assign take_branch = is_branch && zero_flag; // For simplicity, we only handle beq (branch if equal) here. 
    assign next_pc_wire = (take_branch) ? (current_pc_wire + imm_b) : (current_pc_wire + 32'd4);
    always@(posedge clk or posedge rst) begin
        if (is_load||is_store) begin
            alu_control = 4'b0000; // ADD
        end else if (opcode_out == 7'h33) begin //R-instruction
            if (funct3_out == 3'b00 && funct7_out == 7'b0000001)
                alu_control = 4'b0101; // MUL
            else if (funct3_out == 3'b00 && funct7_out == 7'b0000000)
                alu_control = 4'b0001; // SUB
            else if (funct3_out == 3'b010)
                alu_control = 4'b0110; // SLT
            else
                alu_control = {1'b0, funct3_out}; // AND, OR, XOR
        end else begin
            alu_control = {1'b0, funct3_out}; // For I-type instructions,(e.g., ADDI, ANDI, ORI, etc.)
        end
    end
    // Instantiate the PC
    pc pc_instance (
        .clk(clk),
        .rst(rst),
        .next_pc(next_pc_wire), // wire coming from adder
        .current_pc(current_pc_wire) // wire going to mem
    );

    // Instantiate the Instruction Memory
    imem imem_instance (
        .address(current_pc_wire), // wire coming from pc
        .instr(fct) // wire going to output
    );

    decoder decoder_instance (
        .instruction(fct), // wire coming from imem
        .opcode(opcode_out), // wire going to output
        .rd(rd_out), // wire going to output
        .funct3(funct3_out), // wire going to output
        .rs1(rs1_out), // wire going to output
        .rs2(rs2_out), // wire going to output
        .funct7(funct7_out) // wire going to output
    );

    regfile regfile_instance (
        .clk(clk),
        .write_enable(reg_write_enable), // wire coming from control logic (not implemented yet)
        .rs1_add(rs1_out), // wire coming from decoder
        .rs2_add(rs2_out), // wire coming from decoder
        .rd_add(rd_out), // wire coming from decoder
        .rd_data(write_back_data), // wire coming from ALU (not implemented yet)
        .rs1_data(rs1_data), // wire going to ALU (not implemented yet)
        .rs2_data(rs2_data) // wire going to ALU (not implemented yet)
    );

    alu alu_instance(
        .a(rs1_data),
        .b(alu_b_input),
        .alu_control(alu_control),
        .result(alu_results),
        .zero(zero_flag)
    );

    dmem dmem_instance (
        .clk(clk),
        .write_enable(ram_write_enable), // wire coming from control logic (not implemented yet)
        .address(alu_results), // wire coming from ALU (not implemented yet)
        .write_data(rs2_data), // wire coming from regfile (not implemented yet)
        .read_data(ram_read_data) // wire coming from dmem (not implemented yet)
    );

endmodule

