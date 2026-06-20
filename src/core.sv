import definitions::*;

module core
(
    input logic reset,
    input logic clock,
    output word_t output_word,
    vga_bus_if.provider vga_bus,

    input logic uart_rx,
    output logic uart_tx
);

    addr_t pc;
    addr_t pc_next;

    addr_t sp;
    addr_t sp_next;

    instruction_t current_instruction;
    instruction_t instruction_reg;
    decoded_instruction_t controls;
    cpu_core_state_t core_state;

    mem_bus_if intended_bus();
    mem_bus_if actual_bus();

    reg_rd_if rd1();
    reg_rd_if rd2();
    reg_wr_if wr();

    alu_if alu_bus();

    peripheral_if version_slot();
    peripheral_if uart_flag_slot();
    peripheral_if uart_rx_slot();

    version version
    (
        .clock(clock),
        .slot(version_slot)
    );

    uart uart(
        .clock(clock),
        .reset(reset),
        .rx_pin(uart_rx),
        .tx_pin(uart_tx),
        .rx_word(uart_rx_slot),
        .flags(uart_flag_slot)
    );

    memory_watchman watchman
    (
        .clock(clock),
        .reset(reset),
        .core_state(core_state),
        .core_bus(intended_bus),
        .mmap_bus(actual_bus),
        .version_slot(version_slot),
        .uart_flag_slot(uart_flag_slot),
        .uart_rx_slot(uart_rx_slot)
    );

    mmap #(
        .RAM_SIZE(1024),
        .FILE("src/program.hex")
    ) mmap(
        .clock(clock),
        .bus(actual_bus),
        .vga_bus(vga_bus)
    );

    instruction_decoder idc(
        .in(current_instruction),
        .out(controls)
    );

    registers registers(
        .clock(clock),
        .rd1(rd1),
        .rd2(rd2),
        .wr(wr),
        .debug(output_word)
    );

    alu alu(.op(alu_bus));


    always_ff @(posedge clock) begin
        if(reset) begin
            pc <= RESET_ADDRRESS;
            core_state <= FETCH;
            sp <= 'hFFFF;
        end else begin
            case(core_state)
                FETCH: begin
                    core_state <= DECODE;
                end

                DECODE: begin
                    core_state <= EXECUTE;
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

    always_ff @(posedge clock) begin
        if(core_state == DECODE)
            /* we're not using the intended_bus here which kinda breaks the mental model of the 
            memory watchman as a gobetween for the memory and the core, but it breaks a big combinatorial loop that
            reduces max frequency on hardware, and since instructions can't come directly from peripherals this is ok */
            instruction_reg <= actual_bus.read_data;
    end

    always_comb begin
        current_instruction = instruction_reg;
        pc_next = pc + 1;
        sp_next = sp;

        wr.enable = '0;
        wr.select = controls.reg_destination;
        wr.data   = '0;

        rd1.select = controls.reg_a;
        rd2.select = controls.reg_b;

        intended_bus.address      = '0;
        intended_bus.write_data   = '0;
        intended_bus.write_enable = '0;

        alu_bus.input_a = rd1.data;
        alu_bus.input_b = controls.use_immediate ? controls.immediate : rd2.data;
        alu_bus.opcode  = controls.opcode;

        case(core_state)
            FETCH: begin
                intended_bus.address = pc; // fetching the instruction means we're pointing at the PC
            end

            DECODE: begin
                // instruction_reg is being captured this cycle, nothing done here
            end

            EXECUTE: begin
                // only writeback to registers during the execute cycle
                // (so we don't do it again in the transfer cycle)
                if(controls.reg_writeback) begin
                    wr.enable = '1;
                    wr.data   = alu_bus.result;
                end
            end

            TRANSFER: begin
                if(controls.opcode == OP_LD)  wr.enable = '1;
                if(controls.opcode == OP_POP) wr.enable = '1;

                if(controls.opcode == OP_ST) begin
                    intended_bus.address      = rd2.data + controls.immediate;
                    intended_bus.write_enable = '1;
                    intended_bus.write_data   = rd1.data;
                end

                if(controls.opcode == OP_PUSH) begin
                    intended_bus.address      = sp - 1;
                    intended_bus.write_enable = '1;
                    intended_bus.write_data   = rd1.data;
                end

                if(controls.opcode == OP_CALL) begin
                    intended_bus.address      = sp - 1;
                    intended_bus.write_enable = '1;
                    intended_bus.write_data   = pc + 1;
                end

                if(controls.opcode == OP_RET) begin
                    intended_bus.address = sp;
                    pc_next              = intended_bus.read_data;
                    sp_next              = sp + 1;
                end
            end
        endcase

        // jumping commands
        if(controls.jump) begin
            case(controls.opcode)
                OP_JMP:  pc_next = controls.immediate;
                OP_JAL: begin
                    pc_next = controls.immediate;
                    wr.data = pc + 1;
                end
                OP_JREL: pc_next = pc + 32'($signed(controls.immediate[15:0]));
                OP_CALL: pc_next = pc + 32'($signed(controls.immediate[15:0]));
            endcase
        end

        // branching commands
        if(controls.branch) begin
            if((controls.opcode == OP_BEQ  && alu_bus.equal)        ||
               (controls.opcode == OP_BLT  && alu_bus.less_than)    ||
               (controls.opcode == OP_BNEQ && ~alu_bus.equal)       ||
               (controls.opcode == OP_BGT  && alu_bus.greater_than)) begin
                pc_next = pc + 32'($signed(controls.immediate[15:0]));
            end
        end

        if(controls.mem_read && core_state == EXECUTE) begin
            if(controls.opcode == OP_LD) begin
                intended_bus.address = addr_t'(rd1.data + controls.immediate);
            end else if (controls.opcode == OP_POP) begin
                intended_bus.address = sp;
                sp_next              = sp + 1;
            end else if (controls.opcode == OP_RET) begin
                intended_bus.address = sp;
            end
        end

        if(controls.mem_read && core_state == TRANSFER) begin
            wr.data = intended_bus.read_data;
        end

        if(controls.mem_write && core_state != FETCH) begin
            if(controls.opcode == OP_PUSH ||
               controls.opcode == OP_CALL) begin
                sp_next = sp - 1;
            end
        end

        if(controls.opcode == OP_LDI) wr.data = controls.immediate;
        if(controls.opcode == OP_STS) sp_next  = rd1.data;
        if(controls.opcode == OP_LDS) wr.data  = sp;
        if(controls.halt)             pc_next  = pc;
    end

endmodule
