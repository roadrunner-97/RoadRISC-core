import definitions::*;

module pit(
    input logic clock, // clock pin
    input logic reset,

    input io_addr_t read_select,
    output wire[31:0] read_data,

    input io_addr_t write_select,
    input word_t write_data,
    input logic write_enable,

    output wire interrupt // interrupt pin
);

// oughgh theres a way betterway to do all of this im so fat and lazy this only sorta made sense for the tsc deadline
    word_t flags, deadline;

    pit_reg_t reg_wr_select;
    pit_reg_t reg_rd_select;
    logic wr_addr_matched;
    logic rd_addr_matched;
    word_t count;
    logic deadline_active;

    word_t _read_data;

    assign interrupt = (flags & PIT_FLAG_INTERRUPTING) ? '1 : 'Z;
    assign read_data = rd_addr_matched ? _read_data : 'Z;

    always_ff @(posedge clock) begin
	if (reset) begin
		count <= '0;
		flags <= '0;
		deadline <= '0;
		deadline_active <= '0;
		reg_wr_select <= '0;
		reg_rd_select <= '0;
		wr_addr_matched <= '0;
		rd_addr_matched <= '0;
    	end else begin
		count <= count + 1;
		reg_wr_select = write_select - PIT_IO_BASE;
		reg_rd_select = read_select - PIT_IO_BASE;
		wr_addr_matched = write_select >= PIT_IO_BASE && write_select < PIT_IO_END;
		rd_addr_matched = read_select >= PIT_IO_BASE && read_select < PIT_IO_END;

		if (flags & PIT_FLAG_ACTIVE && count == deadline) begin
			flags = PIT_FLAG_INTERRUPTING;
		end

		if (wr_addr_matched && write_enable) begin
			if (reg_wr_select == PIT_DEADLINE) begin
				deadline = write_data + count;
			end else begin
				flags = write_data;
			end
		end

		if (rd_addr_matched) begin
			if (reg_rd_select == PIT_DEADLINE) begin
				_read_data = deadline;
			end else begin
				_read_data = flags;
			end
		end
	end
    end
endmodule
