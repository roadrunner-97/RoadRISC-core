// Drives a byte onto a PMOD header wired to an 8-LED bar.
//
// Two board quirks are corrected here so any PMOD can be used as a plain
// binary output:
//   - the connector swaps each adjacent pair of wires (bit0<->bit1,
//     bit2<->bit3, ...), so undo that, and
//   - the LEDs are active-low, so invert.
//
// Purely combinational.
module pmod_led_conversion(
    input  logic [7:0] value,
    output logic [7:0] pmod
);
    always_comb begin
        pmod = ~{value[6], value[7],
                 value[4], value[5],
                 value[2], value[3],
                 value[0], value[1]};
    end
endmodule
