import definitions::*;

module mmap #(
    parameter int RAM_SIZE = 16384,
    parameter string FILE = "src/program.hex"
)(
    input logic clock,
    mem_bus_if.slave    bus,
    vga_bus_if.provider vga_bus
);

    Gowin_DPB ram (
        // Port A — CPU data read/write (32-bit)
        .douta  (bus.read_data),
        .clka   (clock),
        .ocea   (1'b1),
        .cea    (1'b1),
        .reseta (1'b0),
        .wrea   (bus.write_enable),
        .ada    (bus.address),
        .dina   (bus.write_data),

        // Port B — VGA read (32-bit, read only)
        .doutb  (vga_bus.data),
        .clkb   (clock),
        .oceb   (1'b1),
        .ceb    (1'b1),
        .resetb (1'b0),
        .wreb   (1'b0),
        .adb    (vga_bus.address),
        .dinb   (32'h0)
    );

endmodule
