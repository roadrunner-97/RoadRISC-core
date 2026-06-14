import definitions::*;

module registers(
    input logic clock,
    
    input reg_addr_t read_1_select,
    output word_t read_1_data,

    input reg_addr_t read_2_select,
    output word_t read_2_data,

    input reg_addr_t write_select,
    input word_t write_data,
    input logic write_enable,
    output word_t debug
);

    word_t registers[REG_COUNT];

    //debug ports to view in gtkwave
    word_t r0, r1, r2, r3, r4, r5, r6, r7;
    word_t r8, r9, r10, r11, r12, r13, r14, r15;
    assign r0  = registers[0];
    assign r1  = registers[1];
    assign r2  = registers[2];
    assign r3  = registers[3];
    assign r4  = registers[4];
    assign r5  = registers[5];
    assign r6  = registers[6];
    assign r7  = registers[7];
    assign r8  = registers[8];
    assign r9  = registers[9];
    assign r10 = registers[10];
    assign r11 = registers[11];
    assign r12 = registers[12];
    assign r13 = registers[13];
    assign r14 = registers[14];
    assign r15 = registers[15];
    assign debug = registers[15];

    integer i;
    initial begin
        for (i = 0; i < REG_COUNT; i++)
            registers[i] = '0;
    end


    assign read_1_data = registers[read_1_select];
    assign read_2_data = registers[read_2_select];

    always_ff @(posedge clock) begin
        if(write_enable) begin
            registers[write_select] <= write_data;
        end
    end
endmodule