import definitions::*;

module core
(
    input logic reset,
    input logic clock,
    output word_t output_word,
    //vga data just passing through
    input addr_t vga_address,
    output word_t vga_data
);

//rom controls
    addr_t pc;
    addr_t pc_next;

    addr_t sp;
    addr_t sp_next;

    instruction_t current_instruction;
    instruction_t instruction_reg;
    decoded_instruction_t controls;
    cpu_core_state_t core_state;


// ram controls

    addr_t intended_ram_address;
    word_t intended_ram_read_data;
    word_t intended_ram_write_data;
    logic intended_ram_wr_enable;

    addr_t actual_ram_address;
    word_t actual_ram_read_data;
    word_t actual_ram_write_data;
    logic actual_ram_wr_enable;

// register controls
    reg_addr_t reg_rd1_select;
    word_t reg_rd1_data;

    reg_addr_t reg_rd2_select;
    word_t reg_rd2_data;

    reg_addr_t reg_wr_select;
    word_t reg_wr_data;
    logic reg_wr_enable;

// alu wires
    word_t alu_input_a;
    word_t alu_input_b;
    word_t alu_result;
    logic alu_equal;
    logic alu_less_than;
    logic alu_greater_than;
    opcode_t curr_opcode;

    logic version_requested;
    word_t version_data;

    version version
    (
        .clock(clock),
        .version_requested(version_requested),
        .version_data(version_data)
    );

//i'm going to need to merge related signals into busses
    memory_watchman watchman
    (
        .clock(clock),
        .reset(reset),
        .core_state(core_state),
        .core_address(intended_ram_address),
        .core_write_data(intended_ram_write_data),
        .core_read_data(intended_ram_read_data),
        .core_write_enable(intended_ram_wr_enable),
        .mmap_address(actual_ram_address),
        .mmap_write_data(actual_ram_write_data),
        .mmap_read_data(actual_ram_read_data),
        .mmap_write_enable(actual_ram_wr_enable),
        .version_command_requested(version_requested),
        .version_command_response(version_data)
    );

    mmap #(
        .RAM_SIZE(1024),
        .FILE("src/program.hex")
    ) mmap(
        .clock(clock),
        .memory_address(actual_ram_address),
        .memory_read_data(actual_ram_read_data),
        .memory_write_data(actual_ram_write_data),
        .write_enable(actual_ram_wr_enable),
        .vga_address(vga_address),
        .vga_data(vga_data)
    );

    instruction_decoder idc(
        .in(current_instruction),
        .out(controls)
    );

    registers registers(
        .clock(clock),
        .read_1_select(reg_rd1_select),
        .read_1_data(reg_rd1_data),
        .read_2_select(reg_rd2_select),
        .read_2_data(reg_rd2_data),
        .write_select(reg_wr_select),
        .write_data(reg_wr_data),
        .write_enable(reg_wr_enable),
        .debug(output_word)
    );

    alu alu(
        .input_a(alu_input_a),
        .input_b(alu_input_b),
        .opcode(controls.opcode),
        .result(alu_result),
        .equal(alu_equal),
        .less_than(alu_less_than),
        .greater_than(alu_greater_than)
    );

    assign curr_opcode = controls.opcode;


    always_ff @(posedge clock) begin
        if(reset) begin
            pc <= RESET_ADDRRESS;
            core_state <= FETCH;
            sp <= 'hFFFF;
        end else begin
            case(core_state)
                FETCH: begin
                    core_state <= EXECUTE; // this cycle we just loaded the instruction from memory
                end

                EXECUTE: begin
                    if(controls.mem_read || controls.mem_write) begin
                        core_state <= TRANSFER;
                    end else begin
                        core_state <= FETCH;
                        pc <= pc_next;
                        sp <= sp_next;
                    end
                end

                TRANSFER: begin
                    core_state <= FETCH;
                    pc <= pc_next;
                    sp <= sp_next;
                end
            endcase
        end
    end

    // capture the fetched instruction during EXECUTE so the decoded controls
    // stay stable through TRANSFER (where stores still need them)
    always_ff @(posedge clock) begin
        if(core_state == EXECUTE) begin
            instruction_reg <= intended_ram_read_data;
        end
    end

    always_comb begin
        current_instruction = instruction_reg;
        pc_next = pc + 1;
        sp_next = sp;

        reg_wr_enable = '0;
        reg_wr_select = controls.reg_destination;
        reg_wr_data = '0;

        reg_rd1_select = controls.reg_a;
        reg_rd2_select = controls.reg_b;

        intended_ram_address = '0;
        intended_ram_wr_enable = '0;
        intended_ram_write_data = '0;

        alu_input_a = reg_rd1_data;

        case(core_state)
            FETCH: begin
                intended_ram_address = pc; //fetching the instruction means we're pointing at the PC
            end

            EXECUTE: begin
                //now the instruction has been fetched we can decode this instruction from RAM
                current_instruction = intended_ram_read_data;

                //only writeback to registers during the execute cycle
                //(so we don't do it again in the transfer cycle)
                if(controls.reg_writeback) begin
                    reg_wr_enable = '1;
                    reg_wr_data = alu_result;
                end
            end

            TRANSFER: begin
                if(controls.opcode == OP_LD) begin
                    reg_wr_enable = '1;
                end
                if(controls.opcode == OP_POP) begin
                    reg_wr_enable = '1;
                end

                if(controls.opcode == OP_ST) begin
                    intended_ram_address = reg_rd2_data + controls.immediate;
                    intended_ram_wr_enable = '1;
                    intended_ram_write_data = reg_rd1_data;
                end

                if(controls.opcode == OP_PUSH) begin
                    intended_ram_address = sp - 1;
                    intended_ram_wr_enable = '1;
                    intended_ram_write_data = reg_rd1_data;
                end

                if(controls.opcode == OP_CALL) begin
                    intended_ram_address = sp - 1;
                    intended_ram_wr_enable = '1;
                    intended_ram_write_data = pc + 1;
                end

                if(controls.opcode == OP_RET) begin
                    intended_ram_address = sp;
                    pc_next = intended_ram_read_data;
                    sp_next = sp + 1;
                end
            end
        endcase

        alu_input_b = controls.use_immediate ? controls.immediate : reg_rd2_data;

        //jumping commands
        if(controls.jump) begin
            case(controls.opcode)
                OP_JMP: begin
                    pc_next = controls.immediate;
                end
                OP_JAL: begin
                    pc_next = controls.immediate;
                    reg_wr_data = pc + 1;
                end
                OP_JREL: begin
                    pc_next = pc + 32'($signed(controls.immediate[15:0]));
                end
                OP_CALL: begin
                    pc_next = pc + 32'($signed(controls.immediate[15:0]));
                end
            endcase
        end

        //branching commands
        if(controls.branch) begin
            if((controls.opcode == OP_BEQ && alu_equal) || 
               (controls.opcode == OP_BLT && alu_less_than ||
                controls.opcode == OP_BNEQ && ~alu_equal ||
                controls.opcode == OP_BGT && alu_greater_than)) begin
                    pc_next = pc + 32'($signed(controls.immediate[15:0]));
            end
        end

        if(controls.mem_read && core_state != FETCH ) begin //we can't be doing memory access during PC fetch state
            reg_wr_data = intended_ram_read_data;
            if(controls.opcode == OP_LD) begin
                intended_ram_address = addr_t'(reg_rd1_data + controls.immediate);
            end else if (controls.opcode == OP_POP) begin
                intended_ram_address = sp;
                sp_next = sp + 1;
            end else if (controls.opcode == OP_RET) begin
                intended_ram_address = sp;
            end
        end

        if (controls.mem_write && core_state != FETCH) begin
            if(controls.opcode == OP_PUSH || 
               controls.opcode == OP_CALL) begin
                sp_next = sp - 1;
            end
        end

        if(controls.opcode == OP_LDI) begin
            reg_wr_data = controls.immediate;
        end

        if(controls.opcode == OP_STS) begin
            sp_next = reg_rd1_data;
        end

        if(controls.opcode == OP_LDS) begin
            reg_wr_data = sp;
        end

        if(controls.halt) begin
            pc_next = pc;
        end
    end


endmodule
