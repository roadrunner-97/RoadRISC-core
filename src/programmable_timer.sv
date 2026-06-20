import definitions::*;

module prog_timer
(
    input logic clock,
    input logic reset,
    mmio_transaction.handler direct_timer
);

word_t direct_timer_value;

always_ff @(posedge clock) begin
    if(reset) begin
        direct_timer_value <= 0;
    end else begin
        if(direct_timer.write_request) begin
            direct_timer_value <= direct_timer.write_payload;
        end else begin
            if(direct_timer_value == 0) begin
                //handle interrupt here
            end else begin
                direct_timer_value <= direct_timer_value - 1;
            end
        end
    end
end

//no statefulness needed we can always provide the time

assign direct_timer.read_response = direct_timer_value;
endmodule