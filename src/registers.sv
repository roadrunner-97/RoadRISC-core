import definitions::*;

module registers(
    input logic clock,
    reg_rd_if.regfile rd1,
    reg_rd_if.regfile rd2,
    reg_wr_if.regfile wr,
    output word_t debug
);

    word_t registers[REG_COUNT];

    // debug nets for gtkwave
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

    assign rd1.data = registers[rd1.select];
    assign rd2.data = registers[rd2.select];

    always_ff @(posedge clock) begin
        if(wr.enable)
            registers[wr.select] <= wr.data;
    end
endmodule
