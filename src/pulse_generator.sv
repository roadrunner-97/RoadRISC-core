module pulse_generator #(
    parameter int pulse_on_count = 1,
    parameter int pulse_off_count = 1
)(
    input logic clock,
    input logic reset,
    output logic pulse
);
    localparam int counter_size = $clog2(pulse_on_count + pulse_off_count) + 1;
    logic[counter_size:0] counter;

    always_ff @(posedge clock) begin
        if(reset) begin
            counter <= '0;
            pulse <= '1;
        end else begin
            if(counter < pulse_on_count) begin
                pulse <= '1;
                counter <= counter + 1;
            end else if (counter >= pulse_on_count && counter < (pulse_on_count + pulse_off_count - 1)) begin
                pulse <= '0;
                counter <= counter + 1;
            end else begin
                counter <= '0;
                pulse <= '0;
            end
        end
    end
endmodule