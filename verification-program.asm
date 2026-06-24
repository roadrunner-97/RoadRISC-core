; verification test suite
; r15 holds current test number; on failure we print "TEST FAILED" with the number so you know which test failed
; all tests pass when "ALL TESTS PASSED" is printed

jmp _start	; allow this to still be assembled as a raw binary

str_failed: db "TEST FAILED: ", 0x00
align 4
str_passed: db "ALL TESTS PASSED", 0x00
align 4

_start:
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
    beq r14, r0, test_29  ; r14 should be jal_expected_return
    jmp fail

test_29:
    mov r15, 0x001D ; ensure endianness is big endian
    mov r0, 0x12
    shl r0, 8
    or r0, 0x34
    mov r1, 0x1234
    bneq r0, r1, fail

test_30:
    mov r15, 0x001E
    mov r3, 0xF00F
    sts r3  ; stack pointer now at F00F

    lds r1  ; r1 now at F00F
    bneq r3, r1, fail

test_31:
    mov r15, 0x001F

    mov r3, 0x1A00
    sts r3

    mov r1, 0xBABE
    mov r3, 0xBABE
    mov r2, 0xEEFE
    mov r4, 0xEEFE
    push r2
    push r1
    nop
    pop r2
    pop r1
    bneq r1, r4, fail
    bneq r2, r3, fail

test_32:
    mov r15, 0x0020

    mov r3, 0x1A00
    sts r3

    mov r0, 0x22
    push r0
    mov r0, 0x20
    push r0

    call test_addnumbers
    mov r10, sp
    add r10, 2
    mov sp, r10

    mov r0, 0x42
    bneq r0, r1, fail

test_33: ; test mull and mulh: 0x76543210 * 0xFEDCBA98 = 0x75CD9046_541D5980
    mov r15, 0x0021        ; mull: lower 32 bits

    mov r0, 0x7654
    shl r0, 16
    or r0, 0x3210          ; r0 = 0x76543210

    mov r1, 0xFEDC
    shl r1, 16
    or r1, 0xBA98          ; r1 = 0xFEDCBA98

    mull r2, r0, r1

    mov r4, 0x541D
    shl r4, 16
    or r4, 0x5980          ; r4 = 0x541D5980 (expected)
    bneq r2, r4, fail

test_34:
    mov r15, 0x0022        ; mulu: upper 32 bits
    mulu r3, r0, r1

    mov r5, 0x75CD
    shl r5, 16
    or r5, 0x9046          ; r5 = 0x75CD9046 (expected)
    bneq r3, r5, fail

passed:
	mov r12, r15 ; bios uses standard ABI, move test number out of r15 (scratch) into r12 (callee saved)

	xor r0, r0
	xor r1, r1
	mov r2, str_passed
	call bios_print_str
	jmp wait_then_rtb

fail:
	mov r12, r15 ; bios uses standard ABI, move test number out of r15 (scratch) into r12 (callee saved)

	xor r0, r0
	xor r1, r1
	mov r2, str_failed
	call bios_print_str
	xor r0, r0
	mov r1, 8
	mov r2, r12
	mov r2, 1
	call bios_print_num
	jmp wait_then_rtb

wait_then_rtb:
	xor r14, r14

	mov r13, [r14 + 0xffff]
	shr r13, 31
	beq r13, r14, wait_then_rtb.real_cpu

	mov r15, 0x800
	mul r15, r15
	jmp wait_then_rtb.stall_loop

wait_then_rtb.real_cpu:
	mov r15, 0x017d ; 0x17d7840, or, 25000000
	shl r15, 16
	or r15, 0x7840

wait_then_rtb.stall_loop:
	sub r15, 1
	bneq r15, r14, wait_then_rtb.stall_loop
	jmp bios_rtb ; becuase we fuck up the stack during our testing, use bios functon 6 t initiate RTB procedure

bios_print_str:
	mov r13, 0x1604 ; bios function 4 - print_str(x, y, str)
	jmp bios_call

bios_rtb:
	mov r13, 0x1606 ; bios function 6 - return_to_bios()
	jmp bios_call

bios_print_num:
	mov r13, 0x1607 ; bios function 7 - print_number(x, y, num)

bios_call:
	mov r13, [r13]
	push r13
	ret

test_addnumbers: ; clobbers r1 ?
    mov r0, sp
    mov r1, [r0 + 1]
    mov r2, [r0 + 2]
    add r1, r2
    ret
