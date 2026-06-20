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
        OP_LDI  = 8'h17,
        OP_BNEQ = 8'h18,
        OP_BGT  = 8'h19,
        OP_LDS  = 8'h1A,
        OP_STS  = 8'h1B,
        OP_PUSH = 8'h1C,
        OP_POP  = 8'h1D,
        OP_CALL = 8'h1E,
        OP_RET  = 8'h1F,
        OP_MUL  = 8'h42,
        OP_MULU = 8'h43,
        OP_MULL = 8'h44,
        OP_HALT  = 8'hFF
    } opcode_t;

    typedef enum logic[1:0]{
        FETCH, /*fetch the instruction pointed to by the PC */
        DECODE, /*latch the instruction and turn it into control signals */
        EXECUTE,/*do register and ALU based operations */
        TRANSFER /*some operations require an extra cycle to interact with memory once decoded */
    } cpu_core_state_t;

    localparam int RAM_SIZE = 32768; /* in units of kilowords */
    localparam int REG_COUNT = 16;
    localparam int RAM_WIDTH = 32;

    localparam int RESET_ADDRRESS = 16'h0000;


    typedef logic [RAM_WIDTH-1:0] addr_t;

    // word and register types
    typedef logic [31:0] word_t;
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
        logic[15:0] immediate; //fix
        logic      use_immediate;
        logic      mem_read;
        logic      mem_write;
        logic      reg_writeback;
        logic      branch;
        logic      jump;
        logic      halt;
    } decoded_instruction_t;

    localparam int VERSION_REQUEST_ADDR = 16'hFFFF;

    localparam int UART_FLAG_REQUEST_ADDR = 16'hFFF0;
    localparam int UART_RX_REQUEST_ADDR = 16'hFFF1;

    localparam int TIMER_ADDR = 16'hFF00;

endpackage
