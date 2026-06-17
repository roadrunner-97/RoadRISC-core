import definitions::*;

module version(
    input clock,
    peripheral_if.peripheral slot
);

always_ff @(posedge clock) begin
    if (slot.requested) slot.response <= 32'hF00F;
    else                slot.response <= '0;
end

endmodule
