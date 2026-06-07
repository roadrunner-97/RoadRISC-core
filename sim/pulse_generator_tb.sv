`timescale 1ns/1ps

module pulse_generator_tb;
    reg clock;
    reg reset;
    wire pulse1;
    wire pulse2;
    wire pulse3;
    wire pulse4;

    pulse_generator 
        #(.pulse_on_count(1), .pulse_off_count(1)) dut1(
            .clock(clock),
            .reset(reset),
            .pulse(pulse1)
        );

    pulse_generator
        #(.pulse_on_count(1), .pulse_off_count(2)) dut2(
            .clock(clock),
            .reset(reset),
            .pulse(pulse2)
        );
    
    pulse_generator
        #(.pulse_on_count(1), .pulse_off_count(4)) dut3(
            .clock(clock),
            .reset(reset),
            .pulse(pulse3)
        );
    
    pulse_generator
        #(.pulse_on_count(4), .pulse_off_count(1)) dut4(
            .clock(clock),
            .reset(reset),
            .pulse(pulse4)
        );


    initial begin
        $dumpfile("build/pulse_generator.vcd");
        $dumpvars(0, pulse_generator_tb);

        clock <= 0;
        reset <= 0;
        #10 reset <= 1;
        #10 reset <=0;
        repeat(200) @(posedge clock);
        $finish;
    end

    always begin
        #10 clock <= ~clock;
    end
endmodule