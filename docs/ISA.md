# roadrunner CPU ISA
# instruction format: [63:56] opcode | [55:52] Rd | [51:48] Ra | [47:44] Rb | [43:0] imm
# R0 is hardwired to zero both for reading and writing
# branches are PC-relative (signed immediate offset)

# ALU register only
ADD  0x01   Rd = Ra + Rb
SUB  0x02   Rd = Ra - Rb
AND  0x03   Rd = Ra & Rb
OR   0x04   Rd = Ra | Rb
XOR  0x05   Rd = Ra ^ Rb
SHL  0x06   Rd = Ra << Rb
SHR  0x07   Rd = Ra >> Rb (unsigned)

# ALU immediates
ADDI 0x11   Rd = Ra + imm
LUI  0x12   Rd = imm << 20

# memory
LD   0x20   Rd = mem[Ra + imm]
ST   0x21   mem[Ra + imm] = Rb ,  Rd unused

# control flow
BEQ  0x30   if Ra == Rb: PC += imm    signed offset, in instructions
BLT  0x31   if Ra < Rb:  PC += imm    unsigned comparison
JMP  0x32   PC = imm                  absolute address
JAL  0x33   Rd = PC + 1; PC = imm     Rd holds return address
HALT 0xFF   stop execution