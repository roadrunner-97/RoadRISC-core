import definitions::*;

module vga_readout (
    input  logic clock,
    input  logic reset,
    
    output addr_t fb_address,
    input  word_t fb_data,
    
    output logic [3:0] r, g, b,
    output logic hsync, vsync
);
    logic [9:0] hpos;
    logic [9:0] vpos;
    logic pixel_phase;
    logic visible;

    word_t fb_x;
    word_t fb_y;
    word_t pixel_address;
    logic [2:0] pixel_within_word;
    logic [3:0] pixel_slice;

    vga_timer timing(
        .clock(clock),
        .reset(reset),
        .hpos(hpos),
        .vpos(vpos),
        .visible(visible),
        .hsync(hsync),
        .vsync(vsync),
        .pixel_phase(pixel_phase)
    );

    always_comb begin
        fb_x = hpos/2;
        fb_y = vpos/2;
        pixel_address = ((fb_y * 320) + fb_x);
        pixel_slice = fb_data[(7 - pixel_address[2:0]) * 4 +: 4];
        r = visible ? pixel_slice : 0;
        g = visible ? pixel_slice : 0;
        b = visible ? pixel_slice : 0;
    end

    always_ff @(posedge clock) begin
        if(hpos == 799) begin
            // Prime the start of the next scanline before hpos rolls over.
            // vpos[0] advances fb_y on odd lines; even lines repeat the same row (line doubling).
            fb_address <= 'h1A80 + (fb_y + vpos[0]) * 40;
        end else if(hpos[3:0] == 4'hF) begin
            fb_address <= 'h1A80 + (pixel_address / 8) + 1;
        end else begin
            fb_address <= 'h1A80 + (pixel_address / 8);
        end
    end


endmodule

