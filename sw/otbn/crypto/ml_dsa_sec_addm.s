.section .text.start

    /* Zero out w0 and z */
    bn.xor  w0,  w0,  w0

    /* Load the modulus into MOD and w30 */
    li x8, 30
    la x3, ml_dsa_modulus
    bn.lid  x8, 0(x3)
    bn.wsrw MOD, w30

    la x2, gadget_x_s1
    li x3, 1
    bn.lid x3, 0(x2)

    la x2, gadget_x_s2
    li x4, 2
    bn.lid x4, 0(x2)

    la x2, gadget_y_s1
    li x5, 3
    bn.lid x5, 0(x2)

    la x2, gadget_y_s2
    li x6, 4
    bn.lid x6, 0(x2)

    jal x1, ml_dsa_sec_addm

    /* Write output to memory. */
    li x8, 5
    la x12, gadget_z_s1
    bn.sid x8, 0(x12)
    li x8, 6
    la x12, gadget_z_s2
    bn.sid x8, 0(x12)

    bn.xor w5, w5, w6

    ecall

/**
 * Adds two k=24 bit boolean sharings x^(B,k) and y^(B,k) modulo q.
 *
 * Returns Boolean sharing z^(B,k) such that z = x + y % q.
 *
 * @param[in]  [w0]:    all-zero
 * @param[in]  [w1:w2]: x^(B,k)
 * @param[in]  [w3:w4]: y^(B,k)
 * @param[in]  [w30]:   modulus
 * @param[out] [w5:w6]: z^(B,k)
 *
 * clobbered registers: w7 to w20, w31, x1, x2, x31
 */
ml_dsa_sec_addm:

    /* Set [w5:w6] to s^(B,k+1) = x^(B,k) + y^(B,k) */
    jal  x1, ml_dsa_sec_add

    /* p^(B,k+1) = (2^k - q, 0) */
    bn.addi w3, w0, 1
    bn.rshi w3, w3, w0 >> 232
    bn.sub  w3, w3, w30

    /* Zero out w4 */
    bn.xor w4, w4, w4

    /* Move [w5:w6] to [w1:w2] */
    bn.add w1, w5, w0
    bn.add w2, w6, w0

    /* Set [w5:w6] to s'^(B,k+1) = s^(B,k+1) + p^(B,k+1) */
    jal  x1, ml_dsa_sec_add

    /* Move [w5:w6] to [w1:w2] */
    bn.add w1, w5, w0
    bn.add w2, w6, w0

    /* Set [w3:w4] to a^(B,k) = s'^(B,k+1)[k] * q */
    bn.rshi w3, w0, w5 >> 23
    bn.rshi w4, w0, w6 >> 23

    bn.mulqacc.wo.z w3, w3.0, w30.0, 0
    bn.mulqacc.wo.z w4, w4.0, w30.0, 0

    /* Set [w5:w6] to z^(B,k) = a^(B,k) + s'^(B,k+1) */
    jal  x1, ml_dsa_sec_add
    
    ret

/**
 * Adds two k=24 bit boolean sharings x^(B,k) and y^(B,k).
 *
 * Returns Boolean sharing z^(B,k) such that z = x + y.
 *
 * @param[in]  [w0]: all-zero
 * @param[in]  [w1:w2]: x^(B,k)
 * @param[in]  [w3:w4]: y^(B,k)
 * @param[out] [w5:w6]: z^(B,k)
 *
 * clobbered registers: w7 to w20, w31
 */
ml_dsa_sec_add:

    /* Set up constants for input/state */

    /* Zero out z */
    bn.xor w5, w5, w5
    bn.xor w6, w6, w6

    /* Bit mask */
    bn.addi w31, w0, 1

    /* Load random value r into w15. */
    /* Only the lowest 23 bits are used. */
    bn.wsrr w15, URND

    /* c[i] = 0 */
    bn.add w7, w0, w0
    bn.add w8, w0, w0

    LOOPI 23, 32
        /* move the ith share bits of x into w9 and w10 */
        bn.and  w9, w1, w31
        bn.and w10, w2, w31

        /* move the ith share bits of y into w11 and w12 */
        bn.and w11, w3, w31
        bn.and w12, w4, w31

        /* move the ith bit of r into w17 */
        bn.and w17, w15, w31

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
        bn.or w5, w5, w7
        bn.or w6, w6, w8

        /* Shift bit mask and c one bit to the left */
        bn.rshi w31, w31, w0 >> 255
        bn.rshi  w7,  w9, w0 >> 255
        bn.rshi  w8, w10, w0 >> 255
    
    /* move the 24th share bits of x into w9 and w10 */
    bn.and  w9, w1, w31
    bn.and w10, w2, w31

    /* move the 24th share bits of y into w11 and w12 */
    bn.and w11, w3, w31
    bn.and w12, w4, w31

    /* x = x ^ c */
    bn.xor  w9,  w9, w7
    bn.xor w10, w10, w8

    /* x = x ^ y */
    bn.xor  w9,  w9, w11
    bn.xor w10, w10, w12

    /* z = z | x */
    bn.or w5, w5,  w9
    bn.or w6, w6, w10

    ret

.data
    .globl ml_dsa_modulus
    .balign 32
    ml_dsa_modulus:
    .word 0x007FE001
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl gadget_x_s1
    .balign 32
    gadget_x_s1:
    .word 0x0017E2DB
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
    .word 0x0012D2D9
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
    .word 0x0017E2DB
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
    .word 0x0012D2D9
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
    .word 0x00B900D7
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
