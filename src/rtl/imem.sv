module imem(
    input wire [31:0] address, //address from PC
    output wire [31:0] instr //32-bits
);

    reg [31:0] rom [0:1023];

`ifndef SYNTHESIS
    reg [1023:0] program_file;

    initial begin
        if (!$value$plusargs("PROGRAM=%s", program_file)) begin
            program_file = "src/txt/program.hex";
        end

        $display("Loading program: %s", program_file);
        $readmemh(program_file, rom);
    end
`else
    initial begin
        $readmemh("src/txt/program.hex", rom);
    end
`endif

    wire unused_address_bits = |{address[31:12], address[1:0]};

    assign instr = rom[address[11:2]];

endmodule
