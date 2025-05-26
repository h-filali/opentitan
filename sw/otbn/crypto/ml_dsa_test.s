.section .text.start

    bn.xor  w0,  w0,  w0

    la x3, gadget_x_s1
    li x4, 5
    bn.lid  x4, 0(x3)

    la x3, gadget_x_s2
    li x4, 6
    bn.lid  x4, 0(x3)

    bn.mov  w8,  w7
    bn.mov  w10,  w9

    bn.mov  w15,  w5
    bn.mov  w16,  w6

    bn.mov  w25,  w15
    bn.mov  w26,  w16

    bn.xor  w5,  w5,  w0
    bn.xor  w6,  w6,  w0

    bn.xor  w0,  w0,  w0

    bn.xor  w5,  w5,  w6

    ecall

.data
    .globl gadget_x_s1
    .balign 32
    gadget_x_s1:
    .word 0x0008E616
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl gadget_x_s2
    .balign 32
    gadget_x_s2:
    .word 0x0066E21A
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
