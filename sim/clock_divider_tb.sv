`timescale 1ns/1ps

module clock_divider_tb;

    reg clk;
    reg rst;
    wire out_clock1;
    wire out_clock2;
    wire out_clock4;

    clock_divider #(.downclock_ratio(1)) dut1(
        .in_clock(clk),
        .reset(rst),
        .out_clock(out_clock1)
    );

    clock_divider #(.downclock_ratio(2)) dut2(
        .in_clock(clk),
        .reset(rst),
        .out_clock(out_clock2)
    );

    clock_divider #(.downclock_ratio(4)) dut4(
        .in_clock(clk),
        .reset(rst),
        .out_clock(out_clock4)
    );

    initial begin
        $dumpfile("build/clock_divider.vcd");
        $dumpvars(0, clock_divider_tb);

        //clear the module
        clk <= 0;
        rst <= 0;
        #13
        #7 rst <= 1;
        #9 rst <= 0;
        repeat(100) @(posedge clk);
        $finish;   
    end

    always begin
        #5 clk = ~clk;
    end
endmodule