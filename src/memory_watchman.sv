import definitions::*;

module memory_watchman
(
    input logic clock,
    input logic reset,
    input cpu_core_state_t core_state,

    mem_bus_if.slave  core_bus,
    mem_bus_if.master mmap_bus,

    mmio_transaction.originator version_slot,
    mmio_transaction.originator uart_flag_slot,
    mmio_transaction.originator uart_rx_slot,

    mmio_transaction.originator direct_timer
);

    assign mmap_bus.address      = core_bus.address;
    assign mmap_bus.write_data   = core_bus.write_data;
    assign mmap_bus.write_enable = core_bus.write_enable;

    // Latch the address at end of EXECUTE so the TRANSFER peripheral compare
    // starts from a FF rather than the full recomputed address chain.
    // Mirrors what the MMAP BSRAM already does internally with its registered read.
    addr_t latched_address;
    always_ff @(posedge clock) begin
        if (core_state == EXECUTE) latched_address <= core_bus.address;
    end

    always_comb begin
        version_slot.read_request   = 0;
        version_slot.write_request   = 0;

        uart_flag_slot.read_request = 0;
        uart_flag_slot.write_request = 0;

        uart_rx_slot.read_request   = 0;
        uart_rx_slot.write_request   = 0;

        direct_timer.read_request = 0;
        direct_timer.write_request = 0;

        core_bus.read_data = mmap_bus.read_data; // default — pass through from mmap
        if (core_state == TRANSFER) begin
            if (!core_bus.write_enable) begin
                case (latched_address)
                    VERSION_REQUEST_ADDR: begin
                        version_slot.read_request = 1;
                        core_bus.read_data = version_slot.read_response;
                    end
                    UART_FLAG_REQUEST_ADDR: begin
                        uart_flag_slot.read_request = 1;
                        core_bus.read_data = uart_flag_slot.read_response;
                    end
                    UART_RX_REQUEST_ADDR: begin
                        uart_rx_slot.read_request = 1;
                        core_bus.read_data = uart_rx_slot.read_response;
                    end
                    TIMER_ADDR: begin
                        direct_timer.read_request = 1;
                        core_bus.read_data = direct_timer.read_response;
                    end
                endcase

            end else begin

                //in this caser we know we're in transfer and write enable is high
                case(core_bus.address)
                    TIMER_ADDR: begin
                        direct_timer.write_request = 1;
                        direct_timer.write_payload = core_bus.write_data;
                    end
                endcase
            end
        end
    end
endmodule
