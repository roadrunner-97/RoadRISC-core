# 32-bit instruction, 16-bit data
# [31:24] opcode | [23:20] Rd | [19:16] Ra | [15:12] Rb  (R-type)
#                                          | [15:0]  imm (I-type)
# opcode[0] == 1 → immediate operand

# special
0x00  NOP                    no operation
0xFF  HALT                   stop execution

# ALU — register
0x02  ADD   Rd, Ra, Rb       Rd = Ra + Rb
0x04  SUB   Rd, Ra, Rb       Rd = Ra - Rb
0x06  AND   Rd, Ra, Rb       Rd = Ra & Rb
0x08  OR    Rd, Ra, Rb       Rd = Ra | Rb
0x0A  XOR   Rd, Ra, Rb       Rd = Ra ^ Rb
0x0C  SHL   Rd, Ra, Rb       Rd = Ra << Rb
0x0E  SHR   Rd, Ra, Rb       Rd = Ra >> Rb  logical, no sign extension

# ALU — immediate
0x03  ADDI  Rd, Ra, #imm     Rd = Ra + imm
0x05  SUBI  Rd, Ra, #imm     Rd = Ra - imm
0x07  ANDI  Rd, Ra, #imm     Rd = Ra & imm
0x09  ORI   Rd, Ra, #imm     Rd = Ra | imm
0x0B  XORI  Rd, Ra, #imm     Rd = Ra ^ imm
0x0D  SHLI  Rd, Ra, #imm     Rd = Ra << imm
0x0F  SHRI  Rd, Ra, #imm     Rd = Ra >> imm  logical

# memory
0x10  LD    Rd, Ra, #imm     Rd = mem[Ra + imm]
0x11  ST    Ra, Rb, #imm     mem[Ra + imm] = Rb

# control flow
0x12  BEQ   Ra, Rd, #imm     if Ra == Rd: PC += imm  signed, PC-relative
0x13  BLT   Ra, Rd, #imm     if Ra < Rd:  PC += imm  unsigned comparison
0x14  JMP   #imm             PC = imm  absolute
0x15  JAL   Rd, #imm         Rd = PC+1; PC = imm  Rd holds return address