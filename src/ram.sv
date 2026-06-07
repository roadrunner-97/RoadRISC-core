import definitions::*;

module ram #(
    parameter int WORD_COUNT = 256
)(
    input logic clock,

    input ram_addr_t write_address,
    input word_t write_data,
    input logic write_enable,

    input ram_addr_t read_address,
    output word_t read_data
);

    word_t memory [WORD_COUNT];

    always_ff @(posedge clock) begin
        if(write_enable) begin
            memory[write_address] <= write_data;
        end
    end

    always_comb begin
        read_data = memory[read_address];
    end

endmodule