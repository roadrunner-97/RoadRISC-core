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
        out.reg_writeback = '0;

        case(in.opcode)
            OP_ADD, OP_ADDI, OP_SUB, OP_SUBI, OP_AND, OP_ANDI, OP_OR, OP_ORI,
            OP_XOR, OP_XORI, OP_SHL, OP_SHLI, OP_SHR, OP_SHRI, OP_LD, OP_LDI,
            OP_JAL, OP_LDS, OP_POP, OP_MULL, OP_MULU:
		out.reg_writeback = '1;
        endcase

        case(in.opcode)
            OP_ADDI, OP_SUBI, OP_ANDI, OP_ORI, OP_XORI, OP_SHLI, OP_SHRI,
            OP_LD, OP_ST, OP_JMP, OP_JAL, OP_JREL, OP_LDI, OP_CALL: begin
                out.immediate = in.operand.imm;
                out.use_immediate = '1;
                out.reg_b = '0;
            end
        endcase

        case(in.opcode) // reg_b overrides
            OP_LD, OP_ST, OP_BEQ, OP_BLT, OP_BNEQ, OP_BGT: begin
                out.reg_b = in.reg_destination;
            end
        endcase

        if(in.opcode == OP_LD ||
           in.opcode == OP_POP ||
           in.opcode == OP_RET) begin
            out.mem_read = '1;
        end

        if(in.opcode == OP_ST ||
           in.opcode == OP_PUSH ||
           in.opcode == OP_CALL) begin
            out.mem_write = '1;
        end

        if(in.opcode == OP_BEQ || in.opcode == OP_BLT ||
           in.opcode == OP_BNEQ || in.opcode == OP_BGT) begin
                out.immediate = in.operand.imm;
                out.branch = '1;
        end

        if(in.opcode == OP_JMP ||
           in.opcode == OP_JAL ||
           in.opcode == OP_JREL ||
           in.opcode == OP_CALL) out.jump = '1;

        if (in.opcode == OP_HALT) out.halt = '1;
    end

endmodule
