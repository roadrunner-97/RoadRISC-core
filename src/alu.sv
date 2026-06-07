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

            OP_LUI: begin
                result = input_b << 20;
            end

            OP_SUB: begin
                result = input_a - input_b;
            end

            OP_AND: begin
                result = input_a & input_b;
            end

            OP_OR: begin
                result = input_a | input_b;
            end

            OP_XOR: begin
                result = input_a ^ input_b;
            end

            OP_SHL: begin
                result = input_a << input_b;
            end

            OP_SHR: begin
                result = input_a >> input_b;
            end

            default: begin
                result = '0;
            end
        endcase
    end

endmodule