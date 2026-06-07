`timescale 1ns/1ps

module alu_tb;
    import definitions::*;

    word_t    input_a;
    word_t    input_b;
    opcode_t  opcode;
    word_t    result;
    logic     equal;
    logic     less_than;

    alu dut (
        .input_a   (input_a),
        .input_b   (input_b),
        .opcode    (opcode),
        .result    (result),
        .equal     (equal),
        .less_than (less_than)
    );

    task check(
        input opcode_t op,
        input word_t a, b, expected,
        input string label
    );
        opcode  = op;
        input_a = a;
        input_b = b;
        #1;
        if (result !== expected)
            $fatal(1, "FAIL [%s]: a=%0h b=%0h expected=%0h got=%0h",
                   label, a, b, expected, result);
    endtask

    // The equal/less_than flags are combinational on a and b and
    // independent of the opcode, so drive a/b and check them directly.
    task check_flags(
        input word_t a, b,
        input logic  exp_equal, exp_less_than,
        input string label
    );
        input_a = a;
        input_b = b;
        #1;
        if (equal !== exp_equal)
            $fatal(1, "FAIL [%s]: a=%0h b=%0h expected equal=%0b got=%0b",
                   label, a, b, exp_equal, equal);
        if (less_than !== exp_less_than)
            $fatal(1, "FAIL [%s]: a=%0h b=%0h expected less_than=%0b got=%0b",
                   label, a, b, exp_less_than, less_than);
    endtask

    initial begin
        $dumpfile("build/alu.vcd");
        $dumpvars(0, alu_tb);

        // ADD
        check(OP_ADD, 64'h1, 64'h2, 64'h3,                        "ADD basic");
        check(OP_ADD, 64'hFFFFFFFFFFFFFFFF, 64'h1, 64'h0,          "ADD overflow wrap");
        check(OP_ADD, 64'h0, 64'h0, 64'h0,                        "ADD zero");

        // SUB
        check(OP_SUB, 64'h5, 64'h3, 64'h2,                        "SUB basic");
        check(OP_SUB, 64'h0, 64'h1, 64'hFFFFFFFFFFFFFFFF,         "SUB underflow wrap");
        check(OP_SUB, 64'hA, 64'hA, 64'h0,                        "SUB to zero");

        // AND
        check(OP_AND, 64'hFF, 64'h0F, 64'h0F,                     "AND basic");
        check(OP_AND, 64'hFFFFFFFFFFFFFFFF, 64'h0, 64'h0,         "AND with zero");
        check(OP_AND, 64'hAAAAAAAAAAAAAAAA, 64'h5555555555555555, 64'h0, "AND no overlap");

        // OR
        check(OP_OR, 64'hF0, 64'h0F, 64'hFF,                      "OR basic");
        check(OP_OR, 64'h0, 64'h0, 64'h0,                         "OR zero");
        check(OP_OR,  64'hAAAAAAAAAAAAAAAA, 64'h5555555555555555, 64'hFFFFFFFFFFFFFFFF, "OR full");

        // XOR
        check(OP_XOR, 64'hFF, 64'hFF, 64'h0,                      "XOR same");
        check(OP_XOR, 64'hAAAAAAAAAAAAAAAA, 64'h5555555555555555, 64'hFFFFFFFFFFFFFFFF, "XOR alternating");
        check(OP_XOR, 64'h0, 64'h0, 64'h0,                        "XOR zero");

        // SHL
        check(OP_SHL, 64'h1, 64'h1, 64'h2,                        "SHL by 1");
        check(OP_SHL, 64'h1, 64'h8, 64'h100,                      "SHL by 8");
        check(OP_SHL, 64'h1, 64'h3F, 64'h8000000000000000,        "SHL to MSB");

        // SHR
        check(OP_SHR, 64'h100, 64'h1, 64'h80,                     "SHR by 1");
        check(OP_SHR, 64'h8000000000000000, 64'h3F, 64'h1,        "SHR from MSB");
        check(OP_SHR, 64'hFFFFFFFFFFFFFFFF, 64'h1, 64'h7FFFFFFFFFFFFFFF, "SHR logical no sign extend");

        // ADDI — immediate add, same datapath as ADD (immediate arrives on input_b)
        check(OP_ADDI, 64'h0, 64'h1, 64'h1,                      "ADDI from zero");
        check(OP_ADDI, 64'h10, 64'h22, 64'h32,                   "ADDI basic");
        check(OP_ADDI, 64'hFFFFFFFFFFFFFFFF, 64'h1, 64'h0,        "ADDI overflow wrap");

        // LUI — load upper immediate: result = imm << 20 (imm on input_b)
        check(OP_LUI, 64'h0, 64'h1, 64'h100000,                  "LUI one");
        check(OP_LUI, 64'h0, 64'hABC, 64'hABC00000,              "LUI basic");
        check(OP_LUI, 64'h0, 64'h0, 64'h0,                       "LUI zero");

        // equal / less_than flags                          a                   b                eq  lt
        check_flags(64'h0,                64'h0,                1'b1, 1'b0, "FLAGS zero equal");
        check_flags(64'h5,                64'h5,                1'b1, 1'b0, "FLAGS equal nonzero");
        check_flags(64'hFFFFFFFFFFFFFFFF, 64'hFFFFFFFFFFFFFFFF, 1'b1, 1'b0, "FLAGS equal max");
        check_flags(64'h3,                64'h5,                1'b0, 1'b1, "FLAGS a less than b");
        check_flags(64'h5,                64'h3,                1'b0, 1'b0, "FLAGS a greater than b");
        check_flags(64'h0,                64'h1,                1'b0, 1'b1, "FLAGS zero less than one");
        check_flags(64'hFFFFFFFFFFFFFFFF, 64'h0,                1'b0, 1'b0, "FLAGS max not less than zero (unsigned)");
        check_flags(64'h0,                64'hFFFFFFFFFFFFFFFF, 1'b0, 1'b1, "FLAGS zero less than max (unsigned)");

        $finish(0);
    end

endmodule