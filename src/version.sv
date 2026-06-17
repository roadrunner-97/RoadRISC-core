import definitions::*;

module version(
    input clock,
    input version_requested,
    output word_t version_data
);

always_ff @(posedge clock) begin
    if (version_requested) version_data <= 32'hF00F;
    else                   version_data <= '0;
end

endmodule