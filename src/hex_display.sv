module hex_display(
    input logic reset,
    input logic clock,
    input logic[7:0] data,
    input logic[1:0] display_blank,
    output logic[6:0] segments,
    output logic segment_select
);
