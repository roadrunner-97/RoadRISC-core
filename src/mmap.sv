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
    word_t rom [ROM_SIZE];
    initial $readmemh(FILE, rom);

    always_ff @(posedge clock) begin
        if(write_enable && write_address < ROM_START) begin
            memory[write_address] <= write_data;
        end
    end

    always_comb begin
        if(read_address < ROM_START) begin
            read_data = memory[read_address];
        end else begin
            read_data = rom[read_address - ROM_START];
        end
    end

    always_comb begin
        if (instruction_pointer < ROM_START) begin
            instruction_data = {memory[instruction_pointer], memory[instruction_pointer + 1]};
        end else begin
            instruction_data = {rom[instruction_pointer - ROM_START], rom[instruction_pointer - ROM_START + 1]};
        end
    end

endmodule