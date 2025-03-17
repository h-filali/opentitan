.section .text.start

    /* Set up constants for input/state */

    /* Zero out w0 and z */
    bn.xor  w0,  w0,  w0
    bn.xor w21, w21, w21
    bn.xor w22, w22, w22

    /* Bit mask */
    bn.addi w1, w0, 1

    la x2, gadget_x_s1
    li x3, 3
    bn.lid x3, 0(x2)

    la x2, gadget_x_s2
    li x4, 4
    bn.lid x4, 0(x2)

    la x2, gadget_y_s1
    li x5, 5
    bn.lid x5, 0(x2)

    la x2, gadget_y_s2
    li x6, 6
    bn.lid x6, 0(x2)

    /* Load random values r0 and r1 into w15. */
    /* Only the lowest 22 bits are used. */
    bn.wsrr w15, URND
    bn.addi w15, w0, 1
    bn.or w15, w0, w15 << 32
    bn.subi w15, w15, 1

    /* c[i] = 0 */
    bn.add w7, w0, w0
    bn.add w8, w0, w0

    LOOPI 22, 32
        /* move the ith share bits of x into w9 and w10 */
        bn.and  w9, w3, w1
        bn.and w10, w4, w1

        /* move the ith share bits of y into w11 and w12 */
        bn.and w11, w5, w1
        bn.and w12, w6, w1

        /* move the ith bit of r into w17 */
        bn.and w17, w15, w1

        /* b = x ^ z */
        bn.xor w13,  w9, w7
        bn.xor w14, w10, w8

        /* a = x ^ y */
        bn.xor w11,  w9, w11
        bn.xor w12, w10, w12

        /* c = z ^ a */
        bn.xor w7, w7, w11
        bn.xor w8, w8, w12

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

        /* End of SecAnd */

        /* x = x ^ a */
        bn.xor  w9,  w9, w11
        bn.xor w10, w10, w12

        /* z = z | x */
        bn.or w21, w21, w7
        bn.or w22, w22, w8

        /* Shift bit mask and c one bit to the left */
        bn.rshi w1,  w1, w0 >> 255
        bn.rshi w7,  w9, w0 >> 255
        bn.rshi w8, w10, w0 >> 255
    
    /* move the 23rd share bits of x into w9 and w10 */
    bn.and  w9, w3, w1
    bn.and w10, w4, w1

    /* move the 23rd share bits of y into w11 and w12 */
    bn.and w11, w5, w1
    bn.and w12, w6, w1

    /* x = x ^ c */
    bn.xor  w9,  w9, w7
    bn.xor w10, w10, w8

    /* x = x ^ y */
    bn.xor  w9,  w9, w11
    bn.xor w10, w10, w12

    /* z = z | x */
    bn.or w21, w21,  w9
    bn.or w22, w22, w10

    /* Write output to memory. */
    li x8, 21
    la x12, gadget_z_s1
    bn.sid x8, 0(x12)
    li x8, 22
    la x12, gadget_z_s2
    bn.sid x8, 0(x12)

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

    .globl gadget_y_s1
    .balign 32
    gadget_y_s1:
    .word 0x003BD56B
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl gadget_y_s2
    .balign 32
    gadget_y_s2:
    .word 0x001013B0
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl gadget_z_s1
    .balign 32
    gadget_z_s1:
    .word 0x003900D7
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl gadget_z_s2
    .balign 32
    gadget_z_s2:
    .word 0x0020CA30
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
