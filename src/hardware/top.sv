module top (
    input  logic       clk,
    input  logic       rst,
    output logic [7:0] pmod0,
    output logic [7:0] pmod1,
    output logic [7:0] pmod2
);


    wire [6:0]segments;
    wire segment_select;
    logic [7:0] display_val;

    hex_display disp(
        .reset(rst),
        .clock(clk),
        .data(display_val),
        .display_blank(2'b0),
        .segments(segments),
        .segment_select(segment_select)
    );

    assign pmod0[2] = segments[0];
    assign pmod0[3] = segments[1];
    assign pmod0[1] = segments[2];
    assign pmod0[4] = segments[3];
    assign pmod0[5] = segments[4];
    assign pmod0[7] = segments[5];
    assign pmod0[6] = segment_select;
    assign pmod0[0] = segments[6];


    wire slow_clock;
    clock_divider
        #(.downclock_ratio(33554432)) digit_selecter(
        .in_clock(clk),
        .reset(rst),
        .out_clock(slow_clock)
    );


   core core(
       .reset(rst),
       .clock(slow_clock),
       .output_byte(display_val)
   );


assign pmod1 = 'b0;
assign pmod2 = 'b0;


endmodule