import definitions::*;

module memory_watchman
(
    input logic clock,
    input logic reset,
    input cpu_core_state_t core_state,

    mem_bus_if.slave  core_bus,
    mem_bus_if.master mmap_bus,

    peripheral_if.watchman version_slot,
    peripheral_if.watchman uart_flag_slot,
    peripheral_if.watchman uart_rx_slot
);

    assign mmap_bus.address      = core_bus.address;
    assign mmap_bus.write_data   = core_bus.write_data;
    assign mmap_bus.write_enable = core_bus.write_enable;

    always_comb begin
        version_slot.requested   = 0;
        uart_flag_slot.requested = 0;
        uart_rx_slot.requested   = 0;
        core_bus.read_data       = mmap_bus.read_data; // default — pass through from mmap

        if (!core_bus.write_enable) begin
            if (core_state == EXECUTE) begin
                case (core_bus.address)
                    VERSION_REQUEST_ADDR:   version_slot.requested   = 1;
                    UART_FLAG_REQUEST_ADDR: uart_flag_slot.requested = 1;
                    UART_RX_REQUEST_ADDR:   uart_rx_slot.requested   = 1;
                endcase
            end

            if (core_state == TRANSFER) begin
                case (core_bus.address)
                    VERSION_REQUEST_ADDR:   core_bus.read_data = version_slot.response;
                    UART_FLAG_REQUEST_ADDR: core_bus.read_data = uart_flag_slot.response;
                    UART_RX_REQUEST_ADDR:   core_bus.read_data = uart_rx_slot.response;
                endcase
            end
        end
    end
endmodule
