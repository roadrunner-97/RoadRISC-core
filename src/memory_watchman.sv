import definitions::*;

module memory_watchman
(
    input logic clock,
    input logic reset,
    //just makes it easier to know what the core is up to
    input cpu_core_state_t core_state,

    input word_t core_address,
    input word_t core_write_data,
    output word_t core_read_data,
    input logic core_write_enable,

    output word_t mmap_address,
    output word_t mmap_write_data,
    input word_t mmap_read_data,
    output logic mmap_write_enable,

//version request flag
    output logic version_command_requested,
    input word_t version_command_response,

//uart flag word
    output logic uart_flag_requested,
    input word_t uart_flag_response,

//uart rx word
    output logic uart_rx_word_requested,
    input word_t uart_rx_word_response
);



  assign mmap_address      = core_address;
  assign mmap_write_data   = core_write_data;
  assign mmap_write_enable = core_write_enable;




  always_comb begin
      version_command_requested  = 0;
      uart_flag_requested        = 0;
      uart_rx_word_requested     = 0;
      core_read_data             = mmap_read_data; // default — no dependency on core_address

      if (!core_write_enable) begin
          if (core_state == EXECUTE) begin
              case (core_address)
                  VERSION_REQUEST_ADDR:   version_command_requested = 1;
                  UART_FLAG_REQUEST_ADDR: uart_flag_requested = 1;
                  UART_RX_REQUEST_ADDR:   uart_rx_word_requested = 1;
              endcase
          end

          if (core_state == TRANSFER) begin
              case (core_address)
                  VERSION_REQUEST_ADDR:   core_read_data = version_command_response;
                  UART_FLAG_REQUEST_ADDR: core_read_data = uart_flag_response;
                  UART_RX_REQUEST_ADDR:   core_read_data = uart_rx_word_response;
              endcase
          end
      end
  end
endmodule