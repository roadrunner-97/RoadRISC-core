import definitions::*;

module version(
    input clock,
    mmio_reader.handler slot
);

assign slot.response = 32'h00010001;

endmodule
