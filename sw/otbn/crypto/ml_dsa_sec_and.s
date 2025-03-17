.section .text.start

    /* Set up constants for input/state */

    la x2, gadget_a_s1
    li x11, 11
    bn.lid x11, 0(x2)

    la x2, gadget_a_s2
    li x12, 12
    bn.lid x12, 0(x2)

    la x2, gadget_b_s1
    li x13, 13
    bn.lid x13, 0(x2)

    la x2, gadget_b_s2
    li x14, 14
    bn.lid x14, 0(x2)

    la x2, gadget_r
    li x17, 17
    bn.lid x17, 0(x2)

    /* SecAnd */
    /* t = a & r */
    bn.and w19, w11, w17
    bn.and w20, w12, w17

    /* t = t ^ r */
    bn.xor w19, w19, w17
    bn.xor w20, w20, w17

    /* r = r ^ b */
    bn.xor w18, w17, w13
    bn.xor w17, w17, w14

    /* r = r & a */
    bn.and w17, w17, w11
    bn.and w18, w18, w12

    /* r = r ^ t */
    bn.xor w17, w17, w19
    bn.xor w18, w18, w20

    /* a = a & b */
    bn.and w11, w11, w13
    bn.and w12, w12, w14

    /* a = a ^ r */
    bn.xor w11, w11, w17
    bn.xor w12, w12, w18

    /* Store results to memory. */
    la x2, gadget_a_s1
    bn.sid x11, 0(x2)
    la x2, gadget_a_s2
    bn.sid x12, 0(x2)

    ecall

.data
    .globl gadget_a_s1
    .balign 32
    gadget_a_s1:
    .word 0x00000001
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl gadget_a_s2
    .balign 32
    gadget_a_s2:
    .word 0x00000001
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl gadget_b_s1
    .balign 32
    gadget_b_s1:
    .word 0x00000001
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl gadget_b_s2
    .balign 32
    gadget_b_s2:
    .word 0x00000001
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl gadget_r
    .balign 32
    gadget_r:
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
