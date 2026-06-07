`timescale 1ns/1ps

module ram_tb;

    logic        clock;
    logic [7:0]  write_address;
    logic [63:0] write_data;
    logic        write_enable;
    logic [7:0]  read_address;
    logic [63:0] read_data;

    ram #(
        .WORD_COUNT(256)
    ) dut (
        .clock         (clock),
        .write_address (write_address),
        .write_data    (write_data),
        .write_enable  (write_enable),
        .read_address  (read_address),
        .read_data     (read_data)
    );

    initial clock = 0;
    always #5 clock = ~clock;

    task write_word(input [7:0] addr, input [63:0] data);
        @(posedge clock);
        write_address <= addr;
        write_data    <= data;
        write_enable  <= 1;
        @(posedge clock);
        write_enable  <= 0;
    endtask

    task read_word(input [7:0] addr, input [63:0] expected);
        @(posedge clock);
        read_address <= addr;
        @(posedge clock); // wait for registered output
        #1;               // let combinational settle
        if (read_data !== expected)
            $fatal(1, "FAIL: addr=%0h expected=%0h got=%0h", addr, expected, read_data);
    endtask

    initial begin
        $dumpfile("build/ram.vcd");
        $dumpvars(0, ram_tb);

        write_enable  = 0;
        write_address = 0;
        write_data    = 0;
        read_address  = 0;

        // write some values
        write_word(8'h00, 64'hDEADBEEFCAFEBABE);
        write_word(8'h01, 64'h0123456789ABCDEF);
        write_word(8'hFF, 64'hFFFFFFFFFFFFFFFF);

        // read them back and verify
        read_word(8'h00, 64'hDEADBEEFCAFEBABE);
        read_word(8'h01, 64'h0123456789ABCDEF);
        read_word(8'hFF, 64'hFFFFFFFFFFFFFFFF);

        // verify an unwritten address reads as X or 0
        read_address <= 8'h42;
        repeat(10) @(posedge clock);

        $finish(0);
    end

endmodule