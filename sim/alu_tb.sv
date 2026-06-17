`timescale 1ns/1ps

module alu_tb;
    import definitions::*;

    alu_if op();

    alu dut (.op(op));

    task check(
        input opcode_t op_code,
        input word_t a, b, expected,
        input string label
    );
        op.opcode  = op_code;
        op.input_a = a;
        op.input_b = b;
        #1;
        if (op.result !== expected)
            $fatal(1, "FAIL [%s]: a=%0h b=%0h expected=%0h got=%0h",
                   label, a, b, expected, op.result);
    endtask

    task check_flags(
        input word_t a, b,
        input logic  exp_equal, exp_less_than,
        input string label
    );
        op.input_a = a;
        op.input_b = b;
        #1;
        if (op.equal !== exp_equal)
            $fatal(1, "FAIL [%s]: a=%0h b=%0h expected equal=%0b got=%0b",
                   label, a, b, exp_equal, op.equal);
        if (op.less_than !== exp_less_than)
            $fatal(1, "FAIL [%s]: a=%0h b=%0h expected less_than=%0b got=%0b",
                   label, a, b, exp_less_than, op.less_than);
    endtask

    initial begin
        $dumpfile("build/alu.vcd");
        $dumpvars(0, alu_tb);

        // ADD
        check(OP_ADD,  32'h0000_0001, 32'h0000_0002, 32'h0000_0003, "ADD basic");
        check(OP_ADD,  32'hFFFF_FFFF, 32'h0000_0001, 32'h0000_0000, "ADD overflow wrap");
        check(OP_ADD,  32'h0000_0000, 32'h0000_0000, 32'h0000_0000, "ADD zero");
        check(OP_ADDI, 32'h0000_0010, 32'h0000_0022, 32'h0000_0032, "ADDI basic");
        check(OP_ADDI, 32'hFFFF_FFFF, 32'h0000_0001, 32'h0000_0000, "ADDI overflow wrap");

        // SUB
        check(OP_SUB,  32'h0000_0005, 32'h0000_0003, 32'h0000_0002, "SUB basic");
        check(OP_SUB,  32'h0000_0000, 32'h0000_0001, 32'hFFFF_FFFF, "SUB underflow wrap");
        check(OP_SUB,  32'h0000_000A, 32'h0000_000A, 32'h0000_0000, "SUB to zero");
        check(OP_SUBI, 32'h0000_0032, 32'h0000_0010, 32'h0000_0022, "SUBI basic");

        // AND
        check(OP_AND,  32'h0000_00FF, 32'h0000_000F, 32'h0000_000F, "AND basic");
        check(OP_AND,  32'hFFFF_FFFF, 32'h0000_0000, 32'h0000_0000, "AND with zero");
        check(OP_AND,  32'hAAAA_AAAA, 32'h5555_5555, 32'h0000_0000, "AND no overlap");
        check(OP_ANDI, 32'h0000_F0F0, 32'h0000_0FF0, 32'h0000_00F0, "ANDI basic");

        // OR
        check(OP_OR,   32'h0000_00F0, 32'h0000_000F, 32'h0000_00FF, "OR basic");
        check(OP_OR,   32'h0000_0000, 32'h0000_0000, 32'h0000_0000, "OR zero");
        check(OP_OR,   32'hAAAA_AAAA, 32'h5555_5555, 32'hFFFF_FFFF, "OR full");
        check(OP_ORI,  32'h0000_F000, 32'h0000_000F, 32'h0000_F00F, "ORI basic");

        // XOR
        check(OP_XOR,  32'h0000_00FF, 32'h0000_00FF, 32'h0000_0000, "XOR same");
        check(OP_XOR,  32'hAAAA_AAAA, 32'h5555_5555, 32'hFFFF_FFFF, "XOR alternating");
        check(OP_XORI, 32'h0000_FF00, 32'h0000_0FF0, 32'h0000_F0F0, "XORI basic");

        // SHL
        check(OP_SHL,  32'h0000_0001, 32'h0000_0001, 32'h0000_0002, "SHL by 1");
        check(OP_SHL,  32'h0000_0001, 32'h0000_0008, 32'h0000_0100, "SHL by 8");
        check(OP_SHL,  32'h0000_0001, 32'h0000_001F, 32'h8000_0000, "SHL to MSB");
        check(OP_SHLI, 32'h0000_0003, 32'h0000_0004, 32'h0000_0030, "SHLI by 4");

        // SHR (logical)
        check(OP_SHR,  32'h0000_0100, 32'h0000_0001, 32'h0000_0080, "SHR by 1");
        check(OP_SHR,  32'h8000_0000, 32'h0000_001F, 32'h0000_0001, "SHR from MSB");
        check(OP_SHR,  32'hFFFF_FFFF, 32'h0000_0001, 32'h7FFF_FFFF, "SHR logical no sign extend");
        check(OP_SHRI, 32'h0000_00F0, 32'h0000_0004, 32'h0000_000F, "SHRI by 4");

        // default
        check(OP_NOP,  32'h1234_5678, 32'h9ABC_DEF0, 32'h0000_0000, "NOP/default zero");

        // flags (eq lt)
        check_flags(32'h0000_0000, 32'h0000_0000, 1'b1, 1'b0, "FLAGS zero equal");
        check_flags(32'h0000_0005, 32'h0000_0005, 1'b1, 1'b0, "FLAGS equal nonzero");
        check_flags(32'hFFFF_FFFF, 32'hFFFF_FFFF, 1'b1, 1'b0, "FLAGS equal max");
        check_flags(32'h0000_0003, 32'h0000_0005, 1'b0, 1'b1, "FLAGS a less than b");
        check_flags(32'h0000_0005, 32'h0000_0003, 1'b0, 1'b0, "FLAGS a greater than b");
        check_flags(32'h0000_0000, 32'h0000_0001, 1'b0, 1'b1, "FLAGS zero less than one");
        check_flags(32'hFFFF_FFFF, 32'h0000_0000, 1'b0, 1'b0, "FLAGS max not less than zero (unsigned)");
        check_flags(32'h0000_0000, 32'hFFFF_FFFF, 1'b0, 1'b1, "FLAGS zero less than max (unsigned)");

        $display("alu_tb: all checks passed");
        $finish(0);
    end

endmodule
