module imem(
    input wire [31:0] address, //address from pc
    output wire [31:0] instr //32-bit instruction
);

    reg[31:0] rom[0:1023]; //1024 words of 32-bit instruction memory

    initial begin
        //read text file and load it into array automatically
        $readmemh("src/txt/program.hex", rom);
    end

    wire unused_address_bits = |{address[31:12], address[1:0]}; // Check if any of the upper bits are used
    //1024 needs 10 bits
    assign instr = rom[address[11:2]]; //word aligned, so ignore the last 2 bits

endmodule
