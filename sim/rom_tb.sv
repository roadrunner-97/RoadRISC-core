`timescale 1ns/1ps

module rom_tb;

    logic        clock;
    logic [7:0]  address;
    logic [63:0] data;

    rom #(
        .WORD_COUNT (256),
        .FILE       ("sim/rom.hex")
    ) dut (
        .clock   (clock),
        .address (address),
        .data    (data)
    );

    initial clock = 0;
    always #5 clock = ~clock;

    task read_word(input [7:0] addr, input [63:0] expected);
        @(posedge clock);
        address <= addr;
        @(posedge clock);
        #1;
        if (data !== expected)
            $fatal(1, "FAIL: addr=%0h expected=%0h got=%0h", addr, expected, data);
    endtask

    initial begin
        $dumpfile("build/rom.vcd");
        $dumpvars(0, rom_tb);

        address = 0;

        // spot checks against known values from rom.hex (seed=42)
        read_word(8'h00, 64'h1c80317fa3b1799d);
        read_word(8'h01, 64'h46685257bdd640fb);
        read_word(8'h2a, 64'h5715bd6fa4161293); // addr 42
        read_word(8'hff, 64'h0964fbbf8cd321b0); // addr 255

        $finish(0);
    end

endmodule