package definitions;

    // instruction opcodes
    typedef enum logic [7:0] {
        OP_ADD  = 8'h01,
        OP_SUB  = 8'h02,
        OP_AND  = 8'h03,
        OP_OR   = 8'h04,
        OP_XOR  = 8'h05,
        OP_SHL  = 8'h06,
        OP_SHR  = 8'h07,
        OP_ADDI = 8'h11,
        OP_LUI  = 8'h12,
        OP_LD   = 8'h20,
        OP_ST   = 8'h21,
        OP_BEQ  = 8'h30,
        OP_BLT  = 8'h31,
        OP_JMP  = 8'h32,
        OP_JAL  = 8'h33,
        OP_HALT = 8'hFF
    } opcode_t;

    localparam int RAM_SIZE = 256;
    localparam int ROM_SIZE = 256;

    typedef logic [$clog2(RAM_SIZE)-1:0] ram_addr_t;
    typedef logic [$clog2(ROM_SIZE)-1:0] rom_addr_t;

    // word and register types
    typedef logic [63:0] word_t;
    typedef logic [3:0]  reg_addr_t;
    typedef logic [7:0]  opcode_raw_t;
    typedef logic [43:0] immediate_t;

    // instruction fields (unpacked from a 64-bit instruction word)
    typedef struct packed {
        opcode_t     opcode;
        reg_addr_t   reg_destination;
        reg_addr_t   reg_a;
        reg_addr_t   reg_b;
        immediate_t  immediate;
    } instruction_t;

    typedef struct packed {
        opcode_t   opcode;
        reg_addr_t reg_destination;
        reg_addr_t reg_a;
        reg_addr_t reg_b;
        word_t     immediate;
        logic      use_immediate;
        logic      mem_read;
        logic      mem_write;
        logic      reg_writeback;
        logic      branch;
        logic      jump;
        logic      halt;
    } decoded_instruction_t;

    // CPU parameters
    localparam int REG_COUNT = 16;

endpackage