module top (
    input  logic       clk,
    input  logic       rst,
    output logic [7:0] pmod0,
    output logic [7:0] pmod1,
    output logic [7:0] pmod2
);

    core core(
        .clock(clk),
        .reset(rst),
        .output_byte(pmod0)
    );
 
//    logic [26:0] divider;
//    logic [7:0]  count;
// 
//    always_ff @(posedge clk) begin
//        if (!rst) begin
//            divider <= '0;
//            count   <= '0;
//        end else begin
//            if (divider == 27'd49_999_999) begin
//                divider <= '0;
//                count   <= count + 1;
//            end else begin
//                divider <= divider + 1;
//            end
//        end
//    end
// 
//    assign pmod0 = count;
    assign pmod1 = '0;
    assign pmod2 = '0;
 
endmodule
 
