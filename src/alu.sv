import definitions::*;

module alu (alu_if.unit op);

    logic [(2 * RAM_WIDTH) - 1:0] product;

	Integer_Multiplier_Top your_instance_name(
		.mul_a(op.input_a), //input [31:0] mul_a
		.mul_b(op.input_b), //input [31:0] mul_b
		.product(product) //output [63:0] product
	);

    always_comb begin
        op.equal        = op.input_a == op.input_b;
        op.less_than    = op.input_a <  op.input_b;
        op.greater_than = op.input_a >  op.input_b;
        case (op.opcode)
            OP_ADD,  OP_ADDI: op.result = op.input_a + op.input_b;
            OP_SUB,  OP_SUBI: op.result = op.input_a - op.input_b;
            OP_AND,  OP_ANDI: op.result = op.input_a & op.input_b;
            OP_OR,   OP_ORI:  op.result = op.input_a | op.input_b;
            OP_XOR,  OP_XORI: op.result = op.input_a ^ op.input_b;
            OP_SHL,  OP_SHLI: op.result = op.input_a << op.input_b;
            OP_SHR,  OP_SHRI: op.result = op.input_a >> op.input_b;
            OP_MULL: op.result = product[31:0];
            OP_MULU: op.result = product[63:32];
            default:           op.result = '0;
        endcase
    end

endmodule
