import definitions::*;

module version(
    input clock,
    peripheral_if.peripheral slot
);

assign slot.response = 32'hF00F;

endmodule
