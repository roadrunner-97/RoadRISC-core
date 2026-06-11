`timescale 1ns/1ps

module core_tb;
    import definitions::*;

    logic clock;
    logic reset;
    logic [7:0] bus0_data;
    logic [7:0] bus1_data;
    logic [7:0] bus2_data;

    core dut (
        .clock(clock),
        .reset(reset),
        .bus0_connector(bus0_data),
        .bus1_connector(bus1_data),
        .bus2_connector(bus2_data)
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
        repeat(2000) @(posedge clock);

        $finish(0);
    end

endmodule
