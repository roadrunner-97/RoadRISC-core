import definitions::*;

module version(
    input clock,
    mmio_transaction.handler slot
);

assign slot.read_response = 32'h00010001;

endmodule
