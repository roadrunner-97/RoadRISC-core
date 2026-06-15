module vga_timer(
    input logic       clock,
    input logic       reset,
    output logic[9:0] hpos,
    output logic[9:0] vpos,
    output logic      visible,
    output logic      hsync,
    output logic      vsync,
    output logic      pixel_phase 
);

    always_comb begin
        visible = (hpos < 640 && vpos < 480);
    end

    always_ff @(posedge clock) begin
        if(reset) begin
            hpos <= '0;
            vpos <= '0;
            pixel_phase <= 0;
            hsync <= 1;
            vsync <= 1;
        end else begin
            hsync <= (hpos < 656 || hpos >= 752);
            vsync <= (vpos < 490 || vpos >= 492);
            if (pixel_phase) begin
                pixel_phase <= 0;
                if(hpos == 799) begin
                    hpos <= 0;
                    if(vpos == 524) begin
                        vpos <= 0;
                    end else begin
                        vpos <= vpos + 1;
                    end
                end else begin
                    hpos <= hpos + 1;
                end
            end else begin
                pixel_phase <= 1;
            end
        end
    end
endmodule