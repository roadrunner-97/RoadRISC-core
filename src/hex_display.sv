module hex_display(
    input logic reset,
    input logic clock,
    input logic[7:0] data,
    input logic[1:0] display_blank,
    output logic[6:0] segments,
    output logic segment_select
);

    //gives us around a 95hz clock which we can just use directly
    //as our digit selector
    clock_divider
         #(.downclock_ratio(524288)) digit_selecter(
            .in_clock(clock),
            .reset(reset),
            .out_clock(segment_select)
        );

    // segments: bit order is gfedcba (bit 0 = a, bit 6 = g)
    // active low: 0 = segment on, 1 = segment off
    always_comb begin
        if(display_blank[segment_select]) begin
            segments = 7'b1111111;
        end else begin
            case (segment_select ? data[7:4] : data[3:0])
                4'h0: segments = 7'b1000000; // 0
                4'h1: segments = 7'b1111001; // 1
                4'h2: segments = 7'b0100100; // 2
                4'h3: segments = 7'b0110000; // 3
                4'h4: segments = 7'b0011001; // 4
                4'h5: segments = 7'b0010010; // 5
                4'h6: segments = 7'b0000010; // 6
                4'h7: segments = 7'b1111000; // 7
                4'h8: segments = 7'b0000000; // 8
                4'h9: segments = 7'b0010000; // 9
                4'ha: segments = 7'b0001000; // A
                4'hb: segments = 7'b0000011; // b
                4'hc: segments = 7'b1000110; // C
                4'hd: segments = 7'b0100001; // d
                4'he: segments = 7'b0000110; // E
                4'hf: segments = 7'b0001110; // F
                default: segments = 7'b1111111; // blank
            endcase
        end
    end
endmodule