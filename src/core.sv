import definitions::*;

module core
(
    input logic reset,
    input logic clock,

    output logic[7:0] bus0_connector,
    output logic[7:0] bus1_connector,
    output logic[7:0] bus2_connector
);

//rom controls
    addr_t pc;
    addr_t pc_next;
    addr_t sp;
    addr_t sp_next;
    addr_t sp_next_override;
    instruction_t current_instruction;
    int_code_t exception_reason;
    decoded_instruction_t controls;

// ram controls

    addr_t ram_rd_addr;
    word_t ram_rd_data;

    addr_t ram_wr_addr;
    word_t ram_wr_data;
    logic ram_wr_enable;

    tsc_t tsc;
    tsc_t tsc_next;

    addr_t ram_wr_addr_override;
    word_t ram_wr_data_override;
    logic ram_wr_enable_override;

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

    logic idc_stalled;
    logic interrupting = '1;
    word_t reg_rd1_override;
    word_t reg_rd2_override;
    addr_t reg_wr_select_override = '0;
    word_t reg_wr_data_override = '0;
    logic reg_wr_enable_override = '0;

// interrupt wires
    wire interrupt_pin;
    logic ignore_interrupt_pin;

// io wires
    io_addr_t io_read_select;
    wire[31:0] io_read_data;

    io_addr_t io_wr_select;
    word_t io_wr_data;
    logic io_wr_enable;

    mmap #(
        .RAM_SIZE(1024),
        .FILE("src/program.hex")
    ) mmap(
        .clock(clock),
        .write_address(ram_wr_addr),
        .write_data(ram_wr_data),
        .write_enable(ram_wr_enable),
        .read_address(ram_rd_addr),
        .read_data(ram_rd_data),
        .instruction_pointer(pc),
        .instruction_data(current_instruction)
    );

    instruction_decoder idc(
        .in(current_instruction),
	.stalled(idc_stalled),
        .out(controls)
    );

    pit pit(
        .clock(clock),
	.reset(reset),
	.interrupt(interrupt_pin),
	.read_select(io_read_select),
	.read_data(io_read_data),
        .write_select(io_wr_select),
        .write_data(io_wr_data),
        .write_enable(io_wr_enable)
    );

    ioconnector ioconnector(
        .clock(clock),
	.reset(reset),
	.read_select(io_read_select),
	.read_data(io_read_data),
        .write_select(io_wr_select),
        .write_data(io_wr_data),
        .write_enable(io_wr_enable),

	.bus0_connector(bus0_connector),
	.bus1_connector(bus1_connector),
	.bus2_connector(bus2_connector)
    );

    registers registers(
        .clock(clock),
        .read_1_select(reg_rd1_select),
        .read_1_data(reg_rd1_data),
        .read_2_select(reg_rd2_select),
        .read_2_data(reg_rd2_data),
        .write_select(reg_wr_select),
        .write_data(reg_wr_data),
        .write_enable(reg_wr_enable)
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

    assign exception = controls.exception;
    cpu_core_state_t core_state;

    always_ff @(posedge clock) begin
        if(reset) begin
            pc <= RESET_ADDRRESS;
	    sp <= '0;
	    interrupting <= '0;
	    idc_stalled <= '0;
            reg_rd1_override <= '0;
            reg_rd2_override <= '0;
	    sp_next_override <= '0;
	    ram_wr_addr_override <= '0;
	    ram_wr_data_override <= '0;
	    ram_wr_enable_override <= '0;
            core_state <= FETCH;
            tsc <= '0;
            tsc_next <= '0;
	    ignore_interrupt_pin <= '0;
        end else begin
            case(core_state)
                FETCH: begin
		    	tsc <= tsc_next;
			if (controls.exception) begin // this is very repetetive
				core_state <= INTERRUPT_0;
				idc_stalled <= '1;
				interrupting <= '1;
				sp_next_override = sp - 1;
				ram_wr_addr_override = sp - 1;
				ram_wr_data_override = 32'(controls.exception_reason);
				ram_wr_enable_override = '1;
				ignore_interrupt_pin = '1;
			end else if (interrupt_pin && (ignore_interrupt_pin == '0)) begin
				core_state <= INTERRUPT_0;
				idc_stalled <= '1;
				interrupting <= '1;
				sp_next_override = sp - 1;
				ram_wr_addr_override = sp - 1;
				ram_wr_data_override = 32'(INT_HW);
				ram_wr_enable_override = '1;
				ignore_interrupt_pin = '1;
			end else begin
				core_state <= EXECUTE; // this cycle we just loaded the instruction from memory
			end
                end

                EXECUTE: begin
		    tsc_next <= tsc + 1;
                    if(controls.mem_read || controls.mem_write) begin
                        core_state <= TRANSFER;
                    end else begin
                        core_state <= FETCH;
                        pc <= pc_next;
		   	sp <= sp_next;
                    end
                end

                TRANSFER: begin // stall
                    core_state <= FETCH;
                    pc <= pc_next;
		    sp <= sp_next;
                end

		INTERRUPT_0: begin
			core_state <= INTERRUPT_1;
			sp_next_override = sp_next - 1;
			reg_rd1_override = CTRL_IVA;
			ram_wr_addr_override = sp_next - 1;
			ram_wr_data_override = 32'(pc);
			ram_wr_enable_override = '1;
			sp = sp_next;
		end

		INTERRUPT_1: begin
			core_state = EXECUTE;
			pc = reg_rd1_data;
			ram_wr_addr_override = '0;
			ram_wr_data_override = '0;
			ram_wr_enable_override = '0;
			sp = sp_next;
			idc_stalled = '0;
			interrupting = '0;
		end
            endcase
        end
    end

    always_comb begin
	pc_next = pc + 1;
	sp_next = sp;

	io_read_select = '0;

	io_wr_select = '0;
	io_wr_data = '0;
	io_wr_enable = '0;

	reg_wr_enable = '0;
	reg_wr_select = '0;
	reg_wr_data = '0;

	reg_rd1_select = controls.reg_a;
	reg_rd2_select = controls.reg_b;

	ram_rd_addr = '0;
	ram_wr_addr = '0; // wire to zero
	ram_wr_data = '0;
	ram_wr_enable = '0;

        alu_input_a = reg_rd1_data;

	if (interrupting) begin // if interrupting, then load the various overrides
		sp_next = sp_next_override;

		reg_wr_enable = reg_wr_enable_override;
		reg_wr_select = reg_wr_select_override;
		reg_wr_data = reg_wr_data_override;

		reg_rd1_select = reg_rd1_override;
		reg_rd2_select = reg_rd2_override;

		ram_wr_addr = ram_wr_addr_override;
		ram_wr_data = ram_wr_data_override;
		ram_wr_enable = ram_wr_enable_override;
	end

        if(controls.reg_writeback && core_state == EXECUTE ||
           (controls.opcode == OP_LD || controls.opcode == OP_POP) && core_state == TRANSFER) begin
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
                    reg_wr_data = pc_next;
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

        if(controls.mem_read) begin
		case (controls.opcode)
			OP_LD: begin
				ram_rd_addr = addr_t'(reg_rd1_data + controls.immediate);
				reg_wr_data = ram_rd_data;
			end

			OP_IRET: begin
				ram_rd_addr = sp + 0;
				pc_next = ram_rd_data;
				sp_next = sp + 2;
				ignore_interrupt_pin = '0;
			end

			OP_POP: begin
				ram_rd_addr = sp;
				reg_wr_data = ram_rd_data;
				sp_next = sp + 1;
			end
		endcase
        end

        if(controls.mem_write && core_state == TRANSFER) begin
		if (controls.opcode == OP_ST) begin
			ram_wr_addr = reg_rd2_data + controls.immediate;
		end else begin
			ram_wr_addr = sp - 1;
			sp_next = sp - 1;
		end
		ram_wr_enable = '1;
		ram_wr_data = reg_rd1_data;
        end

	if (controls.opcode == OP_STS) begin
	    sp = reg_rd1_data;
	end

	// reg_wr_data special cases, dedicated controls flag rather than long if ?
	if (controls.opcode == OP_LDC || controls.opcode == OP_STC || controls.opcode == OP_LDI || controls.opcode == OP_LDS) begin
		case (controls.opcode)
			OP_LDC: reg_wr_data = reg_rd1_data;
			OP_STC: reg_wr_data = reg_rd2_data;
			OP_LDI: reg_wr_data = controls.immediate;
			OP_LDS: reg_wr_data = sp;
		endcase
	end

	case (controls.opcode)
		OP_LDIO: begin
			io_read_select = reg_rd1_data;
			reg_wr_data = io_read_data;
			reg_wr_select = controls.reg_destination;
			reg_wr_enable = '0;
		end
		OP_STIO: begin
			io_wr_select = reg_rd2_data;
			io_wr_data = reg_rd1_data;
			io_wr_enable = '1;
		end
	endcase
    end


endmodule
