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
	OP_LDC  = 8'h18, // for roadrunner: load control
	OP_STC  = 8'h19, // for roadrunner: store control
	OP_LDS  = 8'h1A, // for roadrunner: load stack
	OP_STS  = 8'h1B, // for roadrunner: store stack
	OP_PUSH = 8'h1C,
	OP_POP  = 8'h1D,
	OP_IRET = 8'h1E,
	OP_LDIO = 8'h1F, // for roadrunner: load I/O
	OP_STIO = 8'h20, // for roadrunner: store I/O
        OP_HALT = 8'hFF
    } opcode_t;

    // control registers
    typedef enum logic [7:0] {
        CTRL_IVA  = 8'h10,
        CTRL_IVR  = 8'h11,
        CTRL_IVO  = 8'h12
    } ctrl_regs_t;

    // interrupt reasons
    typedef enum logic [7:0] {
        INT_HW = 8'h00,
        INT_EXCEPTION_INJECTED = 8'h80,
        INT_EXCEPTION_DECODER_ERROR = 8'hfe,
        INT_EXCEPTION_UNKNOWN_OPCODE = 8'hff
    } int_code_t;

    typedef enum logic[4:0]{
        FETCH, /*fetch the instruction pointed to by the PC */
        EXECUTE,/*decode the current instruction now fetched */
        TRANSFER, /*some operations require an extra cycle to interact with memory once decoded */

	EXCEPTION, // exception state (copy exception reason to ivr)
	HARDWARE_INTERUPT, // hardware interrupt (write hw reason to ivr)
	INTERRUPT_0, // yet-to-be named interruption states
	INTERRUPT_1,
	INTERRUPT_2,
	INTERRUPT_3,
	INTERRUPT_4
    } cpu_core_state_t;

    localparam int RAM_SIZE = 32768; /* in units of kilowords */
    localparam int REG_COUNT = 24;
    localparam int GPR_COUNT = 16;
    localparam int RAM_WIDTH = 32;

    localparam int RESET_ADDRRESS = 32'h0000;


    typedef logic [RAM_WIDTH-1:0] addr_t;

    // word and register types
    typedef logic [31:0] word_t;
    typedef logic [$clog2(REG_COUNT)-1:0]  reg_addr_t;
    typedef logic [$clog2(GPR_COUNT)-1:0]  insr_reg_addr_t;
    typedef logic [31:0] tsc_t;

    // instruction fields (unpacked from a 32-bit instruction word)
    typedef struct packed {
        opcode_t     opcode;
        insr_reg_addr_t   reg_destination;
        insr_reg_addr_t   reg_a;
        union packed {
            struct packed {
                insr_reg_addr_t   rb;
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

        logic[15:0] immediate;
	int_code_t exception_reason;
        logic      use_immediate;
        logic      mem_read;
        logic      mem_write;
        logic      reg_writeback;
        logic      branch;
        logic      jump;
        logic      halt;
	logic      exception;
    } decoded_instruction_t;

// I/O bus
    typedef logic [31:0] io_addr_t;
    typedef logic [31:0] io_data_t;

// PIT
    localparam int PIT_REGISTER_COUNT = 2;
    localparam int PIT_FLAG_ACTIVE = 'b01;
    localparam int PIT_FLAG_INTERRUPTING = 'b10;
    localparam int PIT_IO_BASE = 32'h00000;
    localparam int PIT_IO_END = 32'h00002;
    typedef logic[1:0] pit_reg_t;

    typedef enum logic [7:0] {
        PIT_FLAG     = 8'h00,
        PIT_DEADLINE = 8'h01
    } pit_regs_t;
    
// I/O connector
    localparam int IOCONNECTOR_BASE = 32'h0008;
    localparam int IOCONNECTOR_BASE_END = 32'h000c;

endpackage
