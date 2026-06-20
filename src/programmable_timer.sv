import definitions::*;

module prog_timer
(
    input logic clock,
    input logic reset,
    mmio_writer.handler direct_timer_write,
    mmio_reader.handler direct_timer_read
);

word_t direct_timer;

always_ff @(posedge clock) begin
    if(reset) begin
        direct_timer <= 0;
    end else begin
        if(direct_timer_write.write_requested) begin
            direct_timer <= direct_timer_write.payload;
        end else begin
            if(direct_timer == 0) begin
                //handle interrupt here
            end else begin
                direct_timer <= direct_timer - 1;
            end
        end
    end
end

//no statefulness needed we can always provide the time

assign direct_timer_read.response = direct_timer;
endmodule