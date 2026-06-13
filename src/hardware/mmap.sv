import definitions::*;

module mmap #(
    parameter int RAM_SIZE = 16384,
    parameter int ROM_SIZE = 1024, //will be mapped to the last 1024 bytes
    parameter string FILE = "src/program.hex"
)(
    input  logic         clock,

    input  addr_t        write_address,
    input  word_t        write_data,
    input  logic         write_enable,

    input  addr_t        read_address,
    output word_t        read_data,

    input  addr_t        instruction_pointer,
    output instruction_t instruction_data
);

    // Port A is the CPU data port: writes (ST) and reads (LD).
    // LD and ST never happen in the same cycle, so the address muxes on write_enable.
    logic [13:0] port_a_addr;
    assign port_a_addr = write_enable ? write_address[13:0] : read_address[13:0];

    Gowin_DPB ram (
        // Port A — CPU data read/write (32-bit)
        .douta  (read_data),
        .clka   (clock),
        .ocea   (1'b1),
        .cea    (1'b1),
        .reseta (1'b0),
        .wrea   (write_enable),
        .ada    (port_a_addr),
        .dina   (write_data),

        // Port B — instruction fetch (32-bit, read only)
        .doutb  (instruction_data),
        .clkb   (clock),
        .oceb   (1'b1),
        .ceb    (1'b1),
        .resetb (1'b0),
        .wreb   (1'b0),
        .adb    (instruction_pointer[13:0]),
        .dinb   (32'h0)
    );

endmodule