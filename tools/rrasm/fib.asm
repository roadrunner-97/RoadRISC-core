addi r1, r0, 0x0000
addi r2, r0, 0x0001
loop:
add r3, r1, r2
add r1, r2, r0
add r2, r3, r0
jmp loop
