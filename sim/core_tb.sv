`timescale 1ns/1ps

module core_tb;
    import definitions::*;

    logic clock;
    logic reset;
    word_t output_data;

    vga_bus_if vga_bus();

    core dut (
        .clock   (clock),
        .reset   (reset),
        .output_word(output_data),
        .vga_bus (vga_bus)
    );

    initial clock = 0;
    always #5 clock = ~clock;

    initial begin
        $dumpfile("build/core.vcd");
        $dumpvars(0, core_tb);

        // hold reset for a few cycles
        reset = 1;
        repeat(4) @(posedge clock);
        reset = 0;

        // run long enough to see several fibonacci iterations
        // each iteration is 4 instructions (3x ADD + JMP)
        // so 200 cycles gives ~25 iterations
        repeat(500) @(posedge clock);

        $finish(0);
    end

endmodule