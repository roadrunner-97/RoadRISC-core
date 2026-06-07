import definitions::*;

module instruction_decoder
(
    input instruction_t in,
    output decoded_instruction_t out
);

    always_comb begin
        out.opcode = in.opcode;
        out.reg_destination = in.reg_destination;
        out.reg_a = in.reg_a;
        out.reg_b = in.operand.r.rb;
        out.immediate = '0;
        out.use_immediate = '0;
        out.mem_read = '0;
        out.mem_write = '0;
        out.branch = '0;
        out.jump = '0;
        out.halt = '0;
        out.reg_writeback = '1;

        //most operations require register writeback, this catches the special ones
        case(in.opcode)
            OP_ST, OP_BEQ, OP_BLT, OP_JMP, OP_NOP, OP_HALT: out.reg_writeback = '0;
        endcase

        case(in.opcode)
            OP_ADDI, OP_SUBI, OP_ANDI, OP_ORI, OP_XORI, OP_SHLI,
            OP_SHRI, OP_LD, OP_ST, OP_BEQ, OP_BLT, OP_JMP, OP_JAL: begin
                out.immediate = in.operand.imm;
                out.use_immediate = '1;
                out.reg_b = '0;
            end
        endcase

        if(in.opcode == OP_LD) out.mem_read = '1;
        if(in.opcode == OP_ST) out.mem_write = '1;
        if(in.opcode == OP_BEQ ||
           in.opcode == OP_BLT) out.branch = '1;
        if(in.opcode == OP_JMP ||
           in.opcode == OP_JAL) out.jump = '1;
        if (in.opcode == OP_HALT) out.halt = '1;
    end

endmodule