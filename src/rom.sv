import definitions::*;

module rom #(
    parameter int WORD_COUNT = 256,
    parameter string FILE = "sim/rom.hex"
)(
    input logic clock,
    input rom_addr_t address,
    output word_t data
);

    word_t memory [WORD_COUNT];

    initial $readmemh(FILE, memory);

    always_ff @(posedge clock) begin
        data <= memory[address];
    end
endmodule