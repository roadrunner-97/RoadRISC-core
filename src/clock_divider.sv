module clock_divider #(
    parameter int downclock_ratio = 1
)(
    input logic in_clock,
    input logic reset,
    output logic out_clock
);
    localparam int downclock_counter_size = $clog2(downclock_ratio);

    logic[downclock_counter_size+1:0] counter;
    
    generate
        if (downclock_ratio == 1) begin
            assign out_clock = in_clock;
        end else begin
            always_ff @(posedge in_clock) begin
                if(reset) begin
                    counter <= '0;
                    out_clock <= 0;
                end else begin
                    if(counter == (downclock_ratio/2)-1) begin
                        counter <= '0;
                        out_clock <= ~out_clock;
                    end else begin
                        counter <= counter + 1;
                    end
                end
            end
        end
    endgenerate
endmodule