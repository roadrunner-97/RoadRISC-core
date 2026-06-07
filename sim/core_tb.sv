`timescale 1ns/1ps

module core_tb;
    import definitions::*;

    logic clock;
    logic reset;
    logic [7:0] output_data;

    core dut (
        .clock (clock),
        .reset (reset),
        .output_byte(output_data)
    );

    initial clock = 0;
    always #5 clock = ~clock;

    initial begin
        $dumpfile("build/core.vcd");
        $dumpvars(0, core_tb);

        $display("ROM_START = %0d", definitions::ROM_START);
        // hold reset for a few cycles
        reset = 1;
        repeat(4) @(posedge clock);
        reset = 0;

        // run long enough to see several fibonacci iterations
        // each iteration is 4 instructions (3x ADD + JMP)
        // so 200 cycles gives ~25 iterations
        repeat(200) @(posedge clock);

        $finish(0);
    end

endmodule