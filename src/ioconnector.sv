import definitions::*;

module ioconnector(
    input logic clock, // clock pin
    input logic reset,

    input io_addr_t read_select,
    output wire[31:0] read_data,

    input io_addr_t write_select,
    input word_t write_data,
    input logic write_enable,

    output logic[7:0] bus0_connector,
    output logic[7:0] bus1_connector,
    output logic[7:0] bus2_connector
);

	logic[3:0] reg_wr_select;
	logic[3:0] reg_rd_select;
	logic wr_addr_matched;
	logic rd_addr_matched;
	word_t _read_data;
	assign read_data = rd_addr_matched ? _read_data : 'Z;
	always_ff @(posedge clock) begin
		reg_wr_select = write_select - IOCONNECTOR_BASE;
		reg_rd_select = read_select - IOCONNECTOR_BASE;
		wr_addr_matched = write_select >= IOCONNECTOR_BASE && write_select < IOCONNECTOR_BASE_END;
		rd_addr_matched = read_select >= IOCONNECTOR_BASE && read_select < IOCONNECTOR_BASE_END;
		if (wr_addr_matched && write_enable) begin
			case (reg_wr_select)
				0: bus0_connector <= write_data;
				1: bus1_connector <= write_data;
				2: bus2_connector <= write_data;
			endcase
		end
		if (rd_addr_matched) begin
			case (reg_wr_select)
				0: _read_data <= bus0_connector;
				1: _read_data <= bus1_connector;
				2: _read_data <= bus2_connector;
			endcase
		end
	end
endmodule
