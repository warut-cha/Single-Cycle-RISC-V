module top (
    input wire clk,
    input wire rst,
    output wire [31:0] fct, //fetch instruction
    output wire [6:0] opcode_out,
    output wire [4:0] rd_out,
    output wire [2:0] funct3_out,
    output wire [6:0] funct7_out,
    output wire [4:0] rs1_out,
    output wire [4:0] rs2_out,
    output wire [7:0] led_out
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
    wire [31:0] ram_read_data;
    wire [31:0] write_back_data;
    wire take_branch;
    wire is_led_access;
    wire dmem_write_enable;
    wire ram_write_enable;

    wire apb_psel;
    wire apb_penable;
    wire apb_pwrite;
    wire [31:0] apb_paddr;
    wire [31:0] apb_pwrite_data;
    wire [31:0] apb_pread_data;
    wire apb_pready;
    wire apb_pslverr;
    wire unused_apb_outputs = |{apb_pread_data, apb_pready, apb_pslverr};
    wire is_branch;
    wire is_jal;
    wire is_jalr;
    wire is_beq;
    wire is_bne;
    wire [31:0] imm_j;
    wire [31:0] jalr_target;
    wire [31:0] pc_plus_4;
    
    reg [3:0] alu_control; // Changed from logic to reg for broader Verilog compatibility

    assign is_load = (opcode_out == 7'h03); //lw
    assign is_store = (opcode_out == 7'h23); //sw
    assign imm_j = {{12{fct[31]}}, fct[19:12], fct[20], fct[30:21], 1'b0};
    assign imm_ext = (is_store) ? imm_s : imm_i; // Select the correct immediate based on instruction type
    assign use_imm = (opcode_out == 7'h13)||is_load||is_store||is_jalr; // Use immediate for I-type instructions and load/store instructions
    assign reg_write_enable = (opcode_out == 7'h13) || (opcode_out == 7'h33) || is_load || is_jal ||is_jalr; // Enable register write for R-type and I-type instructions, and load instructions
    assign alu_b_input = (use_imm) ? imm_ext : rs2_data; // Select between immediate value and register data for ALU input
    assign write_back_data = (is_jal || is_jalr) ? pc_plus_4 : (is_load) ? ((is_led_access) ? apb_pread_data : ram_read_data) : alu_results;
    assign imm_b = {{20{fct[31]}}, fct[7], fct[30:25], fct[11:8], 1'b0}; // Immediate for B-type instructions (sign-extended)
    assign pc_plus_4 = current_pc_wire + 32'd4;
    assign take_branch = (is_beq && zero_flag) || (is_bne && !zero_flag);
    assign jalr_target = (rs1_data + imm_i) & 32'hffff_fffe;
    assign next_pc_wire = is_jal ? (current_pc_wire + imm_j) :
                          is_jalr ? jalr_target : 
                          take_branch ? (current_pc_wire + imm_b) : 
                          pc_plus_4;
    assign ram_write_enable =is_store;

    assign is_led_access = (alu_results == 32'h0000_0100);
    assign dmem_write_enable = ram_write_enable && !is_led_access;

    assign apb_psel = is_led_access && (is_store || is_load);
    assign apb_penable = is_led_access && (is_store || is_load);
    assign apb_pwrite = is_store;
    assign apb_paddr = alu_results;
    assign apb_pwrite_data = rs2_data;

    assign is_branch = (opcode_out == 7'h63);
    assign is_jal = (opcode_out == 7'h6f);
    assign is_jalr = (opcode_out == 7'h67);

    assign is_beq = is_branch && (funct3_out == 3'b000);
    assign is_bne = is_branch && (funct3_out == 3'b001);

    always @(*) begin
        alu_control = 4'b0000; // Default to ADD

        if (is_load || is_store || is_jalr) begin
            alu_control = 4'b0000; // ADD for address calculation (LW, SW, JALR)
        end else if (is_branch) begin
            alu_control = 4'b0001; // SUB for branch comparison (BEQ, BNE)
        end else if (opcode_out == 7'h33) begin // R-type instructions
            if (funct3_out == 3'b000 && funct7_out == 7'b0000001)
                alu_control = 4'b0101; // MUL
            else if (funct3_out == 3'b000 && funct7_out == 7'b0100000)
                alu_control = 4'b0001; // SUB
            else if (funct3_out == 3'b000 && funct7_out == 7'b0000000)
                alu_control = 4'b0000; // ADD
            else if (funct3_out == 3'b111)
                alu_control = 4'b0010; // AND
            else if (funct3_out == 3'b110)
                alu_control = 4'b0011; // OR
            else if (funct3_out == 3'b100)
                alu_control = 4'b0100; // XOR
            else if (funct3_out == 3'b010)
                alu_control = 4'b0110; // SLT
            else
                alu_control = 4'b0000; // Default for other R-type
        end else if (opcode_out == 7'h13) begin // I-type instructions (ADDI, ANDI, ORI, XORI, SLTI)
            if (funct3_out == 3'b000)
                alu_control = 4'b0000; // ADDI
            else if (funct3_out == 3'b111)
                alu_control = 4'b0010; // ANDI
            else if (funct3_out == 3'b110)
                alu_control = 4'b0011; // ORI
            else if (funct3_out == 3'b100)
                alu_control = 4'b0100; // XORI
            else if (funct3_out == 3'b010)
                alu_control = 4'b0110; // SLTI
            else
                alu_control = 4'b1111; // For SLLI, SRLI, SRAI (not implemented in ALU), will result in 0
        end else begin
            alu_control = 4'b0000; // Default for other opcodes (e.g., JAL, LUI, AUIPC)
        }
    end
    // Instantiate the PC
    pc pc_instance (
        .clk(clk),
        .rst(rst), // Reset PC to 0
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
        .rst(rst), // Added reset connection
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
        .rst(rst), // Connect rst
        .write_enable(dmem_write_enable), // wire coming from control logic (not implemented yet)
        .address(alu_results), // wire coming from ALU (not implemented yet)
        .write_data(rs2_data), // wire coming from regfile (not implemented yet)
        .read_data(ram_read_data) // wire coming from dmem (not implemented yet)
    );

    apb_led apb_led_instance (
        .pclk(clk),
        .presetn(~rst),
        .psel(apb_psel),
        .penable(apb_penable),
        .pwrite(apb_pwrite),
        .paddress(apb_paddr),
        .pwrite_data(apb_pwrite_data),
        .pread_data(apb_pread_data),
        .pready(apb_pready),
        .pslverr(apb_pslverr)
    );

endmodule
