.globl ml_dsa_sec_decompose
.globl ml_dsa_sec_b2a_44
.globl ml_dsa_sec_a2b
.globl ml_dsa_sec_addm
.globl ml_dsa_sec_add
.section .text.start

    /* Set up constants for input/state */
    /* Zero out w0 */
    bn.xor w0, w0, w0

    la x31, ml_dsa_modulus
    li x2, 30
    bn.lid x2, 0(x31)

    /* Set the modulus for modular operations */
    bn.wsrw MOD, w30

    la x31, ml_dsa_plantard_const
    li x2, 23
    bn.lid x2, 0(x31)

    /* Load x^(B,k) into w27 and w28 */
    la x31, decompose_r_s1
    li x2, 27
    bn.lid x2, 0(x31)

    /* Dummy instruction */
    bn.xor w0, w0, w0

    la x31, decompose_r_s2
    li x2, 28
    bn.lid x2, 0(x31)

    la x31, ml_dsa_decompose_const
    li x2, 29
    bn.lid x2, 0(x31)

    la x29, ml_dsa_barrett_44_const
    la x30, ml_dsa_modulus

    jal  x1, ml_dsa_sec_decompose

    la x31, decompose_r1
    li x2, 23
    bn.sid x2, 0(x31)

    la x31, decompose_r0_s1
    li x2, 27
    bn.sid x2, 0(x31)

    /* Dummy instruction */
    bn.xor w0, w0, w0

    la x31, decompose_r0_s2
    li x2, 28
    bn.sid x2, 0(x31)

    ecall

/**
 * Converts arithmetic sharing x^(B,k) to boolean sharing z^(B,k) modulo q.
 *
 * Returns Boolean sharing z^(B,k) such that z = x.
 *
 * @param[in]  [x29]:       address for the barrett reduction constant
 * @param[in]  [x30]:       address for the modulus
 * @param[in]  [w0]:        all-zero
 * @param[in]  [w23]:       plantard(-44)
 * @param[in]  [w27:w28]:   r^(A,k)
 * @param[in]  [w29]:       (q-1)/44 = 190464
 * @param[in]  [w30]:       modulus
 * @param[out] [w23]:       r1
 * @param[out] [w27:w28]:   r0^(A,k)
 *
 * clobbered registers:     w1 to w20, w31, x1, x2, x31
 */
ml_dsa_sec_decompose:

    /* Copy w27 to w21 */
    bn.mov w21, w27

    /* Set w1 = 1 */
    bn.addi w1, w0, 1

    /* Copy w28 to w22 */
    bn.mov w22, w28

    /* Plantard multiplication: plantard(-44) * r[0] */
    /* t = (0xDE3CEF7F65FA7FD5 * r[0]) % (2**64) */
    bn.mulqacc.wo.z w21, w21.0, w23.0, 192
    /* t = (t >> 32) + 1 */
    bn.add w21, w1, w21 >> 224
    /* clear add */
    bn.add w0, w0, w0
    /* t *= q */
    bn.mulqacc.wo.z w21, w21.0, w30.0, 0
    /* t = t >> 32 */
    bn.rshi w21, w0, w21 >> 32
    bn.subm w21, w30, w21
    /* clear subm */
    bn.subm w0, w0, w0

    /* clear ACC */
    bn.wsrw ACC, w0
    /* clear flags, dummy instruction */
    bn.mulqacc.wo w0, w0.0, w0.0, 0, FG0

    /* Plantard multiplication: plantard(-44) * r[0] */
    /* t = (0xDE3CEF7F65FA7FD5 * r[1]) % (2**64) */
    bn.mulqacc.wo.z w22, w22.0, w23.0, 192
    /* t = (t >> 32) + 1 */
    bn.add w22, w1, w22 >> 224
    /* clear add */
    bn.add w0, w0, w0
    /* t *= q */
    bn.mulqacc.wo.z w22, w22.0, w30.0, 0
    /* t = t >> 32 */
    bn.rshi w22, w0, w22 >> 32
    bn.subm w22, w30, w22
    /* clear subm */
    bn.subm w0, w0, w0

    /* clear ACC */
    bn.wsrw ACC, w0
    /* clear flags, dummy instruction */
    bn.mulqacc.wo w0, w0.0, w0.0, 0, FG0

    /* Set w21 to s^(B,k)_0 = s^(B,k)_0 + (q-1)/2 */
    bn.rshi w2, w0, w30 >> 1
    bn.addm w21, w21, w2
    /* clear addm */
    bn.addm w0, w0, w0

    /* Set [w5:w6] to s'^(B,k) = A2B(s^(A_q)) */
    jal  x1, ml_dsa_sec_a2b

    /* Set the modulus for modular operations */
    bn.addi w30, w0, 44
    bn.wsrw MOD, w30

    /* Copy w5 to w25 */
    bn.mov w25, w5

    /* dummy instruction */
    bn.xor w0, w0, w0

    /* Copy w6 to w26 */
    bn.mov w26, w6

    /* Set [w23:w24] to s'^(B,k) = B2A(s^(A_q)) */
    jal  x1, ml_dsa_sec_b2a_44

    /* Calculate r0 */
    bn.add w23, w23, w24
    /* clear add */
    bn.add w0, w0, w0

    /* Set the modulus back to it's original value. */
    li x2, 30
    bn.lid x2, 0(x30)
    bn.wsrw MOD, w30

    bn.add w24, w0, w29
    bn.mulqacc.wo.z w24, w23.0, w24.0, 0
    /* clear ACC */
    bn.wsrw ACC, w0
    /* clear flags, dummy instruction */
    bn.mulqacc.wo w0, w0.0, w0.0, 0, FG0
    bn.subm w27, w27, w24
    /* clear subm */
    bn.subm w0, w0, w0

    ret

/**
 * Converts boolean sharing x^(B,k) to arithmetic sharing z^(B,k) modulo 44.
 *
 * Returns arithmetic sharing z^(B,k) such that z = x.
 *
 * @param[in]  [w0]:        all-zero
 * @param[in]  [w25:w26]:   x^(B,k)
 * @param[in]  [w30]:       modulus
 * @param[out] [w23:w24]:   z^(B,k)
 *
 * clobbered registers:     w1 to w21, w31, x1, x2, x31
 */
ml_dsa_sec_b2a_44:

    /* Load random value into w24. */
    /* Only the lowest 23 bits are used. */
    bn.wsrr w24, URND

    /* Create 6 bit mask */
    bn.addi w16, w0, 1
    bn.rshi w16, w16, w0 >> 249
    bn.subi w16, w16, 1

    /* Set [w21:w22] to z'^(A_p) = (randrange(q), 0) */
    bn.and w21, w16, w24
    bn.addm w21, w0, w21

    /* Copy w21 to the output w23 */
    bn.mov w23, w21

    bn.sub w21, w30, w21
    bn.xor w22, w22, w22

    /* Set [w5:w6] to a^(B,k) = A2B(z'^(A_p)) */
    jal  x1, ml_dsa_sec_a2b

    /* Copy w5 to w1 */
    bn.mov w1, w5

    /* dummy instruction */
    bn.xor w0, w0, w0

    /* Copy w6 to w2 */
    bn.mov w2, w6

    /* dummy instruction */
    bn.xor w0, w0, w0

    /* Copy x^(B,k)[0] to w3 */
    bn.mov w3, w25

    /* dummy instruction */
    bn.xor w0, w0, w0

    /* Copy x^(B,k)[1] to w4 */
    bn.mov w4, w26

    /* dummy instruction */
    bn.xor w0, w0, w0

    /* Set [w5:w6] to b^(B,k) = a^(B,k) + x^(B,k) % q */
    jal  x1, ml_dsa_sec_addm

    /* Refresh b^(B,k) */
    bn.xor w5, w5, w24 >> 32
    /* dummy instruction */
    bn.xor w0, w0, w0
    bn.xor w6, w6, w24 >> 32
    /* dummy instruction */
    bn.xor w0, w0, w0

    /* Unmask b^(B,k) to get z^(A_p)_1 */
    bn.xor w24, w5, w6

    ret


/**
 * Converts arithmetic sharing x^(B,k) to boolean sharing z^(B,k) modulo q.
 *
 * Returns Boolean sharing z^(B,k) such that z = x.
 *
 * @param[in]  [w0]:        all-zero
 * @param[in]  [w21:w22]:   x^(B,k)
 * @param[in]  [w30]:       modulus
 * @param[out] [w5:w6]:     z^(B,k)
 *
 * clobbered registers:     w1 to w20, w31, x1, x2, x31
 */
ml_dsa_sec_a2b:

    /* p^(B,k+1) = (2^k - q, 0) */
    bn.addi w3, w0, 1
    bn.rshi w3, w3, w0 >> 232
    bn.sub  w3, w3, w30

    bn.xor w4, w4, w4

    /* y^(B,k) = (x^(B,k)[0], 0) */
    bn.add w1, w0, w21
    /* clear add */
    bn.add w0, w0, w0
    bn.xor w2, w2, w2

    /* Set [w5:w6] to s^(B,k+1) = p^(B,k+1) + y^(B,k) */
    jal  x1, ml_dsa_sec_add

    /* Copy w5 to w1 */
    bn.mov w1, w5

    /* dummy instruction */
    bn.xor w0, w0, w0

    /* Copy w6 to w2 */
    bn.mov w2, w6

    /* s'^(B,k) = (0, x^(B,k)[1]) */
    bn.xor w3, w3, w3
    bn.add w4, w0, w22
    /* clear add */
    bn.add w0, w0, w0

    /* Set [w5:w6] to u^(B,k+1) = s^(B,k+1) + s'^(B,k) */
    jal  x1, ml_dsa_sec_add

    /* Copy w5 to w1 */
    bn.mov w1, w5

    /* dummy instruction */
    bn.xor w0, w0, w0

    /* Copy w6 to w2 */
    bn.mov w2, w6

    /* dummy instruction */
    bn.xor w0, w0, w0

    /* Set [w3:w4] to a^(B,k) = u^(B,k+1)[k] * q */
    bn.rshi w3, w0, w5 >> 23
    /* dummy instruction */
    bn.xor w0, w0, w0
    bn.rshi w4, w0, w6 >> 23
    /* dummy instruction */
    bn.xor w0, w0, w0

    bn.mulqacc.wo.z w3, w3.0, w30.0, 0

    /* clear ACC */
    bn.wsrw ACC, w0
    /* clear flags, dummy instruction */
    bn.mulqacc.wo w0, w0.0, w0.0, 0, FG0

    bn.mulqacc.wo.z w4, w4.0, w30.0, 0

    /* clear ACC */
    bn.wsrw ACC, w0
    /* clear flags, dummy instruction */
    bn.mulqacc.wo w0, w0.0, w0.0, 0, FG0

    /* Set [w5:w6] to z^(B,k) = u^(B,k+1) + a^(B,k) */
    jal  x1, ml_dsa_sec_add

    ret

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

    /* Copy w5 to w1 */
    bn.mov w1, w5

    /* dummy instruction */
    bn.xor w0, w0, w0

    /* Copy w6 to w2 */
    bn.mov w2, w6

    /* dummy instruction */
    bn.xor w0, w0, w0

    /* Set [w5:w6] to s'^(B,k+1) = s^(B,k+1) + p^(B,k+1) */
    jal  x1, ml_dsa_sec_add

    /* Copy w5 to w1 */
    bn.mov w1, w5

    /* dummy instruction */
    bn.xor w0, w0, w0

    /* Copy w6 to w2 */
    bn.mov w2, w6

    /* dummy instruction */
    bn.xor w0, w0, w0

    /* Set [w3:w4] to a^(B,k) = s'^(B,k+1)[k] * q */
    bn.rshi w3, w0, w5 >> 23
    /* dummy instruction */
    bn.xor w0, w0, w0
    bn.rshi w4, w0, w6 >> 23
    /* dummy instruction */
    bn.xor w0, w0, w0

    bn.mulqacc.wo.z w3, w3.0, w30.0, 0

    /* clear ACC */
    bn.wsrw ACC, w0
    /* clear flags, dummy instruction */
    bn.mulqacc.wo w0, w0.0, w0.0, 0, FG0

    bn.mulqacc.wo.z w4, w4.0, w30.0, 0

    /* clear ACC */
    bn.wsrw ACC, w0
    /* clear flags, dummy instruction */
    bn.mulqacc.wo w0, w0.0, w0.0, 0, FG0

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

    LOOPI 23, 62
        /* move the ith share bits of x into w9 and w10 */
        bn.and  w9, w1, w31
        /* dummy instruction */
        bn.xor w0, w0, w0
        bn.and w10, w2, w31
        /* dummy instruction */
        bn.xor w0, w0, w0

        /* move the ith share bits of y into w11 and w12 */
        bn.and w11, w3, w31
        /* dummy instruction */
        bn.xor w0, w0, w0
        bn.and w12, w4, w31
        /* dummy instruction */
        bn.xor w0, w0, w0

        /* move the ith bit of r into w17 */
        bn.and w17, w15, w31

        /* b = x ^ z */
        bn.xor w13,  w9, w7
        /* dummy instruction */
        bn.xor w0, w0, w0
        bn.xor w14, w10, w8
        /* dummy instruction */
        bn.xor w0, w0, w0

        /* a = x ^ y */
        bn.xor w11,  w9, w11
        /* dummy instruction */
        bn.xor w0, w0, w0
        bn.xor w12, w10, w12
        /* dummy instruction */
        bn.xor w0, w0, w0

        /* c = z ^ a */
        bn.xor w7, w7, w11
        /* dummy instruction */
        bn.xor w0, w0, w0
        bn.xor w8, w8, w12
        /* dummy instruction */
        bn.xor w0, w0, w0

        /* SecAnd */
        /* t = a & r */
        bn.and w19, w11, w17
        /* dummy instruction */
        bn.xor w0, w0, w0
        bn.and w20, w12, w17
        /* dummy instruction */
        bn.xor w0, w0, w0

        /* t = t ^ r */
        bn.xor w19, w19, w17
        /* dummy instruction */
        bn.xor w0, w0, w0
        bn.xor w20, w20, w17
        /* dummy instruction */
        bn.xor w0, w0, w0

        /* r = r ^ b */
        bn.xor w18, w17, w13
        /* dummy instruction */
        bn.xor w0, w0, w0
        bn.xor w17, w17, w14
        /* dummy instruction */
        bn.xor w0, w0, w0

        /* r = r & a */
        bn.and w17, w17, w11
        /* dummy instruction */
        bn.xor w0, w0, w0
        bn.and w18, w18, w12
        /* dummy instruction */
        bn.xor w0, w0, w0

        /* r = r ^ t */
        bn.xor w17, w17, w19
        /* dummy instruction */
        bn.xor w0, w0, w0
        bn.xor w18, w18, w20
        /* dummy instruction */
        bn.xor w0, w0, w0

        /* a = a & b */
        bn.and w11, w11, w13
        /* dummy instruction */
        bn.xor w0, w0, w0
        bn.and w12, w12, w14
        /* dummy instruction */
        bn.xor w0, w0, w0

        /* a = a ^ r */
        bn.xor w11, w11, w17
        /* dummy instruction */
        bn.xor w0, w0, w0
        bn.xor w12, w12, w18
        /* dummy instruction */
        bn.xor w0, w0, w0

        /* End of SecAnd */

        /* x = x ^ a */
        bn.xor  w9,  w9, w11
        /* dummy instruction */
        bn.xor w0, w0, w0
        bn.xor w10, w10, w12
        /* dummy instruction */
        bn.xor w0, w0, w0

        /* z = z | x */
        bn.or w5, w5, w7
        /* dummy instruction */
        bn.xor w0, w0, w0
        bn.or w6, w6, w8
        /* dummy instruction */
        bn.xor w0, w0, w0

        /* Shift bit mask and c one bit to the left */
        bn.rshi w31, w31, w0 >> 255
        bn.rshi  w7,  w9, w0 >> 255
        /* dummy instruction */
        bn.xor w0, w0, w0
        bn.rshi  w8, w10, w0 >> 255
        /* dummy instruction */
        bn.xor w0, w0, w0
    
    /* move the 24th share bits of x into w9 and w10 */
    bn.and  w9, w1, w31
    /* dummy instruction */
    bn.xor w0, w0, w0
    bn.and w10, w2, w31
    /* dummy instruction */
    bn.xor w0, w0, w0

    /* move the 24th share bits of y into w11 and w12 */
    bn.and w11, w3, w31
    /* dummy instruction */
    bn.xor w0, w0, w0
    bn.and w12, w4, w31
    /* dummy instruction */
    bn.xor w0, w0, w0

    /* x = x ^ c */
    bn.xor  w9,  w9, w7
    /* dummy instruction */
    bn.xor w0, w0, w0
    bn.xor w10, w10, w8
    /* dummy instruction */
    bn.xor w0, w0, w0

    /* x = x ^ y */
    bn.xor  w9,  w9, w11
    /* dummy instruction */
    bn.xor w0, w0, w0
    bn.xor w10, w10, w12
    /* dummy instruction */
    bn.xor w0, w0, w0

    /* z = z | x */
    bn.or w5, w5,  w9
    /* dummy instruction */
    bn.xor w0, w0, w0
    bn.or w6, w6, w10
    /* dummy instruction */
    bn.xor w0, w0, w0

    ret

.data
    .globl ml_dsa_barrett_44_const
    .balign 32
    ml_dsa_barrett_44_const:
    .word 0x0002E8BA
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl ml_dsa_decompose_const
    .balign 32
    ml_dsa_decompose_const:
    .word 0x0002E800
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl ml_dsa_plantard_const
    .balign 32
    ml_dsa_plantard_const:
    .word 0x04D10839
    .word 0x00005816
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

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

    .globl decompose_r_s1
    .balign 32
    decompose_r_s1:
    .word 0x0051D03F
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl decompose_r_s2
    .balign 32
    decompose_r_s2:
    .word 0x001DE654
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl decompose_r1
    .balign 32
    decompose_r1:
    .word 0x00000026
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl decompose_r0_s1
    .balign 32
    decompose_r0_s1:
    .word 0x00634040
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl decompose_r0_s2
    .balign 32
    decompose_r0_s2:
    .word 0x001de654
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
