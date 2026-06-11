import definitions::*;

module mmap #(
    parameter int RAM_SIZE = 1024,
    parameter int ROM_SIZE = 1024, //will be mapped to the last 1024 bytes
    parameter string FILE = "src/program.hex"
)(
    input logic clock,

    input addr_t write_address,
    input word_t write_data,
    input logic write_enable,
    
    input addr_t read_address,
    output word_t read_data,

    input addr_t instruction_pointer,
    output instruction_t instruction_data
);

    word_t memory [RAM_SIZE];
    initial $readmemh(FILE, memory);

    always_ff @(posedge clock) begin
        if(write_enable && write_address < RAM_SIZE) begin
            memory[write_address] <= write_data;
        end
    end

    always_comb begin
        if(read_address < RAM_SIZE) begin
            read_data = memory[read_address];
        end else begin
            read_data = 'b0;
        end
    end

    always_comb begin
        if (instruction_pointer < RAM_SIZE -1) begin
            instruction_data = memory[instruction_pointer];
        end else begin
            instruction_data = 'b0;
        end
    end

endmodule