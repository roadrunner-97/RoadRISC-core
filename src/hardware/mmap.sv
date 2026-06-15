import definitions::*;

module mmap #(
    parameter int RAM_SIZE = 16384,
    parameter string FILE = "src/program.hex"
)(
    input logic clock,

    input addr_t memory_address,
    input word_t memory_write_data,
    output word_t memory_read_data,
    input logic write_enable,

    input addr_t vga_address,
    output word_t vga_data
);

    word_t address_unused;

    // Port A is the CPU data port: writes (ST) and reads (LD).
    // LD and ST never happen in the same cycle, so the address muxes on write_enable.

    Gowin_DPB ram (
        // Port A — CPU data read/write (32-bit)
        .douta  (memory_read_data),
        .clka   (clock),
        .ocea   (1'b1),
        .cea    (1'b1),
        .reseta (1'b0),
        .wrea   (write_enable),
        .ada    (memory_address),
        .dina   (memory_write_data),

        // Port B — instruction fetch (32-bit, read only)
        .doutb  (vga_data),
        .clkb   (clock),
        .oceb   (1'b1),
        .ceb    (1'b1),
        .resetb (1'b0),
        .wreb   (1'b0),
        .adb    (vga_address),
        .dinb   (32'h0)
    );

endmodule