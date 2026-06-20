`timescale 1ns/1ps

module memory_watchman_tb;
    import definitions::*;

    localparam word_t ADDR_VERSION = 32'h0000_ffff;

    logic  clock = 0;
    always #5 clock = ~clock;

    logic  reset;
    cpu_core_state_t core_state;

    mem_bus_if    core_bus();
    mem_bus_if    mmap_bus();
    mmio_reader version_slot();
    mmio_reader uart_flag_slot();
    mmio_reader uart_rx_slot();

    memory_watchman dut (
        .clock          (clock),
        .reset          (reset),
        .core_state     (core_state),
        .core_bus       (core_bus),
        .mmap_bus       (mmap_bus),
        .version_slot   (version_slot),
        .uart_flag_slot (uart_flag_slot),
        .uart_rx_slot   (uart_rx_slot)
    );

    task do_reset;
        reset                  = 1;
        core_state             = FETCH;
        core_bus.address       = '0;
        core_bus.write_data    = '0;
        core_bus.write_enable  = 0;
        mmap_bus.read_data     = '0;
        version_slot.response  = '0;
        uart_flag_slot.response = '0;
        uart_rx_slot.response  = '0;
        @(posedge clock); #1;
        reset = 0;
    endtask

    task check_passthrough_read(
        input word_t addr,
        input word_t stub_mmap_data,
        input string label
    );
        core_state            = TRANSFER;
        core_bus.address      = addr;
        core_bus.write_enable = 0;
        mmap_bus.read_data    = stub_mmap_data;
        #1;
        if (mmap_bus.address !== addr)
            $fatal(1, "FAIL [%s]: mmap_bus.address not forwarded (got %08h)", label, mmap_bus.address);
        if (core_bus.read_data !== stub_mmap_data)
            $fatal(1, "FAIL [%s]: core_bus.read_data wrong (got %08h)", label, core_bus.read_data);
        if (mmap_bus.write_enable !== 0)
            $fatal(1, "FAIL [%s]: spurious mmap write enable on read", label);
    endtask

    task check_intercepted_read(
        input word_t addr,
        input word_t response,
        input string label
    );
        version_slot.response = response;
        core_bus.address      = addr;
        core_bus.write_enable = 0;
        core_state            = EXECUTE;
        @(posedge clock); #1;
        core_state = TRANSFER;
        #1;
        if (core_bus.read_data !== response)
            $fatal(1, "FAIL [%s]: expected %08h got %08h", label, response, core_bus.read_data);
        if (mmap_bus.write_enable !== 0)
            $fatal(1, "FAIL [%s]: spurious mmap write enable on intercepted read", label);
    endtask

    task check_passthrough_write(
        input word_t addr,
        input word_t data,
        input string label
    );
        core_bus.address      = addr;
        core_bus.write_data   = data;
        core_bus.write_enable = 1;
        #1;
        if (mmap_bus.address !== addr)
            $fatal(1, "FAIL [%s]: mmap_bus.address not forwarded", label);
        if (mmap_bus.write_data !== data)
            $fatal(1, "FAIL [%s]: mmap_bus.write_data not forwarded", label);
        if (mmap_bus.write_enable !== 1)
            $fatal(1, "FAIL [%s]: mmap write enable not asserted", label);
        @(posedge clock); #1;
        core_bus.write_enable = 0;
    endtask

    initial begin
        $dumpfile("build/interceptor.vcd");
        $dumpvars(0, memory_watchman_tb);

        do_reset();

        if (mmap_bus.write_enable !== 0)
            $fatal(1, "FAIL [reset]: mmap write_enable not cleared after reset");

        check_passthrough_read(32'h0000_0000, 32'hDEAD_BEEF, "passthrough r @0x000");
        check_passthrough_read(32'h0000_0100, 32'hCAFE_F00D, "passthrough r @0x100");
        check_passthrough_read(32'h0000_03FF, 32'h1234_5678, "passthrough r @0x3ff");

        check_intercepted_read(ADDR_VERSION, 32'h0000_0001, "VERSION read v1");
        check_intercepted_read(ADDR_VERSION, 32'hDEAD_C0DE, "VERSION read arbitrary response");

        check_passthrough_read(32'h0000_0050, 32'hBEEF_CAFE, "passthrough after VERSION");

        check_intercepted_read(ADDR_VERSION, 32'h0000_0001, "VERSION read again");

        check_passthrough_write(32'h0000_0010, 32'hAAAA_BBBB, "passthrough w @0x010");
        check_passthrough_write(32'h0000_0200, 32'h1111_2222, "passthrough w @0x200");

        $display("memory_watchman_tb: all checks passed");
        $finish(0);
    end

endmodule
