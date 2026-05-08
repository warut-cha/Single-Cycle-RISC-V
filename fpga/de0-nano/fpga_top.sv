module fpga_top (
    input  wire        CLOCK_50,
    input  wire [1:0]  KEY,
    output wire [7:0]  LED
);

    wire rst;

    wire [31:0] fct_unused;
    wire [6:0]  opcode_unused;
    wire [4:0]  rd_unused;
    wire [2:0]  funct3_unused;
    wire [6:0]  funct7_unused;
    wire [4:0]  rs1_unused;
    wire [4:0]  rs2_unused;

    //Press [0] to reset
    assign rst = ~KEY[0];

    top cpu_instance (
        .clk(CLOCK_50),
        .rst(rst),
        .fct(fct_unused),
        .opcode_out(opcode_unused),
        .rd_out(rd_unused),
        .funct3_out(funct3_unused),
        .funct7_out(funct7_unused),
        .rs1_out(rs1_unused),
        .rs2_out(rs2_unused),
        .led_out(LED)
    );

endmodule