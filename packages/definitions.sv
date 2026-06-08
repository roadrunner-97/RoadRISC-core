package definitions;

    // instruction opcodes
    typedef enum logic [7:0] {
        OP_NOP  = 8'h00,
        OP_ADD  = 8'h02,
        OP_ADDI = 8'h03,
        OP_SUB  = 8'h04,
        OP_SUBI = 8'h05,
        OP_AND  = 8'h06,
        OP_ANDI = 8'h07,
        OP_OR   = 8'h08,
        OP_ORI  = 8'h09,
        OP_XOR  = 8'h0A,
        OP_XORI = 8'h0B,
        OP_SHL  = 8'h0C,
        OP_SHLI = 8'h0D,
        OP_SHR  = 8'h0E,
        OP_SHRI = 8'h0F,
        OP_LD   = 8'h10,
        OP_ST   = 8'h11,
        OP_BEQ  = 8'h12,
        OP_BLT  = 8'h13,
        OP_JMP  = 8'h14,
        OP_JAL  = 8'h15,
        OP_JREL = 8'h16,
        OP_HALT  = 8'hFF
    } opcode_t;

    localparam int RAM_SIZE = 1024;
    localparam int ROM_SIZE = 1024;
    localparam int REG_COUNT = 16;
    localparam int RAM_WIDTH = 16;
    localparam int ROM_START = 65536 - ROM_SIZE;


    typedef logic [RAM_WIDTH-1:0] addr_t;

    // word and register types
    typedef logic [15:0] word_t;
    typedef logic [$clog2(REG_COUNT)-1:0]  reg_addr_t;

    // instruction fields (unpacked from a 64-bit instruction word)
    typedef struct packed {
        opcode_t     opcode;
        reg_addr_t   reg_destination;
        reg_addr_t   reg_a;
        union packed {
            struct packed {
                reg_addr_t   rb;
                logic [11:0] unused;
            } r;
            logic [15:0] imm;
        } operand;
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

endpackage