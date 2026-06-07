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
        out.reg_b = in.reg_b;
        out.immediate = '0;
        out.use_immediate = '0;
        out.mem_read = '0;
        out.mem_write = '0;
        out.branch = '0;
        out.jump = '0;
        out.halt = '0;
        out.reg_writeback = '0;

        case(in.opcode)
            OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR, OP_SHL, OP_SHR,
            OP_ADDI, OP_LUI, OP_LD, OP_JAL: out.reg_writeback = '1;
            default:  out.reg_writeback = '0;
        endcase

        case(in.opcode)
            OP_ADDI, OP_LUI: begin
                out.immediate = in.immediate;
                out.use_immediate = '1;
            end

            OP_LD: begin
                out.immediate = in.immediate;
                out.use_immediate = '1;
                out.mem_read = '1;   
            end

            OP_ST: begin
                out.immediate = in.immediate;
                out.use_immediate = '1;
                out.mem_write = '1;
            end

            OP_BEQ, OP_BLT: begin
                out.immediate = in.immediate;
                out.use_immediate = '1;
                out.branch = '1;
            end

            OP_JMP, OP_JAL: begin
                out.immediate = in.immediate;
                out.use_immediate = '1;
                out.jump = '1;
            end

            OP_HALT: begin
                out.halt = '1;
            end
        endcase


    end

endmodule