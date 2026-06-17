`timescale 1ns/1ps

module registers_tb;
    import definitions::*;

    logic clock;

    reg_rd_if rd1();
    reg_rd_if rd2();
    reg_wr_if wr();

    registers dut (
        .clock (clock),
        .rd1   (rd1),
        .rd2   (rd2),
        .wr    (wr)
    );

    initial clock = 0;
    always #5 clock = ~clock;

    task write_reg(input reg_addr_t sel, input word_t data);
        @(posedge clock);
        wr.select <= sel;
        wr.data   <= data;
        wr.enable <= 1;
        @(posedge clock);
        wr.enable <= 0;
    endtask

    task check_rd1(input reg_addr_t sel, input word_t expected, input string label);
        rd1.select = sel;
        #1;
        if (rd1.data !== expected)
            $fatal(1, "FAIL [%s]: port1 reg[%0d] expected %0h got %0h",
                   label, sel, expected, rd1.data);
    endtask

    task check_rd2(input reg_addr_t sel, input word_t expected, input string label);
        rd2.select = sel;
        #1;
        if (rd2.data !== expected)
            $fatal(1, "FAIL [%s]: port2 reg[%0d] expected %0h got %0h",
                   label, sel, expected, rd2.data);
    endtask

    integer i;

    initial begin
        $dumpfile("build/registers.vcd");
        $dumpvars(0, registers_tb);

        wr.enable  = 0;
        wr.select  = '0;
        wr.data    = '0;
        rd1.select = '0;
        rd2.select = '0;

        for (i = 0; i < REG_COUNT; i++)
            check_rd1(i[3:0], 32'h0000_0000, "init zero");

        write_reg(4'h1, 32'hAAAA_AAAA);
        check_rd1(4'h1, 32'hAAAA_AAAA, "R1 readback");

        write_reg(4'hF, 32'h1234_5678);
        check_rd1(4'hF, 32'h1234_5678, "R15 readback");
        check_rd1(4'h1, 32'hAAAA_AAAA, "R1 untouched by R15 write");

        @(posedge clock);
        wr.select <= 4'h2;
        wr.data   <= 32'hBEEF_CAFE;
        wr.enable <= 0;
        @(posedge clock);
        check_rd1(4'h2, 32'h0000_0000, "write_enable=0 ignored");

        write_reg(4'h2, 32'hBEEF_CAFE);
        check_rd1(4'h2, 32'hBEEF_CAFE, "R2 readback");

        rd1.select = 4'h1;
        rd2.select = 4'h2;
        #1;
        if (rd1.data !== 32'hAAAA_AAAA)
            $fatal(1, "FAIL: dual read port1 expected AAAA_AAAA got %0h", rd1.data);
        if (rd2.data !== 32'hBEEF_CAFE)
            $fatal(1, "FAIL: dual read port2 expected BEEF_CAFE got %0h", rd2.data);

        check_rd1(4'h2, 32'hBEEF_CAFE, "same reg port1");
        check_rd2(4'h2, 32'hBEEF_CAFE, "same reg port2");

        write_reg(4'h1, 32'hCCCC_CCCC);
        check_rd1(4'h1, 32'hCCCC_CCCC, "R1 overwrite");

        check_rd1(4'h3, 32'h0000_0000, "R3 pre-write");
        @(posedge clock);
        wr.select <= 4'h3;
        wr.data   <= 32'h5555_5555;
        wr.enable <= 1;
        rd1.select = 4'h3;
        #1;
        if (rd1.data !== 32'h0000_0000)
            $fatal(1, "FAIL [sync]: R3 updated before clock edge, got %0h", rd1.data);
        @(posedge clock);
        wr.enable <= 0;
        #1;
        if (rd1.data !== 32'h5555_5555)
            $fatal(1, "FAIL [sync]: R3 not updated after clock edge, got %0h", rd1.data);

        $display("registers_tb: all checks passed");
        $finish(0);
    end

endmodule
