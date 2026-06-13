module top (
    input  logic       clk,
    input  logic       rst,
    output logic [7:0] pmod0,
    output logic [7:0] pmod1,
    output logic [7:0] pmod2
);

    core core(
        .reset(rst),
        .clock(clk),
        .bus0_connector(pmod2),
        .bus1_connector(pmod1),
        .bus2_connector(pmod0)
    );

//assign' pmod0 = 'b01010101;

endmodule