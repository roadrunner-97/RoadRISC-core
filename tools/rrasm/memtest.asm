org 0xfc00	; set origin

xor r0, r0 ; address reg
xor r1, r1 ; outbound data reg 1
xor r2, r2 ; outbound data reg 2
xor r3, r3 ; inbound data reg

or r0, 0x0010
or r1, 0xBABE
or r2, 0xABBA
nop

mov [r0], r1
mov [r0 + 0x0001], r2

nop
mov r3, [r0]
mov r3, [r0 + 0x0001]