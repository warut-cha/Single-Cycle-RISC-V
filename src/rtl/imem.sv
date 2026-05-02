module imem(
    input wire [31:0] address, //address from pc
    output wire [31:0] instr //32-bit instruction
);

    reg[31:00] rom[0:1023]; //1024 words of 32-bit instruction memory

    initial begin
        //read text file and load it into array automatically
        $readmemh("src/txt/program.hex", rom);
    end

    assign instr = rom[address[31:2]]; //word aligned, so ignore the last 2 bits

endmodule