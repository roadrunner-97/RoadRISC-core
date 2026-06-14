import definitions::*;

module core
(
    input logic reset,
    input logic clock,
    output word_t output_word
);

//rom controls
    addr_t pc;
    addr_t pc_next;
    instruction_t current_instruction;
    instruction_t instruction_reg;
    decoded_instruction_t controls;

// ram controls

    addr_t ram_address;
    word_t ram_read_data;
    word_t ram_write_data;
    logic ram_wr_enable;

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
    opcode_t curr_opcode;

    mmap #(
        .RAM_SIZE(1024),
        .FILE("src/program.hex")
    ) mmap(
        .clock(clock),
        .memory_address(ram_address),
        .memory_read_data(ram_read_data),
        .memory_write_data(ram_write_data),
        .write_enable(ram_wr_enable)
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
        .less_than(alu_less_than)
    );

    assign curr_opcode = controls.opcode;

    cpu_core_state_t core_state;

    always_ff @(posedge clock) begin
        if(reset) begin
            pc <= RESET_ADDRRESS;
            core_state <= FETCH;
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
                    end
                end

                TRANSFER: begin
                    core_state <= FETCH;
                    pc <= pc_next;
                end
            endcase
        end
    end

    // capture the fetched instruction during EXECUTE so the decoded controls
    // stay stable through TRANSFER (where stores still need them)
    always_ff @(posedge clock) begin
        if(core_state == EXECUTE) begin
            instruction_reg <= ram_read_data;
        end
    end

    always_comb begin
        current_instruction = instruction_reg;
        pc_next = pc + 1;

        reg_wr_enable = '0;
        reg_wr_select = '0;
        reg_wr_data = '0;

        reg_rd1_select = controls.reg_a;
        reg_rd2_select = controls.reg_b;

        ram_address = '0;
        ram_wr_enable = '0;
        ram_write_data = '0;

        alu_input_a = reg_rd1_data;

        if(core_state == FETCH) begin
            ram_address = pc;
            ram_wr_enable = 'b0;
        end

        if(core_state == EXECUTE) begin
            current_instruction = ram_read_data;
        end

        if(controls.reg_writeback && core_state == EXECUTE ||
           controls.opcode == OP_LD && core_state == TRANSFER) begin
            reg_wr_data = alu_result;
            reg_wr_select = controls.reg_destination;
            reg_wr_enable = '1;
        end

        if(controls.use_immediate) begin
            alu_input_b = controls.immediate;
        end else begin
            alu_input_b = reg_rd2_data;
        end

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
            endcase
        end

        if(controls.branch) begin
            if((controls.opcode == OP_BEQ && alu_equal) || 
               (controls.opcode == OP_BLT && alu_less_than)) begin
                    pc_next = pc + 32'($signed(controls.immediate[15:0]));
            end
        end

        if(controls.mem_read && core_state != FETCH ) begin //we can't be doing memory access during PC fetch state
            ram_address = addr_t'(reg_rd1_data + controls.immediate);
            reg_wr_data = ram_read_data;
        end

        if(controls.mem_write && core_state == TRANSFER) begin
            ram_address = reg_rd2_data + controls.immediate;
            ram_wr_enable = '1;
            ram_write_data = reg_rd1_data;
        end

        if(controls.opcode == OP_LDI) begin
            reg_wr_data = controls.immediate;
        end
    end


endmodule
