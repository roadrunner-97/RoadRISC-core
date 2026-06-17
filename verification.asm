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

test_33:
    mov r15, 0x0021

    mov r0, 0x1A00
    mov sp, r0

    mov r12, 0x1A80          ; current row base (8 pixels = 40 words per text row)

    mov r4, str_hello
    mov r5, r12
    call draw_string
    add r12, r12, 400

    mov r4, str_fox1
    mov r5, r12
    call draw_string
    add r12, r12, 400

    mov r4, str_fox2
    mov r5, r12
    call draw_string
    add r12, r12, 400

    mov r4, str_roadrisc
    mov r5, r12
    call draw_string
    add r12, r12, 400

    mov r4, str_roadrisc2
    mov r5, r12
    call draw_string
    add r12, r12, 400

    add r12, r12, 400        ; blank row

    mov r5, r12
    call draw_glyph_dump

test_34:
    mov r15, 0x0022
    mov r1, 0xF00F
    mov r0, 0xFFFF
    mov r2, [r0]
    bneq r1, r2, fail

    mov r15, 0x0023

; after all tests pass: poll UART RX and print each received value as 8 hex digits
uart_demo:
    mov r0, 0x1A00
    mov sp, r0
    mov r12, 0x1A80          ; current screen line (top of framebuffer)

uart_demo_poll:
    xor r6, r6, r6           ; r6 = 0 (re-zero each iteration; draw_glyph clobbers it)
    mov r0, 0xFFF0
    mov r1, [r0]             ; r1 = UART flag (non-zero means byte ready)
    beq r1, r6, uart_demo_poll

    mov r0, 0xFFF1
    mov r4, [r0]             ; r4 = received value

    mov r5, r12
    call print_hex_word

    add r12, r12, 40         ; advance to next screen line
    mov r0, 0x1EF0           ; ~30 text rows from 0x1A80
    blt r0, r12, uart_demo_poll  ; if r12 < 0x1EF0, keep going
    mov r12, 0x1A80          ; wrap back to top of screen
    jmp uart_demo_poll

done:
    halt

fail:
    halt


test_addnumbers: ; clobbers r1 ?
    mov r0, sp
    mov r1, [r0 + 1]
    mov r2, [r0 + 2]
    add r1, r2
    ret


; draw_string: render a null-terminated ASCII string to the framebuffer
; r4 = ptr to string (one ASCII char per word, 0 = null terminator)
; r5 = framebuffer word address of top-left of first character
; clobbers r0, r1, r3, r4, r5, r6, r7, r8, r9
draw_string:
    xor r6, r6, r6
    mov r7, ascii_glyphs
draw_string_next:
    mov r0, [r4]
    beq r0, r6, draw_string_ret
    sub r0, r0, 0x20        ; offset from space (first glyph)
    shl r0, 3               ; * 8 words per glyph
    add r0, r0, r7          ; glyph address
    mov r1, r5
    call draw_glyph
    add r4, r4, 1
    add r5, r5, 1
    jmp draw_string_next
draw_string_ret:
    ret


; draw_glyph: blit one 8x8 pre-expanded glyph into the framebuffer
; r0 = font glyph ptr (8 consecutive words of 4bpp pixel data), exits advanced by 8
; r1 = framebuffer word address of top-left pixel of character cell
; clobbers r0, r1, r3, r6, r9 (r2 intentionally preserved for caller)
draw_glyph:
    xor r6, r6, r6
    mov r9, 8
draw_glyph_row:
    mov r3, [r0]
    mov [r1], r3
    add r0, r0, 1
    add r1, r1, 40
    sub r9, r9, 1
    bneq r9, r6, draw_glyph_row
    ret


; draw_glyph_dump: blit every printable ASCII char (0x20-0x7E) starting at r5,
; wrapping to the next screen row every 40 characters
; r5 = framebuffer word address of top-left of first cell
; clobbers r0, r1, r3, r5, r6, r7, r9, r10, r11, r13
draw_glyph_dump:
    xor r6, r6, r6
    mov r7, ascii_glyphs
    mov r10, 0x20            ; current ASCII code
    mov r11, 0               ; column counter
    mov r13, 0x7F            ; one past last glyph
draw_glyph_dump_next:
    beq r10, r13, draw_glyph_dump_done
    mov r0, r10
    sub r0, r0, 0x20
    shl r0, 3
    add r0, r0, r7
    mov r1, r5
    call draw_glyph
    add r5, r5, 1
    add r10, r10, 1
    add r11, r11, 1
    sub r3, r11, 40
    bneq r3, r6, draw_glyph_dump_next
    mov r11, 0
    sub r5, r5, 40
    add r5, r5, 320
    jmp draw_glyph_dump_next
draw_glyph_dump_done:
    ret


; print_hex_word: render a 32-bit value as 8 hex digits to the framebuffer
; r4 = 32-bit value to display
; r5 = framebuffer word address of top-left of first character
; clobbers r0, r1, r3, r5, r6, r7, r9, r10, r11
print_hex_word:
    mov r10, r4              ; r10 = working copy (rotated left 4 each iteration)
    mov r11, 8               ; r11 = nibble counter
    mov r7, ascii_glyphs
    xor r6, r6, r6
print_hex_word_loop:
    beq r11, r6, print_hex_word_done
    shr r0, r10, 28          ; extract top nibble (bits 31:28)
    and r0, r0, 0xF
    mov r3, 10
    blt r3, r0, print_hex_word_digit  ; branch if r0 < 10 -> '0'-'9'
    add r0, r0, 0x37         ; 'A' - 10 = 0x37; 10->A, 11->B, ...
    jmp print_hex_word_char
print_hex_word_digit:
    add r0, r0, 0x30         ; '0' + nibble
print_hex_word_char:
    sub r0, r0, 0x20         ; offset from glyph_20 (space is first glyph)
    shl r0, r0, 3            ; * 8 words per glyph
    add r0, r0, r7           ; r0 = glyph ptr
    mov r1, r5               ; r1 = screen address
    call draw_glyph
    add r5, r5, 1            ; advance screen cursor by one character
    shl r10, r10, 4          ; shift next nibble into top position
    sub r11, r11, 1
    jmp print_hex_word_loop
print_hex_word_done:
    ret


; strings for test_34, one ASCII char per word, null-terminated
str_hello:
    dd "Hello world!", 0

str_fox1:
    dd "The quick brown fox", 0

str_fox2:
    dd "jumped over the lazy dog", 0

str_roadrisc:
    dd "Roadrisc-32 CPU by roadrunner", 0

str_roadrisc2:
    dd "program assembled on lemonASM by lemon", 0


; ASCII 0x20-0x7E glyphs, pre-expanded to 4bpp, 8 words each
; pixel 0 (leftmost) in bits [3:0]; index = (ascii - 0x20)
ascii_glyphs:
glyph_20:
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
glyph_21:
    dd 0x000FF000
    dd 0x00FFFF00
    dd 0x00FFFF00
    dd 0x000FF000
    dd 0x000FF000
    dd 0x00000000
    dd 0x000FF000
    dd 0x00000000
glyph_22:
    dd 0x0FF0FF00
    dd 0x0FF0FF00
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
glyph_23:
    dd 0x0FF0FF00
    dd 0x0FF0FF00
    dd 0xFFFFFFF0
    dd 0x0FF0FF00
    dd 0xFFFFFFF0
    dd 0x0FF0FF00
    dd 0x0FF0FF00
    dd 0x00000000
glyph_24:
    dd 0x00FF0000
    dd 0x0FFFFF00
    dd 0xFF000000
    dd 0x0FFFF000
    dd 0x0000FF00
    dd 0xFFFFF000
    dd 0x00FF0000
    dd 0x00000000
glyph_25:
    dd 0x00000000
    dd 0xFF000FF0
    dd 0xFF00FF00
    dd 0x000FF000
    dd 0x00FF0000
    dd 0x0FF00FF0
    dd 0xFF000FF0
    dd 0x00000000
glyph_26:
    dd 0x00FFF000
    dd 0x0FF0FF00
    dd 0x00FFF000
    dd 0x0FFF0FF0
    dd 0xFF0FFF00
    dd 0xFF00FF00
    dd 0x0FFF0FF0
    dd 0x00000000
glyph_27:
    dd 0x0FF00000
    dd 0x0FF00000
    dd 0xFF000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
glyph_28:
    dd 0x000FF000
    dd 0x00FF0000
    dd 0x0FF00000
    dd 0x0FF00000
    dd 0x0FF00000
    dd 0x00FF0000
    dd 0x000FF000
    dd 0x00000000
glyph_29:
    dd 0x0FF00000
    dd 0x00FF0000
    dd 0x000FF000
    dd 0x000FF000
    dd 0x000FF000
    dd 0x00FF0000
    dd 0x0FF00000
    dd 0x00000000
glyph_2A:
    dd 0x00000000
    dd 0x0FF00FF0
    dd 0x00FFFF00
    dd 0xFFFFFFFF
    dd 0x00FFFF00
    dd 0x0FF00FF0
    dd 0x00000000
    dd 0x00000000
glyph_2B:
    dd 0x00000000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0xFFFFFF00
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x00000000
    dd 0x00000000
glyph_2C:
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x0FF00000
glyph_2D:
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0xFFFFFF00
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
glyph_2E:
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x00000000
glyph_2F:
    dd 0x00000FF0
    dd 0x0000FF00
    dd 0x000FF000
    dd 0x00FF0000
    dd 0x0FF00000
    dd 0xFF000000
    dd 0xF0000000
    dd 0x00000000
glyph_30:
    dd 0x0FFFFF00
    dd 0xFF000FF0
    dd 0xFF00FFF0
    dd 0xFF0FFFF0
    dd 0xFFFF0FF0
    dd 0xFFF00FF0
    dd 0x0FFFFF00
    dd 0x00000000
glyph_31:
    dd 0x00FF0000
    dd 0x0FFF0000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0xFFFFFF00
    dd 0x00000000
glyph_32:
    dd 0x0FFFF000
    dd 0xFF00FF00
    dd 0x0000FF00
    dd 0x00FFF000
    dd 0x0FF00000
    dd 0xFF000000
    dd 0xFFFFFF00
    dd 0x00000000
glyph_33:
    dd 0x0FFFF000
    dd 0xFF00FF00
    dd 0x0000FF00
    dd 0x00FFF000
    dd 0x0000FF00
    dd 0xFF00FF00
    dd 0x0FFFF000
    dd 0x00000000
glyph_34:
    dd 0x000FFF00
    dd 0x00FFFF00
    dd 0x0FF0FF00
    dd 0xFF00FF00
    dd 0xFFFFFFF0
    dd 0x0000FF00
    dd 0x000FFFF0
    dd 0x00000000
glyph_35:
    dd 0xFFFFFF00
    dd 0xFF000000
    dd 0xFFFFF000
    dd 0x0000FF00
    dd 0x0000FF00
    dd 0xFF00FF00
    dd 0x0FFFF000
    dd 0x00000000
glyph_36:
    dd 0x00FFF000
    dd 0x0FF00000
    dd 0xFF000000
    dd 0xFFFFF000
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0x0FFFF000
    dd 0x00000000
glyph_37:
    dd 0xFFFFFF00
    dd 0xFF00FF00
    dd 0x0000FF00
    dd 0x000FF000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x00000000
glyph_38:
    dd 0x0FFFF000
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0x0FFFF000
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0x0FFFF000
    dd 0x00000000
glyph_39:
    dd 0x0FFFF000
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0x0FFFFF00
    dd 0x0000FF00
    dd 0x000FF000
    dd 0x0FFF0000
    dd 0x00000000
glyph_3A:
    dd 0x00000000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x00000000
    dd 0x00000000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x00000000
glyph_3B:
    dd 0x00000000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x00000000
    dd 0x00000000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x0FF00000
glyph_3C:
    dd 0x000FF000
    dd 0x00FF0000
    dd 0x0FF00000
    dd 0xFF000000
    dd 0x0FF00000
    dd 0x00FF0000
    dd 0x000FF000
    dd 0x00000000
glyph_3D:
    dd 0x00000000
    dd 0x00000000
    dd 0xFFFFFF00
    dd 0x00000000
    dd 0x00000000
    dd 0xFFFFFF00
    dd 0x00000000
    dd 0x00000000
glyph_3E:
    dd 0x0FF00000
    dd 0x00FF0000
    dd 0x000FF000
    dd 0x0000FF00
    dd 0x000FF000
    dd 0x00FF0000
    dd 0x0FF00000
    dd 0x00000000
glyph_3F:
    dd 0x0FFFF000
    dd 0xFF00FF00
    dd 0x0000FF00
    dd 0x000FF000
    dd 0x00FF0000
    dd 0x00000000
    dd 0x00FF0000
    dd 0x00000000
glyph_40:
    dd 0x0FFFFF00
    dd 0xFF000FF0
    dd 0xFF0FFFF0
    dd 0xFF0F00F0
    dd 0xFF0FFFF0
    dd 0xFF000000
    dd 0x0FFFF000
    dd 0x00000000
glyph_41:
    dd 0x00FF0000
    dd 0x0FFFF000
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0xFFFFFF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0x00000000
glyph_42:
    dd 0xFFFFFF00
    dd 0x0FF00FF0
    dd 0x0FF00FF0
    dd 0x0FFFFF00
    dd 0x0FF00FF0
    dd 0x0FF00FF0
    dd 0xFFFFFF00
    dd 0x00000000
glyph_43:
    dd 0x00FFFF00
    dd 0x0FF00FF0
    dd 0xFF000000
    dd 0xFF000000
    dd 0xFF000000
    dd 0x0FF00FF0
    dd 0x00FFFF00
    dd 0x00000000
glyph_44:
    dd 0xFFFFF000
    dd 0x0FF0FF00
    dd 0x0FF00FF0
    dd 0x0FF00FF0
    dd 0x0FF00FF0
    dd 0x0FF0FF00
    dd 0xFFFFF000
    dd 0x00000000
glyph_45:
    dd 0xFFFFFFF0
    dd 0x0FF000F0
    dd 0x0FF0F000
    dd 0x0FFFF000
    dd 0x0FF0F000
    dd 0x0FF000F0
    dd 0xFFFFFFF0
    dd 0x00000000
glyph_46:
    dd 0xFFFFFFF0
    dd 0x0FF000F0
    dd 0x0FF0F000
    dd 0x0FFFF000
    dd 0x0FF0F000
    dd 0x0FF00000
    dd 0xFFFF0000
    dd 0x00000000
glyph_47:
    dd 0x00FFFF00
    dd 0x0FF00FF0
    dd 0xFF000000
    dd 0xFF000000
    dd 0xFF00FFF0
    dd 0x0FF00FF0
    dd 0x00FFFFF0
    dd 0x00000000
glyph_48:
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0xFFFFFF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0x00000000
glyph_49:
    dd 0x0FFFF000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x0FFFF000
    dd 0x00000000
glyph_4A:
    dd 0x000FFFF0
    dd 0x0000FF00
    dd 0x0000FF00
    dd 0x0000FF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0x0FFFF000
    dd 0x00000000
glyph_4B:
    dd 0xFFF00FF0
    dd 0x0FF00FF0
    dd 0x0FF0FF00
    dd 0x0FFFF000
    dd 0x0FF0FF00
    dd 0x0FF00FF0
    dd 0xFFF00FF0
    dd 0x00000000
glyph_4C:
    dd 0xFFFF0000
    dd 0x0FF00000
    dd 0x0FF00000
    dd 0x0FF00000
    dd 0x0FF000F0
    dd 0x0FF00FF0
    dd 0xFFFFFFF0
    dd 0x00000000
glyph_4D:
    dd 0xFF000FF0
    dd 0xFFF0FFF0
    dd 0xFFFFFFF0
    dd 0xFFFFFFF0
    dd 0xFF0F0FF0
    dd 0xFF000FF0
    dd 0xFF000FF0
    dd 0x00000000
glyph_4E:
    dd 0xFF000FF0
    dd 0xFFF00FF0
    dd 0xFFFF0FF0
    dd 0xFF0FFFF0
    dd 0xFF00FFF0
    dd 0xFF000FF0
    dd 0xFF000FF0
    dd 0x00000000
glyph_4F:
    dd 0x00FFF000
    dd 0x0FF0FF00
    dd 0xFF000FF0
    dd 0xFF000FF0
    dd 0xFF000FF0
    dd 0x0FF0FF00
    dd 0x00FFF000
    dd 0x00000000
glyph_50:
    dd 0xFFFFFF00
    dd 0x0FF00FF0
    dd 0x0FF00FF0
    dd 0x0FFFFF00
    dd 0x0FF00000
    dd 0x0FF00000
    dd 0xFFFF0000
    dd 0x00000000
glyph_51:
    dd 0x0FFFF000
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0xFF0FFF00
    dd 0x0FFFF000
    dd 0x000FFF00
    dd 0x00000000
glyph_52:
    dd 0xFFFFFF00
    dd 0x0FF00FF0
    dd 0x0FF00FF0
    dd 0x0FFFFF00
    dd 0x0FF0FF00
    dd 0x0FF00FF0
    dd 0xFFF00FF0
    dd 0x00000000
glyph_53:
    dd 0x0FFFF000
    dd 0xFF00FF00
    dd 0xFFF00000
    dd 0x0FFF0000
    dd 0x000FFF00
    dd 0xFF00FF00
    dd 0x0FFFF000
    dd 0x00000000
glyph_54:
    dd 0xFFFFFF00
    dd 0xF0FF0F00
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x0FFFF000
    dd 0x00000000
glyph_55:
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0xFF44FF00
    dd 0x2FFFF200
    dd 0x00000000
glyph_56:
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0x0FFFF000
    dd 0x00FF0000
    dd 0x00000000
glyph_57:
    dd 0xFF000FF0
    dd 0xFF000FF0
    dd 0xFF000FF0
    dd 0xFF0F0FF0
    dd 0xFFFFFFF0
    dd 0xFFF0FFF0
    dd 0xFF000FF0
    dd 0x00000000
glyph_58:
    dd 0xFF000FF0
    dd 0xFF000FF0
    dd 0x0FF0FF00
    dd 0x00FFF000
    dd 0x00FFF000
    dd 0x0FF0FF00
    dd 0xFF000FF0
    dd 0x00000000
glyph_59:
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0x0FFFF000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x0FFFF000
    dd 0x00000000
glyph_5A:
    dd 0xFFFFFFF0
    dd 0xFF000FF0
    dd 0xF000FF00
    dd 0x000FF000
    dd 0x00FF00F0
    dd 0x0FF00FF0
    dd 0xFFFFFFF0
    dd 0x00000000
glyph_5B:
    dd 0x0FFFF000
    dd 0x0FF00000
    dd 0x0FF00000
    dd 0x0FF00000
    dd 0x0FF00000
    dd 0x0FF00000
    dd 0x0FFFF000
    dd 0x00000000
glyph_5C:
    dd 0xFF000000
    dd 0x0FF00000
    dd 0x00FF0000
    dd 0x000FF000
    dd 0x0000FF00
    dd 0x00000FF0
    dd 0x000000F0
    dd 0x00000000
glyph_5D:
    dd 0x0FFFF000
    dd 0x000FF000
    dd 0x000FF000
    dd 0x000FF000
    dd 0x000FF000
    dd 0x000FF000
    dd 0x0FFFF000
    dd 0x00000000
glyph_5E:
    dd 0x000F0000
    dd 0x00FFF000
    dd 0x0FF0FF00
    dd 0xFF000FF0
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
glyph_5F:
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0xFFFFFFFF
glyph_60:
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x000FF000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
glyph_61:
    dd 0x00000000
    dd 0x00000000
    dd 0x0FFFF000
    dd 0x0000FF00
    dd 0x0FFFFF00
    dd 0xFF00FF00
    dd 0x0FFF0FF0
    dd 0x00000000
glyph_62:
    dd 0xFFF00000
    dd 0x0FF00000
    dd 0x0FF00000
    dd 0x0FFFFF00
    dd 0x0FF00FF0
    dd 0x0FF00FF0
    dd 0xFF0FFF00
    dd 0x00000000
glyph_63:
    dd 0x00000000
    dd 0x00000000
    dd 0x0FFFF000
    dd 0xFF00FF00
    dd 0xFF000000
    dd 0xFF00FF00
    dd 0x0FFFF000
    dd 0x00000000
glyph_64:
    dd 0x000FFF00
    dd 0x0000FF00
    dd 0x0000FF00
    dd 0x0FFFFF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0x0FFF0FF0
    dd 0x00000000
glyph_65:
    dd 0x00000000
    dd 0x00000000
    dd 0x0FFFF000
    dd 0xFF00FF00
    dd 0xFFFFFF00
    dd 0xFF000000
    dd 0x0FFFF000
    dd 0x00000000
glyph_66:
    dd 0x00FFF000
    dd 0x0FF0FF00
    dd 0x0FF00000
    dd 0xFFFF0000
    dd 0x0FF00000
    dd 0x0FF00000
    dd 0xFFFF0000
    dd 0x00000000
glyph_67:
    dd 0x00000000
    dd 0x00000000
    dd 0x0FFF0FF0
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0x0FFFFF00
    dd 0x0000FF00
    dd 0xFFFFF000
glyph_68:
    dd 0xFFF00000
    dd 0x0FF00000
    dd 0x0FF0FF00
    dd 0x0FFF0FF0
    dd 0x0FF00FF0
    dd 0x0FF00FF0
    dd 0xFFF00FF0
    dd 0x00000000
glyph_69:
    dd 0x00FF0000
    dd 0x00000000
    dd 0x0FFF0000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x0FFFF000
    dd 0x00000000
glyph_6A:
    dd 0x0000FF00
    dd 0x00000000
    dd 0x0000FF00
    dd 0x0000FF00
    dd 0x0000FF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0x0FFFF000
glyph_6B:
    dd 0xFFF00000
    dd 0x0FF00000
    dd 0x0FF00FF0
    dd 0x0FF0FF00
    dd 0x0FFFF000
    dd 0x0FF0FF00
    dd 0xFFF00FF0
    dd 0x00000000
glyph_6C:
    dd 0x0FFF0000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x0FFFF000
    dd 0x00000000
glyph_6D:
    dd 0x00000000
    dd 0x00000000
    dd 0xFF00FF00
    dd 0xFFFFFFF0
    dd 0xFFFFFFF0
    dd 0xFF0F0FF0
    dd 0xFF000FF0
    dd 0x00000000
glyph_6E:
    dd 0x00000000
    dd 0x00000000
    dd 0xFFFFF000
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0x00000000
glyph_6F:
    dd 0x00000000
    dd 0x00000000
    dd 0x0FFFF000
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0x0FFFF000
    dd 0x00000000
glyph_70:
    dd 0x00000000
    dd 0x00000000
    dd 0xFF0FFF00
    dd 0x0FF00FF0
    dd 0x0FF00FF0
    dd 0x0FFFFF00
    dd 0x0FF00000
    dd 0xFFFF0000
glyph_71:
    dd 0x00000000
    dd 0x00000000
    dd 0x0FFF0FF0
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0x0FFFFF00
    dd 0x0000FF00
    dd 0x000FFFF0
glyph_72:
    dd 0x00000000
    dd 0x00000000
    dd 0xFF0FFF00
    dd 0x0FFF0FF0
    dd 0x0FF00FF0
    dd 0x0FF00000
    dd 0xFFFF0000
    dd 0x00000000
glyph_73:
    dd 0x00000000
    dd 0x00000000
    dd 0x0FFFFF00
    dd 0xFF000000
    dd 0x0FFFF000
    dd 0x0000FF00
    dd 0xFFFFF000
    dd 0x00000000
glyph_74:
    dd 0x000F0000
    dd 0x00FF0000
    dd 0x0FFFFF00
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x00FF0F00
    dd 0x000FF000
    dd 0x00000000
glyph_75:
    dd 0x00000000
    dd 0x00000000
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0x0FFF0FF0
    dd 0x00000000
glyph_76:
    dd 0x00000000
    dd 0x00000000
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0xFF00FF00
    dd 0x0FFFF000
    dd 0x00FF0000
    dd 0x00000000
glyph_77:
    dd 0x00000000
    dd 0x00000000
    dd 0xFF000FF0
    dd 0xFF0F0FF0
    dd 0xFFFFFFF0
    dd 0xFFFFFFF0
    dd 0x0FF0FF00
    dd 0x00000000
glyph_78:
    dd 0x00000000
    dd 0x00000000
    dd 0xFF000FF0
    dd 0x0FF0FF00
    dd 0x00FFF000
    dd 0x0FF0FF00
    dd 0xFF000FF0
    dd 0x00000000
glyph_79:
    dd 0x00000000
    dd 0x00000000
    dd 0x0FF00FF0
    dd 0x0FF00FF0
    dd 0x0FF00FF0
    dd 0x00FFFFF0
    dd 0x00000FF0
    dd 0x000FFFF0
glyph_7A:
    dd 0x00000000
    dd 0x00000000
    dd 0xFFFFFF00
    dd 0xF00FF000
    dd 0x00FF0000
    dd 0x0FF00F00
    dd 0xFFFFFF00
    dd 0x00000000
glyph_7B:
    dd 0x000FFF00
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0xFFF00000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x000FFF00
    dd 0x00000000
glyph_7C:
    dd 0x000FF000
    dd 0x000FF000
    dd 0x000FF000
    dd 0x00000000
    dd 0x000FF000
    dd 0x000FF000
    dd 0x000FF000
    dd 0x00000000
glyph_7D:
    dd 0xFFF00000
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0x000FFF00
    dd 0x00FF0000
    dd 0x00FF0000
    dd 0xFFF00000
    dd 0x00000000
glyph_7E:
    dd 0x0FFF0FF0
    dd 0xFF0FFF00
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
    dd 0x00000000
