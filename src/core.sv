import definitions::*;

module core
(
    input logic reset,
    input logic clock,
    output logic[7:0] output_byte
);

//rom controls
    addr_t pc;
    addr_t pc_next;
    instruction_t current_instruction;
    decoded_instruction_t controls;

// ram controls

    addr_t ram_rd_addr;
    word_t ram_rd_data;

    addr_t ram_wr_addr;
    word_t ram_wr_data;
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
        .ROM_SIZE(1024),
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
    assign output_byte = pc[7:0];
    always_ff @(posedge clock) begin
        if(reset) pc <= 16'hFC00;
        else pc <= pc_next;
    end

    always_comb begin
        pc_next = pc + 2;

        reg_wr_enable = '0;
        reg_wr_select = '0;
        reg_wr_data = '0;

        reg_rd1_select = controls.reg_a;
        reg_rd2_select = controls.reg_b;

        ram_rd_addr = '0;
        ram_wr_addr = '0;
        ram_wr_data = '0;
        ram_wr_enable = '0;

        alu_input_a = reg_rd1_data;

        if(controls.reg_writeback) begin
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
            pc_next = controls.immediate;
            case(controls.opcode)
                OP_JMP: begin
                    pc_next = controls.immediate;
                end
                OP_JAL: begin
                    pc_next = controls.immediate;
                    reg_wr_data = pc + 1;
                end
                OP_JREL: begin
                    pc_next += $signed(controls.immediate);
                end
            endcase
        end

        if (controls.opcode == OP_JAL) begin
            end else if (controls.opcode == OP_JREL) begin
        end

        if(controls.branch) begin
            if((controls.opcode == OP_BEQ && alu_equal) || 
               (controls.opcode == OP_BLT && alu_less_than)) begin
                    pc_next = pc + $signed(controls.immediate);
            end
        end

        if(controls.mem_read) begin
            ram_rd_addr = addr_t'(reg_rd1_data + controls.immediate);
            reg_wr_data = ram_rd_data;
        end

        if(controls.mem_write) begin
            ram_wr_addr = reg_rd1_data + controls.immediate;
            ram_wr_enable = '1;
            ram_wr_data = reg_rd2_data;
        end
    end


endmodule
