`timescale 1ns/1ps

module top_tb;

    reg clk_tb;
    reg rst_tb;

    integer test_id;

    wire [31:0] instruction_tb;
    wire [6:0]  opcode_out_tb;
    wire [4:0]  rd_tb;
    wire [2:0]  funct3_tb;
    wire [6:0]  funct7_tb;
    wire [4:0]  rs1_tb;
    wire [4:0]  rs2_tb;
    wire [7:0]  led_out;

    top dut (
        .clk(clk_tb),
        .rst(rst_tb),
        .fct(instruction_tb),
        .opcode_out(opcode_out_tb),
        .rd_out(rd_tb),
        .funct3_out(funct3_tb),
        .funct7_out(funct7_tb),
        .rs1_out(rs1_tb),
        .rs2_out(rs2_tb),
        .led_out(led_out)
    );

    always begin
        #5 clk_tb = ~clk_tb;
    end

    initial begin
        $dumpfile("build/top_waves.vcd");
        $dumpvars(0, top_tb);

        if (!$value$plusargs("TEST_ID=%d", test_id)) begin
            test_id = 0;
        end

        clk_tb = 0;
        rst_tb = 1;

        $display("Booting");
        $display("Running TEST_ID: %0d", test_id);

        #10;
        rst_tb = 0;

        #180;

        $display("Cloud CI Verification");

        if (dut.regfile_instance.registers[0] !== 32'd0) begin
            $display("SIM FAIL: x0 was modified. x0 = %0d",
                     dut.regfile_instance.registers[0]);
            $fatal(1);
        end

        case (test_id)

            1: begin
                if (dut.regfile_instance.registers[1] !== 32'd5) begin
                    $display("SIM FAIL: addi x1 expected 5, got %0d",
                            dut.regfile_instance.registers[1]);
                    $fatal(1);
                end

                if (dut.regfile_instance.registers[2] !== 32'd10) begin
                    $display("SIM FAIL: addi x2 expected 10, got %0d",
                            dut.regfile_instance.registers[2]);
                    $fatal(1);
                end

                if (dut.regfile_instance.registers[3] !== 32'd9) begin
                    $display("SIM FAIL: addi x3 expected 9, got %0d",
                            dut.regfile_instance.registers[3]);
                    $fatal(1);
                end

                if (dut.regfile_instance.registers[4] !== 32'd10) begin
                    $display("SIM FAIL: addi x4 expected 10, got %0d",
                            dut.regfile_instance.registers[4]);
                    $fatal(1);
                end

                $display("RISCV-TEST PASS: addi");
            end

            2: begin
                if (dut.regfile_instance.registers[3] !== 32'd15) begin
                    $display("SIM FAIL: ADD failed. x3 expected 15, got %0d",
                             dut.regfile_instance.registers[3]);
                    $fatal(1);
                end

                if (dut.regfile_instance.registers[4] !== 32'hffff_fffb) begin
                    $display("SIM FAIL: SUB failed. x4 expected fffffffb, got %h",
                             dut.regfile_instance.registers[4]);
                    $fatal(1);
                end

                if (dut.regfile_instance.registers[5] !== 32'd25) begin
                    $display("SIM FAIL: ADD dependency failed. x5 expected 25, got %0d",
                             dut.regfile_instance.registers[5]);
                    $fatal(1);
                end

                $display("RISCV-TEST PASS: add_sub");
            end

            3: begin
                if (dut.regfile_instance.registers[3] !== 32'h0000_0003) begin
                    $display("SIM FAIL: AND failed. x3 expected 3, got %h",
                            dut.regfile_instance.registers[3]);
                    $fatal(1);
                end

                if (dut.regfile_instance.registers[4] !== 32'h0000_003f) begin
                    $display("SIM FAIL: OR failed. x4 expected 3f, got %h",
                            dut.regfile_instance.registers[4]);
                    $fatal(1);
                end

                if (dut.regfile_instance.registers[5] !== 32'h0000_003c) begin
                    $display("SIM FAIL: XOR failed. x5 expected 3c, got %h",
                            dut.regfile_instance.registers[5]);
                    $fatal(1);
                end

                $display("RISCV-TEST PASS: logic");
            end

            4: begin
                if (dut.regfile_instance.registers[3] !== 32'd1) begin
                    $display("SIM FAIL: SLT failed. x3 expected 1, got %0d",
                             dut.regfile_instance.registers[3]);
                    $fatal(1);
                end

                if (dut.regfile_instance.registers[4] !== 32'd0) begin
                    $display("SIM FAIL: SLT failed. x4 expected 0, got %0d",
                             dut.regfile_instance.registers[4]);
                    $fatal(1);
                end

                $display("RISCV-TEST PASS: slt");
            end

            5: begin
                if (dut.regfile_instance.registers[3] !== 32'd123) begin
                    $display("SIM FAIL: LW/SW failed. x3 expected 123, got %0d",
                             dut.regfile_instance.registers[3]);
                    $fatal(1);
                end

                if (dut.regfile_instance.registers[5] !== 32'd456) begin
                    $display("SIM FAIL: LW/SW failed. x5 expected 456, got %0d",
                             dut.regfile_instance.registers[5]);
                    $fatal(1);
                end

                $display("RISCV-TEST PASS: load_store");
            end

            6: begin
                if (dut.regfile_instance.registers[3] !== 32'd42) begin
                    $display("SIM FAIL: BEQ failed. x3 expected 42, got %0d",
                             dut.regfile_instance.registers[3]);
                    $fatal(1);
                end

                if (dut.regfile_instance.registers[6] !== 32'd55) begin
                    $display("SIM FAIL: BNE failed. x6 expected 55, got %0d",
                             dut.regfile_instance.registers[6]);
                    $fatal(1);
                end

                if (dut.regfile_instance.registers[7] !== 32'h0000_002c) begin
                    $display("SIM FAIL: JAL link failed. x7 expected 0x2c, got %h",
                             dut.regfile_instance.registers[7]);
                    $fatal(1);
                end

                if (dut.regfile_instance.registers[8] !== 32'd66) begin
                    $display("SIM FAIL: JAL target failed. x8 expected 66, got %0d",
                             dut.regfile_instance.registers[8]);
                    $fatal(1);
                end

                if (dut.regfile_instance.registers[10] !== 32'h0000_003c) begin
                    $display("SIM FAIL: JALR link failed. x10 expected 0x3c, got %h",
                             dut.regfile_instance.registers[10]);
                    $fatal(1);
                end

                if (dut.regfile_instance.registers[11] !== 32'd77) begin
                    $display("SIM FAIL: JALR target failed. x11 expected 77, got %0d",
                             dut.regfile_instance.registers[11]);
                    $fatal(1);
                end

                $display("RISCV-TEST PASS: branch_jump");
            end

            7: begin
                if (dut.regfile_instance.registers[3] !== 32'd42) begin
                    $display("SIM FAIL: MUL failed. x3 expected 42, got %0d",
                             dut.regfile_instance.registers[3]);
                    $fatal(1);
                end

                $display("RISCV-TEST PASS: mul");
            end

            default: begin
                if (dut.regfile_instance.registers[3] !== 32'd42) begin
                    $display("SIM FAIL: APB read expected x3 = 42, got %0d",
                             dut.regfile_instance.registers[3]);
                    $fatal(1);
                end else begin
                    $display("APB read PASS: x3 = %0d",
                             dut.regfile_instance.registers[3]);
                end

                if (dut.regfile_instance.registers[12] !== 32'd42) begin
                    $display("SIM FAIL: BNE test failed. x12 = %0d",
                             dut.regfile_instance.registers[12]);
                    $fatal(1);
                end else begin
                    $display("BNE PASS: x12 = %0d",
                             dut.regfile_instance.registers[12]);
                end

                if (dut.regfile_instance.registers[14] !== 32'd55) begin
                    $display("SIM FAIL: JAL test failed. x14 = %0d",
                             dut.regfile_instance.registers[14]);
                    $fatal(1);
                end else begin
                    $display("JAL PASS: x14 = %0d",
                             dut.regfile_instance.registers[14]);
                end

                if (dut.regfile_instance.registers[17] !== 32'd77) begin
                    $display("SIM FAIL: JALR test failed. x17 = %0d",
                             dut.regfile_instance.registers[17]);
                    $fatal(1);
                end else begin
                    $display("JALR PASS: x17 = %0d",
                             dut.regfile_instance.registers[17]);
                end

                if (led_out !== 8'd42) begin
                    $display("SIM FAIL: APB write expected led_out = 42, got %0d",
                             led_out);
                    $fatal(1);
                end else begin
                    $display("APB write PASS: led_out = %0d", led_out);
                end

                $display("SIM PASS: default APB/control-flow test");
            end

        endcase

        $display("Shutting down");
        $finish;
    end

    initial begin
            $monitor(
                "Time: %0t | PC: %h | Inst: %h | Op: %h | x1: %0d | x2: %0d | x3: %0d | led_out: %0d | apb_psel=%b apb_penable=%b apb_pwrite=%b apb_paddr=%h apb_pread_data=%0d write_back=%0d",
                $time,
                dut.current_pc_wire,
                instruction_tb,
                opcode_out_tb,
                dut.regfile_instance.registers[1],
                dut.regfile_instance.registers[2],
                dut.regfile_instance.registers[3],
                led_out,
                dut.apb_psel,
                dut.apb_penable,
                dut.apb_pwrite,
                dut.apb_paddr,
                dut.apb_pread_data,
                dut.write_back_data
            );
    end

endmodule