import definitions::*;

// CPU ↔ memory (watchman + mmap)
interface mem_bus_if;
    addr_t address;
    word_t write_data;
    logic  write_enable;
    word_t read_data;

    modport master (output address, write_data, write_enable, input  read_data);
    modport slave  (input  address, write_data, write_enable, output read_data);
endinterface

interface mmio_transaction;
    logic read_request; //useful for ops that pop
    word_t read_response;
    logic write_request;
    word_t write_payload;

    modport originator (output read_request, input read_response, output write_request, output write_payload);
    modport handler(input read_request, output read_response, input write_request, input write_payload);
endinterface

// VGA framebuffer read port
interface vga_bus_if;
    addr_t address;
    word_t data;

    modport requester (output address, input  data);  // VGA controller
    modport provider  (input  address, output data);  // mmap / core
endinterface

// Register file read port (combinational)
interface reg_rd_if;
    reg_addr_t select;
    word_t     data;

    modport core    (output select, input  data);
    modport regfile (input  select, output data);
endinterface

// Register file write port (synchronous)
interface reg_wr_if;
    reg_addr_t select;
    word_t     data;
    logic      enable;

    modport core    (output select, data, enable);
    modport regfile (input  select, data, enable);
endinterface

// ALU operation
interface alu_if;
    word_t   input_a;
    word_t   input_b;
    opcode_t opcode;
    word_t   result;
    logic    equal;
    logic    less_than;
    logic    greater_than;

    modport core (output input_a, input_b, opcode, input  result, equal, less_than, greater_than);
    modport unit (input  input_a, input_b, opcode, output result, equal, less_than, greater_than);
endinterface
