module edge_detector(
    input logic clock,
    input logic in,
    output logic out_posedge,
    output logic out_negedge
);
    logic in_history;
    initial in_history = 0;

    always_ff @(posedge clock) begin
        in_history <= in;
        if(in_history == in) begin
            out_posedge <= 0;
            out_negedge <= 0;
        end else if (!in_history && in) begin
            out_posedge <= 1;
            out_negedge <= 0;
        end else if (in_history && !in) begin
            out_negedge <= 1;
            out_posedge <= 0;
        end
    end
endmodule