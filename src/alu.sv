import definitions::*;

module alu 
(
    input word_t input_a,
    input word_t input_b,
    input opcode_t opcode,
    output word_t result,
    output logic equal,
    output logic less_than
);

    always_comb begin
        equal = input_a == input_b;
        less_than = input_a < input_b;
        case (opcode)

            OP_ADD, OP_ADDI: begin
                result = input_a + input_b;
            end

            OP_SUB, OP_SUBI: begin
                result = input_a - input_b;
            end

            OP_AND, OP_ANDI: begin
                result = input_a & input_b;
            end

            OP_OR, OP_ORI: begin
                result = input_a | input_b;
            end

            OP_XOR, OP_XORI: begin
                result = input_a ^ input_b;
            end

            OP_SHL, OP_SHLI: begin
                result = input_a << input_b;
            end

            OP_SHR, OP_SHRI: begin
                result = input_a >> input_b;
            end

            default: begin
                result = '0;
            end
        endcase
    end

endmodule