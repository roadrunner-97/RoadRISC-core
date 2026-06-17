`timescale 1ns/1ps

// VGA 640×480 @ 60 Hz timing parameters verified:
//   Horizontal (800 pixels/line):  active 0-639 | front 640-655 | sync 656-751 | back 752-799
//   Vertical   (525 lines/frame):  active 0-479 | front 480-489 | sync 490-491 | back 492-524
//
// pixel_phase divides the 50 MHz clock by 2 (25 MHz pixel clock):
//   phase 0→1: hpos/vpos hold  |  phase 1→0: hpos/vpos advance
//
// Advance primitive: advance_pixels(N) requires pixel_phase=0 on entry and
// leaves it at 0 on exit.  2*N posedges = exactly N pixels.

module vga_timer_tb;

    logic       clock;
    logic       reset;
    logic [9:0] hpos;
    logic [9:0] vpos;
    logic       visible;
    logic       hsync;
    logic       vsync;
    logic       pixel_phase;

    vga_timer dut (
        .clock       (clock),
        .reset       (reset),
        .hpos        (hpos),
        .vpos        (vpos),
        .visible     (visible),
        .hsync       (hsync),
        .vsync       (vsync),
        .pixel_phase (pixel_phase)
    );

    initial clock = 0;
    always #10 clock = ~clock;  // 50 MHz

    // Advance N pixels. Requires pixel_phase=0 on entry; leaves it at 0 on exit.
    task automatic advance_pixels(input int n);
        repeat(2 * n) @(posedge clock);
        #1;
    endtask

    // Advance N complete lines (800 pixels each).
    task automatic advance_lines(input int n);
        advance_pixels(n * 800);
    endtask

    task automatic check_hpos(input int expected, input string label);
        if (hpos !== expected[9:0])
            $fatal(1, "FAIL [%s]: hpos expected %0d got %0d", label, expected, hpos);
    endtask

    task automatic check_vpos(input int expected, input string label);
        if (vpos !== expected[9:0])
            $fatal(1, "FAIL [%s]: vpos expected %0d got %0d", label, expected, vpos);
    endtask

    task automatic check_sig(input string label, input logic actual, input logic expected);
        if (actual !== expected)
            $fatal(1, "FAIL [%s]: expected %0b got %0b", label, expected, actual);
    endtask

    initial begin
        $dumpfile("build/vga_timer.vcd");
        $dumpvars(0, vga_timer_tb);

        reset = 1;
        repeat(2) @(posedge clock); #1;

        // --- Reset state: counters zeroed, pixel_phase=0, active-region signals asserted ---
        check_hpos(0, "reset hpos");
        check_vpos(0, "reset vpos");
        check_sig("reset pixel_phase", pixel_phase, 0);
        check_sig("reset visible",     visible,     1);
        check_sig("reset hsync",       hsync,       1);
        check_sig("reset vsync",       vsync,       1);

        reset = 0;

        // --- pixel_phase divides the clock by 2 ---
        // First cycle after reset: phase 0→1, hpos holds.
        @(posedge clock); #1;
        check_sig("phase rises on first cycle", pixel_phase, 1);
        check_hpos(0, "hpos stable while phase rising");

        // Second cycle: phase 1→0, hpos increments.
        @(posedge clock); #1;
        check_sig("phase falls on second cycle", pixel_phase, 0);
        check_hpos(1, "hpos advances after phase pulse");

        // pixel_phase=0, hpos=1, vpos=0 from here on.

        // --- Horizontal timing ---
        // Advance to hpos=639 (last active pixel).
        advance_pixels(638);
        check_hpos(639, "h-active last pixel");
        check_vpos(0,   "vpos unchanged during line 0");
        check_sig("visible at hpos=639",       visible, 1);
        check_sig("hsync active at hpos=639",  hsync,   1);

        // hpos=640: horizontal front porch — visible drops, hsync stays high.
        advance_pixels(1);
        check_hpos(640, "h-front-porch start");
        check_sig("visible=0 at hpos=640",    visible, 0);
        check_sig("hsync=1 in h-front-porch", hsync,   1);

        // hpos=655: last pixel of front porch.
        advance_pixels(15);
        check_hpos(655, "h-front-porch end");
        check_sig("hsync=1 at hpos=655", hsync, 1);

        // hpos=656: sync pulse — hsync goes low (active-low polarity).
        advance_pixels(1);
        check_hpos(656, "h-sync start");
        check_sig("hsync=0 at hpos=656", hsync, 0);

        // hpos=751: last pixel of sync pulse.
        advance_pixels(95);
        check_hpos(751, "h-sync end");
        check_sig("hsync=0 at hpos=751", hsync, 0);

        // hpos=752: back porch — hsync returns high.
        advance_pixels(1);
        check_hpos(752, "h-back-porch start");
        check_sig("hsync=1 at hpos=752", hsync, 1);

        // hpos=799: last pixel of the line.
        advance_pixels(47);
        check_hpos(799, "h-last pixel");
        check_vpos(0,   "vpos=0 before first line wrap");

        // Line wraps: hpos→0, vpos→1.
        advance_pixels(1);
        check_hpos(0, "hpos wraps to 0");
        check_vpos(1, "vpos increments on line wrap");
        check_sig("visible restored at line start",  visible, 1);
        check_sig("hsync restored at line start",    hsync,   1);

        // --- Vertical timing ---
        // Advance from vpos=1 to vpos=479 (last active line).
        advance_lines(478);
        check_hpos(0,   "hpos=0 after line advances");
        check_vpos(479, "v-active last line");
        check_sig("visible in last active line", visible, 1);
        check_sig("vsync during active video",   vsync,   1);

        // vpos=480: vertical front porch — visible drops, vsync stays high.
        advance_lines(1);
        check_vpos(480, "v-front-porch start");
        check_sig("visible=0 at vpos=480",    visible, 0);
        check_sig("vsync=1 in v-front-porch", vsync,   1);

        // vpos=489: last line of vertical front porch.
        advance_lines(9);
        check_vpos(489, "v-front-porch end");
        check_sig("vsync=1 at vpos=489", vsync, 1);

        // vpos=490: vsync pulse — vsync goes low.
        advance_lines(1);
        check_vpos(490, "v-sync start");
        check_sig("vsync=0 at vpos=490", vsync, 0);

        // vpos=491: second line of vsync pulse.
        advance_lines(1);
        check_vpos(491, "v-sync line 2");
        check_sig("vsync=0 at vpos=491", vsync, 0);

        // vpos=492: back porch — vsync returns high.
        advance_lines(1);
        check_vpos(492, "v-back-porch start");
        check_sig("vsync=1 at vpos=492", vsync, 1);

        // vpos=524: last line of the frame.
        advance_lines(32);
        check_vpos(524, "v-last line");

        // Frame wraps: vpos→0.
        advance_lines(1);
        check_hpos(0, "hpos=0 after frame wrap");
        check_vpos(0, "vpos wraps to 0 after frame");
        check_sig("visible=1 at (0,0) after frame wrap", visible, 1);
        check_sig("hsync=1 at start of frame",           hsync,   1);
        check_sig("vsync=1 at start of frame",           vsync,   1);

        $display("vga_timer_tb: all checks passed");
        $finish(0);
    end

endmodule
