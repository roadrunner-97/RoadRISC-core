`timescale 1ns/1ps

module instruction_decoder_tb;
    import definitions::*;

    instruction_t         in;
    decoded_instruction_t out;

    instruction_decoder dut (
        .in  (in),
        .out (out)
    );

    task check_base(input string label);
        // fields that should always pass through unchanged
        if (out.opcode          !== in.opcode)          $fatal(1, "FAIL [%s]: opcode mismatch",  label);
        if (out.reg_destination !== in.reg_destination) $fatal(1, "FAIL [%s]: rd mismatch",      label);
        if (out.reg_a           !== in.reg_a)           $fatal(1, "FAIL [%s]: ra mismatch",      label);
        if (out.reg_b           !== in.reg_b)           $fatal(1, "FAIL [%s]: rb mismatch",      label);
    endtask

    task check_alu(input opcode_t op, input string label);
        in.opcode          = op;
        in.reg_destination = 4'h1;
        in.reg_a           = 4'h2;
        in.reg_b           = 4'h3;
        in.immediate       = 44'hDEAD;
        #1;
        check_base(label);
        if (out.use_immediate) $fatal(1, "FAIL [%s]: use_immediate should be 0", label);
        if (out.mem_read)      $fatal(1, "FAIL [%s]: mem_read should be 0",      label);
        if (out.mem_write)     $fatal(1, "FAIL [%s]: mem_write should be 0",     label);
        if (out.branch)        $fatal(1, "FAIL [%s]: branch should be 0",        label);
        if (out.jump)          $fatal(1, "FAIL [%s]: jump should be 0",          label);
        if (out.halt)          $fatal(1, "FAIL [%s]: halt should be 0",          label);
        if (!out.reg_writeback) $fatal(1, "FAIL [%s]: reg_writeback should be 1", label);
    endtask

    task check_imm(input opcode_t op, input string label);
        in.opcode          = op;
        in.reg_destination = 4'h1;
        in.reg_a           = 4'h2;
        in.reg_b           = 4'h3;
        in.immediate       = 44'hABCDE;
        #1;
        check_base(label);
        if (!out.use_immediate)          $fatal(1, "FAIL [%s]: use_immediate should be 1",   label);
        if (out.immediate !== 44'hABCDE) $fatal(1, "FAIL [%s]: immediate value wrong",       label);
        if (!out.reg_writeback)          $fatal(1, "FAIL [%s]: reg_writeback should be 1",    label);
    endtask

    initial begin
        $dumpfile("build/instruction_decoder.vcd");
        $dumpvars(0, instruction_decoder_tb);

        in = '0;

        // pure register ALU ops — no immediate, no mem, no branch
        check_alu(OP_ADD,  "ADD");
        check_alu(OP_SUB,  "SUB");
        check_alu(OP_AND,  "AND");
        check_alu(OP_OR,   "OR");
        check_alu(OP_XOR,  "XOR");
        check_alu(OP_SHL,  "SHL");
        check_alu(OP_SHR,  "SHR");

        // immediate ALU ops
        check_imm(OP_ADDI, "ADDI");
        check_imm(OP_LUI,  "LUI");

        // load
        in.opcode    = OP_LD;
        in.immediate = 44'h100;
        #1;
        if (!out.use_immediate) $fatal(1, "FAIL [LD]: use_immediate should be 1");
        if (!out.mem_read)      $fatal(1, "FAIL [LD]: mem_read should be 1");
        if (out.mem_write)      $fatal(1, "FAIL [LD]: mem_write should be 0");
        if (!out.reg_writeback) $fatal(1, "FAIL [LD]: reg_writeback should be 1");

        // store
        in.opcode    = OP_ST;
        in.immediate = 44'h200;
        #1;
        if (!out.use_immediate) $fatal(1, "FAIL [ST]: use_immediate should be 1");
        if (out.mem_read)       $fatal(1, "FAIL [ST]: mem_read should be 0");
        if (!out.mem_write)     $fatal(1, "FAIL [ST]: mem_write should be 1");
        if (out.reg_writeback)  $fatal(1, "FAIL [ST]: reg_writeback should be 0");

        // branches
        in.opcode    = OP_BEQ;
        in.immediate = 44'hFF;
        #1;
        if (!out.use_immediate) $fatal(1, "FAIL [BEQ]: use_immediate should be 1");
        if (!out.branch)        $fatal(1, "FAIL [BEQ]: branch should be 1");
        if (out.jump)           $fatal(1, "FAIL [BEQ]: jump should be 0");
        if (out.reg_writeback)  $fatal(1, "FAIL [BEQ]: reg_writeback should be 0");

        in.opcode = OP_BLT;
        #1;
        if (!out.branch)       $fatal(1, "FAIL [BLT]: branch should be 1");
        if (out.reg_writeback) $fatal(1, "FAIL [BLT]: reg_writeback should be 0");

        // jumps
        in.opcode    = OP_JMP;
        in.immediate = 44'h42;
        #1;
        if (!out.use_immediate) $fatal(1, "FAIL [JMP]: use_immediate should be 1");
        if (!out.jump)          $fatal(1, "FAIL [JMP]: jump should be 1");
        if (out.branch)         $fatal(1, "FAIL [JMP]: branch should be 0");
        if (out.reg_writeback)  $fatal(1, "FAIL [JMP]: reg_writeback should be 0");

        in.opcode = OP_JAL;
        #1;
        if (!out.jump)          $fatal(1, "FAIL [JAL]: jump should be 1");
        if (!out.reg_writeback) $fatal(1, "FAIL [JAL]: reg_writeback should be 1");

        // halt
        in.opcode = OP_HALT;
        #1;
        if (!out.halt)         $fatal(1, "FAIL [HALT]: halt should be 1");
        if (out.branch)        $fatal(1, "FAIL [HALT]: branch should be 0");
        if (out.jump)          $fatal(1, "FAIL [HALT]: jump should be 0");
        if (out.mem_read)      $fatal(1, "FAIL [HALT]: mem_read should be 0");
        if (out.mem_write)     $fatal(1, "FAIL [HALT]: mem_write should be 0");
        if (out.reg_writeback) $fatal(1, "FAIL [HALT]: reg_writeback should be 0");

        $finish(0);
    end

endmodule