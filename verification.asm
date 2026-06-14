; verification test suite
; r15 holds current test number; on failure we halt with it set so you know which test broke
; all tests pass when r15 == 0x001C (last test number) at halt

test_1:
    mov r15, 0x0001 ; NOP: must not crash or corrupt state
    nop

test_2:
    mov r15, 0x0002 ; ADD: 0xAB00 + 0x00CD == 0xABCD
    mov r0, 0xAB00
    mov r1, 0x00CD
    mov r2, 0xABCD
    add r3, r0, r1
    bneq r2, r3, fail

test_3:
    mov r15, 0x0003 ; SUB: 0xCDEF - 0xCD00 == 0x00EF
    mov r0, 0xCDEF
    mov r1, 0xCD00
    mov r2, 0x00EF
    sub r3, r0, r1
    bneq r2, r3, fail

test_4:
    mov r15, 0x0004 ; AND: 0xF0F0 & 0xFF00 == 0xF000
    mov r0, 0xF0F0
    mov r1, 0xFF00
    mov r2, 0xF000
    and r3, r0, r1
    bneq r2, r3, fail

test_5:
    mov r15, 0x0005 ; OR: 0xF000 | 0x0F00 == 0xFF00
    mov r0, 0xF000
    mov r1, 0x0F00
    mov r2, 0xFF00
    or r3, r0, r1
    bneq r2, r3, fail

test_6:
    mov r15, 0x0006 ; XOR: 0xFF00 ^ 0x0FF0 == 0xF0F0
    mov r0, 0xFF00
    mov r1, 0x0FF0
    mov r2, 0xF0F0
    xor r3, r0, r1
    bneq r2, r3, fail

test_7:
    mov r15, 0x0007 ; SHL: 0x0001 << 4 == 0x0010
    mov r0, 0x0001
    mov r1, 0x0004
    mov r2, 0x0010
    shl r3, r0, r1
    bneq r2, r3, fail

test_8:
    mov r15, 0x0008 ; SHR: 0x0100 >> 4 == 0x0010
    mov r0, 0x0100
    mov r1, 0x0004
    mov r2, 0x0010
    shr r3, r0, r1
    bneq r2, r3, fail

test_9:
    mov r15, 0x0009 ; ADDI: 0x1234 + 0x000C == 0x1240
    mov r0, 0x1234
    mov r2, 0x1240
    add r3, r0, 0x000C
    bneq r2, r3, fail

test_10:
    mov r15, 0x000A ; SUBI: 0x1234 - 0x0010 == 0x1224
    mov r0, 0x1234
    mov r2, 0x1224
    sub r3, r0, 0x0010
    bneq r2, r3, fail

test_11:
    mov r15, 0x000B ; ANDI: 0xABCD & 0x00FF == 0x00CD
    mov r0, 0xABCD
    mov r2, 0x00CD
    and r3, r0, 0x00FF
    bneq r2, r3, fail

test_12:
    mov r15, 0x000C ; ORI: 0xAB00 | 0x00FF == 0xABFF
    mov r0, 0xAB00
    mov r2, 0xABFF
    or r3, r0, 0x00FF
    bneq r2, r3, fail

test_13:
    mov r15, 0x000D ; XORI: 0xFFFF ^ 0x00FF == 0xFF00
    mov r0, 0xFFFF
    mov r2, 0xFF00
    xor r3, r0, 0x00FF
    bneq r2, r3, fail

test_14:
    mov r15, 0x000E ; SHLI: 0x0001 << 3 == 0x0008
    mov r0, 0x0001
    mov r2, 0x0008
    shl r3, r0, 3
    bneq r2, r3, fail

test_15:
    mov r15, 0x000F ; SHRI: 0x0080 >> 3 == 0x0010
    mov r0, 0x0080
    mov r2, 0x0010
    shr r3, r0, 3
    bneq r2, r3, fail

test_16:
    mov r15, 0x0010 ; LDI: load 0xBEEF
    mov r3, 0xBEEF
    mov r2, 0xBEEF
    bneq r2, r3, fail

test_17:
    mov r15, 0x0011 ; ST + LD: round-trip to address 0x0200
    mov r0, 0x0200
    mov r1, 0xDEAD
    mov [r0], r1
    mov r3, [r0]
    bneq r1, r3, fail

test_18:
    mov r15, 0x0012 ; BEQ taken: 0x1234 == 0x1234 must branch
    mov r0, 0x1234
    mov r1, 0x1234
    beq r0, r1, beq_taken_ok
    jmp fail
beq_taken_ok:

test_19:
    mov r15, 0x0013 ; BEQ not taken: 0x1234 != 0x5678 must not branch
    mov r0, 0x1234
    mov r1, 0x5678
    beq r0, r1, fail

test_20:
    mov r15, 0x0014 ; BNEQ taken: 0x1234 != 0x5678 must branch
    mov r0, 0x1234
    mov r1, 0x5678
    bneq r0, r1, bneq_taken_ok
    jmp fail
bneq_taken_ok:

test_21:
    mov r15, 0x0015 ; BNEQ not taken: 0x1234 == 0x1234 must not branch
    mov r0, 0x1234
    mov r1, 0x1234
    bneq r0, r1, fail

; BLT/BGT note: `blt X, Y` branches when Y < X (Ra < Rd; Ra=second arg, Rd=first arg)
test_22:
    mov r15, 0x0016 ; BLT taken: r1(0x0002) < r0(0x0005)
    mov r0, 0x0005
    mov r1, 0x0002
    blt r0, r1, blt_taken_ok
    jmp fail
blt_taken_ok:

test_23:
    mov r15, 0x0017 ; BLT not taken: r1(0x0005) < r0(0x0002) is false
    mov r0, 0x0002
    mov r1, 0x0005
    blt r0, r1, fail

test_24:
    mov r15, 0x0018 ; BGT taken: r1(0x0005) > r0(0x0002)
    mov r0, 0x0002
    mov r1, 0x0005
    bgt r0, r1, bgt_taken_ok
    jmp fail
bgt_taken_ok:

test_25:
    mov r15, 0x0019 ; BGT not taken: r1(0x0002) > r0(0x0005) is false
    mov r0, 0x0005
    mov r1, 0x0002
    bgt r0, r1, fail

test_26:
    mov r15, 0x001A ; JMPABS: absolute jump must skip halt
    jmpabs jmpabs_ok
    halt
jmpabs_ok:

test_27:
    mov r15, 0x001B ; JREL: relative jump must skip halt
    jrel jrel_ok
    halt
jrel_ok:

test_28:
    mov r15, 0x001C ; JAL: must jump to target with return address in r14
    jal r14, jal_target
jal_expected_return:
    jmp fail
jal_target:
    mov r0, jal_expected_return
    beq r14, r0, done  ; r14 should be jal_expected_return
    jmp fail

done:
    halt

fail:
    halt
