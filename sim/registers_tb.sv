`timescale 1ns/1ps

module registers_tb;

    logic        clock;
    logic [3:0]  read_1_select;
    logic [63:0] read_1_data;
    logic [3:0]  read_2_select;
    logic [63:0] read_2_data;
    logic [3:0]  write_select;
    logic [63:0] write_data;
    logic        write_enable;

    registers dut (
        .clock         (clock),
        .read_1_select (read_1_select),
        .read_1_data   (read_1_data),
        .read_2_select (read_2_select),
        .read_2_data   (read_2_data),
        .write_select  (write_select),
        .write_data    (write_data),
        .write_enable  (write_enable)
    );

    initial clock = 0;
    always #5 clock = ~clock;

    task write_reg(input [3:0] reg_sel, input [63:0] data);
        @(posedge clock);
        write_select <= reg_sel;
        write_data   <= data;
        write_enable <= 1;
        @(posedge clock);
        write_enable <= 0;
    endtask

    task check_read(input [3:0] reg_sel, input [63:0] expected, input string label);
        read_1_select = reg_sel;
        #1;
        if (read_1_data !== expected)
            $fatal(1, "FAIL [%s]: reg[%0d] expected %0h got %0h", label, reg_sel, expected, read_1_data);
    endtask

    initial begin
        $dumpfile("build/registers.vcd");
        $dumpvars(0, registers_tb);

        write_enable  = 0;
        write_select  = 0;
        write_data    = 0;
        read_1_select = 0;
        read_2_select = 0;

        // R0 always reads zero regardless of writes
        write_reg(4'h0, 64'hDEADBEEFCAFEBABE);
        check_read(4'h0, 64'h0, "R0 write ignored");

        // write and read back a few registers
        write_reg(4'h1, 64'hAAAAAAAAAAAAAAAA);
        check_read(4'h1, 64'hAAAAAAAAAAAAAAAA, "R1 readback");

        write_reg(4'hF, 64'h123456789ABCDEF0);
        check_read(4'hF, 64'h123456789ABCDEF0, "R15 readback");

        // write to R1, simultaneously read R1 and R2 on both ports
        write_reg(4'h2, 64'hBBBBBBBBBBBBBBBB);
        read_1_select = 4'h1;
        read_2_select = 4'h2;
        #1;
        if (read_1_data !== 64'hAAAAAAAAAAAAAAAA)
            $fatal(1, "FAIL: dual read port 1 expected AAAA... got %0h", read_1_data);
        if (read_2_data !== 64'hBBBBBBBBBBBBBBBB)
            $fatal(1, "FAIL: dual read port 2 expected BBBB... got %0h", read_2_data);

        // overwrite R1 and verify update
        write_reg(4'h1, 64'hCCCCCCCCCCCCCCCC);
        check_read(4'h1, 64'hCCCCCCCCCCCCCCCC, "R1 overwrite");

        $finish(0);
    end

endmodule