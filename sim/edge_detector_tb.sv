`timescale 1ns/1ps

module edge_detector_tb;
    reg clock;
    reg in;
    wire out_posedge;
    wire out_negedge;

    edge_detector dut(
        .clock(clock),
        .in(in),
        .out_posedge(out_posedge),
        .out_negedge(out_negedge)
    );

    initial begin
        $dumpfile("build/edge_detector.vcd");
        $dumpvars(0, edge_detector_tb);

        clock <= 0;
        in <= 0;
        #10
        in <= 1;
        #20
        in <= 0;
        #20
        in <= 1;
        #14
        in <= 0;
        #7
        in <= 1;
        #41
        in <= 0;
        #34
        in <= 1;
        #51
        $finish(0);
    end

    always begin
        #5 clock = ~clock;
    end
endmodule