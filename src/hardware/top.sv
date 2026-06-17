import definitions::*;

module top (
    input  logic       clk,
    input  logic       rst,
    output logic [7:0] pmod0,
    output logic [7:0] pmod1,
    output logic [7:0] pmod2
);

    wire [6:0] segments;
    wire       segment_select;
    logic [31:0] display_val;

    hex_display disp(
        .reset(rst),
        .clock(clk),
        .data(display_val[7:0]),
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

    logic [3:0] red, green, blue;
    logic hsync, vsync;

    vga_bus_if vga_bus();

    vga_readout vga_readout(
        .clock(clk),
        .reset(rst),
        .fb_address(vga_bus.address),
        .fb_data(vga_bus.data),
        .r(red),
        .g(green),
        .b(blue),
        .hsync(hsync),
        .vsync(vsync)
    );

    core core(
        .reset(rst),
        .clock(clk),
        .output_word(display_val),
        .vga_bus(vga_bus)
    );

    assign pmod1[1] = hsync;
    assign pmod1[3] = vsync;

    assign pmod1[0] = green[0];
    assign pmod1[2] = green[1];
    assign pmod1[4] = green[2];
    assign pmod1[6] = green[3];

    assign pmod2[0] = red[0];
    assign pmod2[2] = red[1];
    assign pmod2[4] = red[2];
    assign pmod2[6] = red[3];

    assign pmod2[1] = blue[0];
    assign pmod2[3] = blue[1];
    assign pmod2[5] = blue[2];
    assign pmod2[7] = blue[3];

endmodule
