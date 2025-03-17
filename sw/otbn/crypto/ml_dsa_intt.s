.section .text.start
    /* Zero some registers */
    bn.xor  w0,  w0,  w0

    /* Set up constants for input/state */
    la  x9, ntt_f
    la x10, ntt_w
    la x11, ntt_modified_zetas
    la x12, modulus
    la x13, ntt_modified_zetas_scratch

    la x14, 1
    la x15, 2
    la x16, 3

    li x17,  17
    li x18,  18
    li x19,  19
    li x20,  20
    li x21,  21
    li x22,  22
    li x23,  23
    li x24,  24
    li x25,  25
    li x26,  26
    li x27,  27
    li x28,  28
    li x29,  29
    li x30,  30
    li x31,  31

    /* Load the last 15 Zetas into the scratchpad */
    li x8, 0xAE213AF3
    sw x8, 0(x13)
    li x7, 0x254DC526
    sw x7, 4(x13)
    li x8, 0xA0F3ABAA
    sw x8, 8(x13)
    li x7, 0xEEF89A48
    sw x7, 12(x13)
    li x8, 0x581FF54E
    sw x8, 16(x13)
    li x7, 0x1EB51B09
    sw x7, 20(x13)
    li x8, 0xA0B34390
    sw x8, 24(x13)
    li x7, 0x8CFE3A74
    sw x7, 28(x13)
    li x8, 0x3FE6FB40
    sw x8, 32(x13)
    li x7, 0xBEEFF47F
    sw x7, 36(x13)
    li x8, 0x0AF96444
    sw x8, 40(x13)
    li x7, 0xAE1024AD
    sw x7, 44(x13)
    li x8, 0xB81BB17D
    sw x8, 48(x13)
    li x7, 0x93C9492A
    sw x7, 52(x13)
    li x8, 0xC835B7DE
    sw x8, 56(x13)
    li x7, 0x12613E2A
    sw x7, 60(x13)
    li x8, 0xF1C02827
    sw x8, 64(x13)
    li x7, 0x61CB9E23
    sw x7, 68(x13)
    li x8, 0x1AC460E3
    sw x8, 72(x13)
    li x7, 0x6017A128
    sw x7, 76(x13)
    li x8, 0x17C3C0C1
    sw x8, 80(x13)
    li x7, 0x58172118
    sw x7, 84(x13)
    li x8, 0xF8C1A879
    sw x8, 88(x13)
    li x7, 0x61CC1E43
    sw x7, 92(x13)
    li x8, 0x0FD9F05D
    sw x8, 96(x13)
    li x7, 0x8D187503
    sw x7, 100(x13)
    li x8, 0x4FB1E7DB
    sw x8, 104(x13)
    li x7, 0x8CF87102
    sw x7, 108(x13)
    li x8, 0xFF35DF7A
    sw x8, 112(x13)
    li x7, 0x6D1F44F6
    sw x7, 116(x13)
    li x8, 0x00000000
    sw x8, 120(x13)
    sw x7, 124(x13)

    /* Load f = 256^-1 mod q into the scratchpad */
    li x8, 0x00801c07
    sw x8,  0(x9)
    li x7, 0xff000002
    sw x7,  4(x9)
    sw x0,  8(x9)
    sw x0, 12(x9)
    sw x0, 16(x9)
    sw x0, 20(x9)
    sw x0, 24(x9)
    sw x0, 28(x9)

    /* Load modulus into w31.1 and have w31.0 be all zeros */
    li x8, 0x007FE001
    sw x8,  0(x12)
    sw x0,  4(x12)
    sw x0,  8(x12)
    sw x0, 12(x12)
    sw x0, 16(x12)
    sw x0, 20(x12)
    sw x0, 24(x12)
    sw x0, 28(x12)
    bn.lid x31, 0(x12)

    /* Set the modulus for modular operations */
    bn.wsrw MOD, w31
    bn.rshi w31, w31, w0 >> 192

    /* Load 0x1 into w31.2 */
    bn.addi w2, w0, 1
    bn.or w31, w31, w2 << 128

    /* Load mask into w31.3 */
    bn.addi w1, w0, 1
    bn.or w1, w0, w1 << 32
    bn.subi w1, w1, 1
    bn.or w31, w31, w1 << 192

    /* Create mask */
    bn.rshi w29, w0, w31 >> 192

    loopi 16, 232
        /* Load zetas into the zetas register */
        bn.lid x30, 0(x11++)

        /* Load coefficients into the buffers */
        bn.lid x17, 0(x10)
        bn.and w1, w29, w17 >> 0
        bn.and w2, w29, w17 >> 32
        bn.and w3, w29, w17 >> 64
        bn.and w4, w29, w17 >> 96
        bn.and w5, w29, w17 >> 128
        bn.and w6, w29, w17 >> 160
        bn.and w7, w29, w17 >> 192
        bn.and w8, w29, w17 >> 224

        bn.lid x18, 32(x10)
        bn.and w9,  w29, w18 >> 0
        bn.and w10, w29, w18 >> 32
        bn.and w11, w29, w18 >> 64
        bn.and w12, w29, w18 >> 96
        bn.and w13, w29, w18 >> 128
        bn.and w14, w29, w18 >> 160
        bn.and w15, w29, w18 >> 192
        bn.and w16, w29, w18 >> 224

        /* Round 1 */

        /* Butterfly */
        bn.subm w0, w1, w2
        bn.addm w1, w1, w2
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.0, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w2, w31, w0 >> 32

        /* Butterfly */
        bn.subm w0, w3, w4
        bn.addm w3, w3, w4
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.1, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w4, w31, w0 >> 32

        /* Butterfly */
        bn.subm w0, w5, w6
        bn.addm w5, w5, w6
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.2, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w6, w31, w0 >> 32

        /* Butterfly */
        bn.subm w0, w7, w8
        bn.addm w7, w7, w8
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.3, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w8, w31, w0 >> 32

        /* Load next 4 zetas into the zetas register */
        bn.lid x30, 0(x11++)

        /* Butterfly */
        bn.subm w0, w9, w10
        bn.addm w9, w9, w10
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.0, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w10, w31, w0 >> 32

        /* Butterfly */
        bn.subm  w0, w11, w12
        bn.addm w11, w11, w12
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.1, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w12, w31, w0 >> 32

        /* Butterfly */
        bn.subm  w0, w13, w14
        bn.addm w13, w13, w14
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.2, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w14, w31, w0 >> 32

        /* Butterfly */
        bn.subm  w0, w15, w16
        bn.addm w15, w15, w16
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.3, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w16, w31, w0 >> 32

        /* Round 2 */

        /* Load next 4 zetas into the zetas register */
        bn.lid x30, 0(x11++)

        /* Butterfly */
        bn.subm w0, w1, w3
        bn.addm w1, w1, w3
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.0, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w3, w31, w0 >> 32

        /* Butterfly */
        bn.subm w0, w2, w4
        bn.addm w2, w2, w4
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.0, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w4, w31, w0 >> 32

        /* Butterfly */
        bn.subm w0, w5, w7
        bn.addm w5, w5, w7
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.1, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w7, w31, w0 >> 32

        /* Butterfly */
        bn.subm w0, w6, w8
        bn.addm w6, w6, w8
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.1, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w8, w31, w0 >> 32

        /* Butterfly */
        bn.subm w0, w9, w11
        bn.addm w9, w9, w11
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.2, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w11, w31, w0 >> 32

        /* Butterfly */
        bn.subm  w0, w10, w12
        bn.addm w10, w10, w12
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.2, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w12, w31, w0 >> 32

        /* Butterfly */
        bn.subm  w0, w13, w15
        bn.addm w13, w13, w15
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.3, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w15, w31, w0 >> 32

        /* Butterfly */
        bn.subm  w0, w14, w16
        bn.addm w14, w14, w16
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.3, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w16, w31, w0 >> 32

        /* Round 3 */

        /* Load next 4 zetas into the zetas register */
        bn.lid x30, 0(x11++)

        /* Butterfly */
        bn.subm w0, w1, w5
        bn.addm w1, w1, w5
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.0, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w5, w31, w0 >> 32

        /* Butterfly */
        bn.subm w0, w2, w6
        bn.addm w2, w2, w6
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.0, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w6, w31, w0 >> 32

        /* Butterfly */
        bn.subm w0, w3, w7
        bn.addm w3, w3, w7
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.0, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w7, w31, w0 >> 32

        /* Butterfly */
        bn.subm w0, w4, w8
        bn.addm w4, w4, w8
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.0, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w8, w31, w0 >> 32

        /* Butterfly */
        bn.subm w0, w9, w13
        bn.addm w9, w9, w13
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.1, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w13, w31, w0 >> 32

        /* Butterfly */
        bn.subm  w0, w10, w14
        bn.addm w10, w10, w14
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.1, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w14, w31, w0 >> 32

        /* Butterfly */
        bn.subm  w0, w11, w15
        bn.addm w11, w11, w15
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.1, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w15, w31, w0 >> 32

        /* Butterfly */
        bn.subm  w0, w12, w16
        bn.addm w12, w12, w16
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.1, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w16, w31, w0 >> 32

        /* Round 4 */

        /* Butterfly */
        bn.subm w0, w1, w9
        bn.addm w1, w1, w9
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.2, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w9, w31, w0 >> 32

        /* Butterfly */
        bn.subm w0, w2, w10
        bn.addm w2, w2, w10
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.2, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w10, w31, w0 >> 32

        /* Butterfly */
        bn.subm w0, w3, w11
        bn.addm w3, w3, w11
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.2, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w11, w31, w0 >> 32

        /* Butterfly */
        bn.subm w0, w4, w12
        bn.addm w4, w4, w12
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.2, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w12, w31, w0 >> 32

        /* Butterfly */
        bn.subm w0, w5, w13
        bn.addm w5, w5, w13
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.2, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w13, w31, w0 >> 32

        /* Butterfly */
        bn.subm w0, w6, w14
        bn.addm w6, w6, w14
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.2, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w14, w31, w0 >> 32

        /* Butterfly */
        bn.subm w0, w7, w15
        bn.addm w7, w7, w15
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.2, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w15, w31, w0 >> 32

        /* Butterfly */
        bn.subm w0, w8, w16
        bn.addm w8, w8, w16
        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w0.0, w30.2, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w16, w31, w0 >> 32

        /* Write back the coefficients from buffers to memory */
        bn.rshi w17, w1, w17 >> 32
        bn.rshi w17, w2, w17 >> 32
        bn.rshi w17, w3, w17 >> 32
        bn.rshi w17, w4, w17 >> 32
        bn.rshi w17, w5, w17 >> 32
        bn.rshi w17, w6, w17 >> 32
        bn.rshi w17, w7, w17 >> 32
        bn.rshi w17, w8, w17 >> 32
        bn.sid x17, 0(x10++)

        bn.rshi w18,  w9, w18 >> 32
        bn.rshi w18, w10, w18 >> 32
        bn.rshi w18, w11, w18 >> 32
        bn.rshi w18, w12, w18 >> 32
        bn.rshi w18, w13, w18 >> 32
        bn.rshi w18, w14, w18 >> 32
        bn.rshi w18, w15, w18 >> 32
        bn.rshi w18, w16, w18 >> 32
        bn.sid x18, 0(x10++)

    /* Set x10 back to its original value */
    la x10, ntt_w

    loopi 2, 329
        /* Load coefficients into the buffers */
        bn.lid x17,    0(x10)
        bn.lid x18,   64(x10)
        bn.lid x19,  128(x10)
        bn.lid x20,  192(x10)
        bn.lid x21,  256(x10)
        bn.lid x22,  320(x10)
        bn.lid x23,  384(x10)
        bn.lid x24,  448(x10)
        bn.lid x25,  512(x10)
        bn.lid x26,  576(x10)
        bn.lid x27,  640(x10)
        bn.lid x28,  704(x10)
        bn.lid x29,  768(x10)

        loopi 8, 302
            /* Load zetas into the zetas register */
            bn.lid x30, 0(x13)

            /* Load coefficients that don't have a buffer */
            bn.lid x14, 832(x10)
            bn.and w14, w1, w31 >> 192
            bn.lid x15, 896(x10)
            bn.and w15, w2, w31 >> 192
            bn.lid x16, 960(x10)
            bn.and w16, w3, w31 >> 192

            /* Load the rest of the coefficients from the buffers */
            bn.and w1,  w17, w31 >> 192
            bn.and w2,  w18, w31 >> 192
            bn.and w3,  w19, w31 >> 192
            bn.and w4,  w20, w31 >> 192
            bn.and w5,  w21, w31 >> 192
            bn.and w6,  w22, w31 >> 192
            bn.and w7,  w23, w31 >> 192
            bn.and w8,  w24, w31 >> 192
            bn.and w9,  w25, w31 >> 192
            bn.and w10, w26, w31 >> 192
            bn.and w11, w27, w31 >> 192
            bn.and w12, w28, w31 >> 192
            bn.and w13, w29, w31 >> 192

            /* Round 5 */

            /* Butterfly */
            bn.subm w0, w1, w2
            bn.addm w1, w1, w2
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w2, w31, w0 >> 32

            /* Butterfly */
            bn.subm w0, w3, w4
            bn.addm w3, w3, w4
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.1, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w4, w31, w0 >> 32

            /* Butterfly */
            bn.subm w0, w5, w6
            bn.addm w5, w5, w6
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.2, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w6, w31, w0 >> 32

            /* Butterfly */
            bn.subm w0, w7, w8
            bn.addm w7, w7, w8
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.3, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w8, w31, w0 >> 32

            /* Load next 4 zetas into the zetas register */
            bn.lid x30, 32(x13)

            /* Butterfly */
            bn.subm w0, w9, w10
            bn.addm w9, w9, w10
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w10, w31, w0 >> 32

            /* Butterfly */
            bn.subm  w0, w11, w12
            bn.addm w11, w11, w12
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.1, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w12, w31, w0 >> 32

            /* Butterfly */
            bn.subm  w0, w13, w14
            bn.addm w13, w13, w14
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.2, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w14, w31, w0 >> 32

            /* Butterfly */
            bn.subm  w0, w15, w16
            bn.addm w15, w15, w16
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.3, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w16, w31, w0 >> 32

            /* Round 6 */

            /* Load next 4 zetas into the zetas register */
            bn.lid x30, 64(x13)

            /* Butterfly */
            bn.subm w0, w1, w3
            bn.addm w1, w1, w3
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w3, w31, w0 >> 32

            /* Butterfly */
            bn.subm w0, w2, w4
            bn.addm w2, w2, w4
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w4, w31, w0 >> 32

            /* Butterfly */
            bn.subm w0, w5, w7
            bn.addm w5, w5, w7
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.1, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w7, w31, w0 >> 32

            /* Butterfly */
            bn.subm w0, w6, w8
            bn.addm w6, w6, w8
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.1, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w8, w31, w0 >> 32

            /* Butterfly */
            bn.subm w0, w9, w11
            bn.addm w9, w9, w11
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.2, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w11, w31, w0 >> 32

            /* Butterfly */
            bn.subm  w0, w10, w12
            bn.addm w10, w10, w12
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.2, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w12, w31, w0 >> 32

            /* Butterfly */
            bn.subm  w0, w13, w15
            bn.addm w13, w13, w15
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.3, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w15, w31, w0 >> 32

            /* Butterfly */
            bn.subm  w0, w14, w16
            bn.addm w14, w14, w16
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.3, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w16, w31, w0 >> 32

            /* Round 7 */

            /* Load next 4 zetas into the zetas register */
            bn.lid x30, 96(x13)

            /* Butterfly */
            bn.subm w0, w1, w5
            bn.addm w1, w1, w5
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w5, w31, w0 >> 32

            /* Butterfly */
            bn.subm w0, w2, w6
            bn.addm w2, w2, w6
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w6, w31, w0 >> 32

            /* Butterfly */
            bn.subm w0, w3, w7
            bn.addm w3, w3, w7
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w7, w31, w0 >> 32

            /* Butterfly */
            bn.subm w0, w4, w8
            bn.addm w4, w4, w8
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w8, w31, w0 >> 32

            /* Butterfly */
            bn.subm w0, w9, w13
            bn.addm w9, w9, w13
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.1, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w13, w31, w0 >> 32

            /* Butterfly */
            bn.subm  w0, w10, w14
            bn.addm w10, w10, w14
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.1, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w14, w31, w0 >> 32

            /* Butterfly */
            bn.subm  w0, w11, w15
            bn.addm w11, w11, w15
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.1, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w15, w31, w0 >> 32

            /* Butterfly */
            bn.subm  w0, w12, w16
            bn.addm w12, w12, w16
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.1, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w16, w31, w0 >> 32

            /* Round 8 */

            /* Butterfly */
            bn.subm w0, w1, w9
            bn.addm w1, w1, w9
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.2, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w9, w31, w0 >> 32

            /* Butterfly */
            bn.subm w0, w2, w10
            bn.addm w2, w2, w10
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.2, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w10, w31, w0 >> 32

            /* Butterfly */
            bn.subm w0, w3, w11
            bn.addm w3, w3, w11
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.2, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w11, w31, w0 >> 32

            /* Butterfly */
            bn.subm w0, w4, w12
            bn.addm w4, w4, w12
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.2, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w12, w31, w0 >> 32

            /* Butterfly */
            bn.subm w0, w5, w13
            bn.addm w5, w5, w13
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.2, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w13, w31, w0 >> 32

            /* Butterfly */
            bn.subm w0, w6, w14
            bn.addm w6, w6, w14
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.2, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w14, w31, w0 >> 32

            /* Butterfly */
            bn.subm w0, w7, w15
            bn.addm w7, w7, w15
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.2, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w15, w31, w0 >> 32

            /* Butterfly */
            bn.subm w0, w8, w16
            bn.addm w8, w8, w16
            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w0.0, w30.2, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w16, w31, w0 >> 32

            /* Muliply each coefficient with f = 256^-1 mod q */

            /* Load f into w0 */
            bn.lid x0, 0(x9)

            /* Plantard multiplication: f * w[j] mod q */
            /* t = (f * w[j]) % (2**64) */
            bn.mulqacc.wo.z w1, w1.0, w0.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w1, w31, w1 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w1, w1.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w1, w31, w1 >> 32

            /* Plantard multiplication: f * w[j] mod q */
            /* t = (f * w[j]) % (2**64) */
            bn.mulqacc.wo.z w2, w2.0, w0.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w2, w31, w2 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w2, w2.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w2, w31, w2 >> 32

            /* Plantard multiplication: f * w[j] mod q */
            /* t = (f * w[j]) % (2**64) */
            bn.mulqacc.wo.z w3, w3.0, w0.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w3, w31, w3 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w3, w3.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w3, w31, w3 >> 32

            /* Plantard multiplication: f * w[j] mod q */
            /* t = (f * w[j]) % (2**64) */
            bn.mulqacc.wo.z w4, w4.0, w0.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w4, w31, w4 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w4, w4.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w4, w31, w4 >> 32

            /* Plantard multiplication: f * w[j] mod q */
            /* t = (f * w[j]) % (2**64) */
            bn.mulqacc.wo.z w5, w5.0, w0.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w5, w31, w5 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w5, w5.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w5, w31, w5 >> 32

            /* Plantard multiplication: f * w[j] mod q */
            /* t = (f * w[j]) % (2**64) */
            bn.mulqacc.wo.z w6, w6.0, w0.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w6, w31, w6 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w6, w6.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w6, w31, w6 >> 32

            /* Plantard multiplication: f * w[j] mod q */
            /* t = (f * w[j]) % (2**64) */
            bn.mulqacc.wo.z w7, w7.0, w0.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w7, w31, w7 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w7, w7.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w7, w31, w7 >> 32

            /* Plantard multiplication: f * w[j] mod q */
            /* t = (f * w[j]) % (2**64) */
            bn.mulqacc.wo.z w8, w8.0, w0.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w8, w31, w8 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w8, w8.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w8, w31, w8 >> 32

            /* Plantard multiplication: f * w[j] mod q */
            /* t = (f * w[j]) % (2**64) */
            bn.mulqacc.wo.z w9, w9.0, w0.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w9, w31, w9 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w9, w9.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w9, w31, w9 >> 32

            /* Plantard multiplication: f * w[j] mod q */
            /* t = (f * w[j]) % (2**64) */
            bn.mulqacc.wo.z w10, w10.0, w0.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w10, w31, w10 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w10, w10.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w10, w31, w10 >> 32

            /* Plantard multiplication: f * w[j] mod q */
            /* t = (f * w[j]) % (2**64) */
            bn.mulqacc.wo.z w11, w11.0, w0.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w11, w31, w11 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w11, w11.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w11, w31, w11 >> 32

            /* Plantard multiplication: f * w[j] mod q */
            /* t = (f * w[j]) % (2**64) */
            bn.mulqacc.wo.z w12, w12.0, w0.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w12, w31, w12 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w12, w12.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w12, w31, w12 >> 32

            /* Plantard multiplication: f * w[j] mod q */
            /* t = (f * w[j]) % (2**64) */
            bn.mulqacc.wo.z w13, w13.0, w0.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w13, w31, w13 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w13, w13.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w13, w31, w13 >> 32

            /* Plantard multiplication: f * w[j] mod q */
            /* t = (f * w[j]) % (2**64) */
            bn.mulqacc.wo.z w14, w14.0, w0.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w14, w31, w14 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w14, w14.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w14, w31, w14 >> 32

            /* Plantard multiplication: f * w[j] mod q */
            /* t = (f * w[j]) % (2**64) */
            bn.mulqacc.wo.z w15, w15.0, w0.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w15, w31, w15 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w15, w15.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w15, w31, w15 >> 32

            /* Plantard multiplication: f * w[j] mod q */
            /* t = (f * w[j]) % (2**64) */
            bn.mulqacc.wo.z w16, w16.0, w0.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w16, w31, w16 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w16, w16.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w16, w31, w16 >> 32

            /* Shift the results back into the top of the buffers */
            bn.rshi w17,  w1, w17 >> 32
            bn.rshi w18,  w2, w18 >> 32
            bn.rshi w19,  w3, w19 >> 32
            bn.rshi w20,  w4, w20 >> 32
            bn.rshi w21,  w5, w21 >> 32
            bn.rshi w22,  w6, w22 >> 32
            bn.rshi w23,  w7, w23 >> 32
            bn.rshi w24,  w8, w24 >> 32
            bn.rshi w25,  w9, w25 >> 32
            bn.rshi w26, w10, w26 >> 32
            bn.rshi w27, w11, w27 >> 32
            bn.rshi w28, w12, w28 >> 32
            bn.rshi w29, w13, w29 >> 32

            /* Shift the results back into the top of the temp WDRs */
            /* Write the temp WDR content back to DMEM */
            bn.lid  x14, 832(x10)
            bn.rshi w1, w14, w1 >> 32
            bn.sid  x14, 832(x10)
            bn.lid  x15, 896(x10)
            bn.rshi w2, w15, w2 >> 32
            bn.sid  x15, 896(x10)
            bn.lid  x16, 960(x10)
            bn.rshi w3, w16, w3 >> 32
            bn.sid  x16, 960(x10)

        /* Write back the coefficients from buffers to memory */
        bn.sid x17,    0(x10)
        bn.sid x18,   64(x10)
        bn.sid x19,  128(x10)
        bn.sid x20,  192(x10)
        bn.sid x21,  256(x10)
        bn.sid x22,  320(x10)
        bn.sid x23,  384(x10)
        bn.sid x24,  448(x10)
        bn.sid x25,  512(x10)
        bn.sid x26,  576(x10)
        bn.sid x27,  640(x10)
        bn.sid x28,  704(x10)
        /* Add 32 bytes to the address of ntt_w for the next iteration */
        bn.sid x29,  768(x10++)

    ecall

.data
    .globl ntt_w
    .balign 256
    ntt_w:
    .word 0x0060FC78
    .word 0x002D0230
    .word 0x002A2114
    .word 0x0025C490
    .word 0x0025D781
    .word 0x0038F5B2
    .word 0x00475320
    .word 0x004907AA
    .word 0x00080853
    .word 0x003D7E45
    .word 0x0025C590
    .word 0x0072939A
    .word 0x004807CC
    .word 0x004A34C0
    .word 0x00057204
    .word 0x007006AF
    .word 0x003030BB
    .word 0x006DAA68
    .word 0x0075D2A9
    .word 0x005AC31B
    .word 0x00595FC2
    .word 0x002D0E84
    .word 0x0057A4A4
    .word 0x00471722
    .word 0x002CBA7B
    .word 0x0013EB7E
    .word 0x001B3277
    .word 0x00533D4E
    .word 0x00695224
    .word 0x006195DA
    .word 0x004C799A
    .word 0x002E253D
    .word 0x00015952
    .word 0x000CD7CF
    .word 0x00708758
    .word 0x00285707
    .word 0x00783E7B
    .word 0x005895F8
    .word 0x0014D14B
    .word 0x0038C0F5
    .word 0x00566EDC
    .word 0x001027F6
    .word 0x000C631F
    .word 0x00081F8C
    .word 0x000EA60B
    .word 0x0005ED5E
    .word 0x0035B6B0
    .word 0x005A2A27
    .word 0x006FEA32
    .word 0x0024A266
    .word 0x005BD287
    .word 0x004ED1FD
    .word 0x006A1ED8
    .word 0x006906A0
    .word 0x0053133E
    .word 0x0036AB36
    .word 0x005D0FDF
    .word 0x001E6A3D
    .word 0x00202D00
    .word 0x0014B783
    .word 0x00356821
    .word 0x005AA9C9
    .word 0x0023B661
    .word 0x00088AE9
    .word 0x004FC98E
    .word 0x005B2841
    .word 0x004869BA
    .word 0x004BA979
    .word 0x000634DC
    .word 0x000A10C8
    .word 0x002D8532
    .word 0x000A8611
    .word 0x00736E04
    .word 0x00194D7C
    .word 0x004FA9E0
    .word 0x00139F4F
    .word 0x001A4980
    .word 0x00236D28
    .word 0x0053C904
    .word 0x0077E267
    .word 0x0021D117
    .word 0x0070210B
    .word 0x0021FD42
    .word 0x006388AC
    .word 0x003A435C
    .word 0x005B3E04
    .word 0x007D94D6
    .word 0x00415584
    .word 0x00479C7C
    .word 0x00273C82
    .word 0x003A499F
    .word 0x0046D934
    .word 0x001B043B
    .word 0x0034644C
    .word 0x005E9B3D
    .word 0x007E524B
    .word 0x004006A1
    .word 0x007D72BC
    .word 0x00255C7B
    .word 0x00774D10
    .word 0x0035B779
    .word 0x002BEAD2
    .word 0x006EA3D2
    .word 0x0072D1B5
    .word 0x006B0AD5
    .word 0x002490F9
    .word 0x002C653A
    .word 0x00400209
    .word 0x0050B408
    .word 0x000147F8
    .word 0x0020CD52
    .word 0x0016F475
    .word 0x005268A3
    .word 0x00567E8F
    .word 0x003AAADA
    .word 0x003A1B75
    .word 0x0034D477
    .word 0x000E1CB3
    .word 0x002D25D2
    .word 0x001C40C9
    .word 0x00774F25
    .word 0x006DE42A
    .word 0x002B4340
    .word 0x0047CC89
    .word 0x001724F5
    .word 0x0018E549
    .word 0x001AA9F2
    .word 0x00421954
    .word 0x004777A5
    .word 0x00372DAA
    .word 0x007906B2
    .word 0x00613D41
    .word 0x000C00EB
    .word 0x00183FFE
    .word 0x005C760A
    .word 0x003F8190
    .word 0x004BF439
    .word 0x0012AC2D
    .word 0x007CA0E1
    .word 0x0037D0E4
    .word 0x007A709D
    .word 0x0071D97B
    .word 0x0072DF19
    .word 0x000013DC
    .word 0x002C16E1
    .word 0x0028D750
    .word 0x00574AB4
    .word 0x000C533D
    .word 0x00016016
    .word 0x005FC8F0
    .word 0x0036A32E
    .word 0x003F35F9
    .word 0x000BAAB7
    .word 0x0026A92F
    .word 0x007C6DB5
    .word 0x0074FD65
    .word 0x006D55BA
    .word 0x002BAF75
    .word 0x001376D4
    .word 0x000F12AA
    .word 0x0074430E
    .word 0x007BAB9E
    .word 0x007DD540
    .word 0x007E2968
    .word 0x00555B81
    .word 0x005D2512
    .word 0x00577CCA
    .word 0x001FF1F9
    .word 0x005ED915
    .word 0x007A3581
    .word 0x00254C08
    .word 0x00738226
    .word 0x007291E4
    .word 0x00551691
    .word 0x005CC299
    .word 0x006BB1AB
    .word 0x00220133
    .word 0x005C57B8
    .word 0x0020F375
    .word 0x000BA294
    .word 0x00182FAE
    .word 0x005CDA7A
    .word 0x004DB334
    .word 0x00559F0F
    .word 0x001FAF5B
    .word 0x0042BE26
    .word 0x007E9067
    .word 0x006E5028
    .word 0x000A0E87
    .word 0x0066A710
    .word 0x006E29B7
    .word 0x007A1905
    .word 0x000ED243
    .word 0x00781DCC
    .word 0x0068EFF1
    .word 0x001990FA
    .word 0x006072D5
    .word 0x0057554D
    .word 0x001EC93E
    .word 0x004B58AE
    .word 0x003EF5C4
    .word 0x0028B8CC
    .word 0x002F3631
    .word 0x00595322
    .word 0x002E52AA
    .word 0x007A6755
    .word 0x00311980
    .word 0x00050A4F
    .word 0x00328251
    .word 0x00510941
    .word 0x00160714
    .word 0x006D359C
    .word 0x0013C262
    .word 0x001AE8FD
    .word 0x0026012D
    .word 0x00249BF0
    .word 0x00242A57
    .word 0x001AEF4E
    .word 0x0002A575
    .word 0x001448A4
    .word 0x007884BD
    .word 0x00665BAA
    .word 0x0020AAE0
    .word 0x00372ACB
    .word 0x00300D08
    .word 0x006B2E97
    .word 0x005C8F82
    .word 0x005F7E50
    .word 0x007FBE01
    .word 0x005AC259
    .word 0x0072CEE2
    .word 0x0010D726
    .word 0x00138122
    .word 0x00604FF0
    .word 0x001A96C5
    .word 0x003CB96D
    .word 0x0066A42F
    .word 0x0048166B
    .word 0x0067B4EA
    .word 0x0056A296
    .word 0x00726E0E
    .word 0x000A7921
    .word 0x00614496
    .word 0x000C8E00
    .word 0x0072F994
    .word 0x003863F1
    .word 0x003736EE
    .word 0x001FFDEF
    .word 0x0033FC89
    .word 0x002D6E48
    .word 0x0059DD87
    .word 0x002CC657
    .word 0x0053C105
    .word 0x002D7B43
    .word 0x00692453
    .word 0x0051FD00

    .globl ntt_modified_zetas
    .balign 256
    ntt_modified_zetas:
    .word 0xC39D4BCC
    .word 0x1657E9CD
    .word 0x19D90A0F
    .word 0xDFC9D6B6
    .word 0xD5387E76
    .word 0x17E25E67
    .word 0x87B65A88
    .word 0xC5F555C9
    .word 0x299CA8D7
    .word 0x734716DF
    .word 0x0179C26E
    .word 0x7969034E
    .word 0x8843B9DE
    .word 0x94214F2B
    .word 0x10EF9BC6
    .word 0x09418A50
    .word 0x8AB2FBAA
    .word 0xCAB5B7D8
    .word 0x6EDB07E5
    .word 0x44538057
    .word 0x768E6AAE
    .word 0x3AB8479C
    .word 0x5C39C9BA
    .word 0x74A62EA2
    .word 0x55770316
    .word 0xC73AEF2D
    .word 0xC0B585E1
    .word 0x99CA1D53
    .word 0xF77252A6
    .word 0xBA3CE5C4
    .word 0x00000000
    .word 0x00000000
    .word 0x6C4FC118
    .word 0x0BFF05A9
    .word 0xCEBB5B3A
    .word 0xA69DDC29
    .word 0x1DD76BA0
    .word 0x3471B805
    .word 0xFA657369
    .word 0x5C152C92
    .word 0x45D7634E
    .word 0x42FE3D09
    .word 0x0CDB7CC6
    .word 0xB7F533DD
    .word 0x444DB4E5
    .word 0xA093C1AF
    .word 0x59C7A937
    .word 0x42BFA764
    .word 0x2BFAFA67
    .word 0x47EA4802
    .word 0x18D3ACBA
    .word 0xE11C1944
    .word 0x306A5A36
    .word 0x0A03D0E0
    .word 0xD8B9E4C8
    .word 0xF5583E24
    .word 0x4E1B262E
    .word 0xC75EFC30
    .word 0x88D7CEE3
    .word 0xA6E20533
    .word 0x857D5E4D
    .word 0xA9FD5200
    .word 0x00000000
    .word 0x00000000
    .word 0x751D907A
    .word 0x2E40DFDB
    .word 0x07F64983
    .word 0xFBB745DA
    .word 0x21BC08BF
    .word 0x97358633
    .word 0x32EF8B7E
    .word 0xE5B98E98
    .word 0xC5A4999C
    .word 0x10EA2667
    .word 0x371468AD
    .word 0xF07A3CAE
    .word 0xCB5936B7
    .word 0x21B44CCF
    .word 0x0D08B814
    .word 0xA1221D45
    .word 0xD7069DFA
    .word 0x0E06B791
    .word 0xD7CFEA4B
    .word 0x13F4B304
    .word 0x056B9ADC
    .word 0xB9594AE0
    .word 0x49993FBD
    .word 0x69ED9C93
    .word 0x8971B75B
    .word 0x89C59852
    .word 0xE2D9CAAD
    .word 0xEEFD4F75
    .word 0x0097E1F8
    .word 0x6D83F422
    .word 0x00000000
    .word 0x00000000
    .word 0xF1944930
    .word 0x1788F40D
    .word 0xCB87142E
    .word 0xEF5715E6
    .word 0x1DCF8BA8
    .word 0xF96F9BF4
    .word 0xBC652BD3
    .word 0x9940A4F6
    .word 0xF7C270AD
    .word 0xA3BC1DBF
    .word 0x89E04F00
    .word 0x29DDA114
    .word 0x945AA581
    .word 0x005CE538
    .word 0x5CD4BC76
    .word 0x85F9213C
    .word 0x388E371D
    .word 0x54E27FF6
    .word 0x9F7A5B58
    .word 0xAE0876C1
    .word 0x6C8B11EC
    .word 0x54CAC808
    .word 0xFA35B579
    .word 0xD690646B
    .word 0xEFC4BD50
    .word 0x9E7B5B99
    .word 0xE7327CD1
    .word 0x588163A7
    .word 0xCA522AF7
    .word 0x13A17034
    .word 0x00000000
    .word 0x00000000
    .word 0x36F542E3
    .word 0x66EC2C3D
    .word 0x70D96779
    .word 0xDC748167
    .word 0xCD842D71
    .word 0xC20C7799
    .word 0xE7408654
    .word 0xCD20FCA4
    .word 0xA3EE1A3F
    .word 0xCB5C1D70
    .word 0xCE9F9849
    .word 0x3159AA07
    .word 0xFB0689AD
    .word 0xB185FC1B
    .word 0x613ED2F3
    .word 0x86672CBE
    .word 0x2839FE30
    .word 0x98ECE808
    .word 0xE8C8F06B
    .word 0xA69FB8A0
    .word 0x0671DE6B
    .word 0x2578A7DF
    .word 0xB702E94D
    .word 0x88D1F56B
    .word 0x8EFCA80D
    .word 0x78A9F38B
    .word 0x30E3807F
    .word 0x3473145C
    .word 0x641FD72E
    .word 0xD360FC98
    .word 0x00000000
    .word 0x00000000
    .word 0x24E1EA31
    .word 0x7AE273A7
    .word 0xFA551F54
    .word 0xE91A34BA
    .word 0x99151614
    .word 0x81466897
    .word 0xC435DDF0
    .word 0x4FD0DD97
    .word 0x050823FF
    .word 0xA40F5C8F
    .word 0xB505D40B
    .word 0xAF1C53B6
    .word 0xB5B2572B
    .word 0x0A567D8A
    .word 0x3D82B032
    .word 0x5CAC4658
    .word 0x6345508E
    .word 0xED0669C0
    .word 0xCD80D09A
    .word 0xA3423947
    .word 0x004314C5
    .word 0xB4CF9E7E
    .word 0x71C4DC54
    .word 0x28406BCA
    .word 0x41642A88
    .word 0x3B223617
    .word 0x94DCBA05
    .word 0x8D3D643E
    .word 0x2AC0C1DB
    .word 0xB50984F7
    .word 0x00000000
    .word 0x00000000
    .word 0x73609940
    .word 0x380A3E1F
    .word 0xEDD9C696
    .word 0x162410D7
    .word 0x71C44C30
    .word 0x24496C12
    .word 0x4EF185C4
    .word 0xF07BF11B
    .word 0x386B6C6B
    .word 0x2A8EB157
    .word 0x330CD2CF
    .word 0xB3E57FF8
    .word 0x568187B5
    .word 0xC3164A0C
    .word 0x1091BC4E
    .word 0x2D1E3934
    .word 0x871311B7
    .word 0x4827A759
    .word 0xE45E8FDC
    .word 0x27B64D43
    .word 0x219AEA78
    .word 0x7FC6F6BE
    .word 0xFEA5A96E
    .word 0x95A0ACFF
    .word 0x74BE7CB6
    .word 0x6D30CF59
    .word 0x94E8FF16
    .word 0x18F93E1D
    .word 0x75E7AAFF
    .word 0xCBA1FAE7
    .word 0x00000000
    .word 0x00000000
    .word 0x97F45FE9
    .word 0x53CDD8CE
    .word 0xBBB31D50
    .word 0xEFDF1DE7
    .word 0xE84242C1
    .word 0x2408BBE6
    .word 0xD22C817D
    .word 0xEE178404
    .word 0x29FF2576
    .word 0x3E20A5AD
    .word 0x4DC88185
    .word 0x48882578
    .word 0xC5702A80
    .word 0xBFB06098
    .word 0x27171F7A
    .word 0x3196D953
    .word 0xA15D4810
    .word 0x44E04587
    .word 0xF073EF1B
    .word 0x490AA416
    .word 0xF7E81A17
    .word 0xC9620AEF
    .word 0x6621B5A2
    .word 0x4ECA1BE9
    .word 0x3236E154
    .word 0xCA41AAD6
    .word 0x33E87FB9
    .word 0x97ADB23D
    .word 0x40B4809F
    .word 0x629A6DD6
    .word 0x00000000
    .word 0x00000000
    .word 0x3BF42091
    .word 0x428FCD6E
    .word 0x9B01BB39
    .word 0x1902D282
    .word 0xD7E86C6C
    .word 0x396CE6C6
    .word 0x0DC7A9CF
    .word 0xC1B59DE4
    .word 0x2BB08DCD
    .word 0x6A100D2F
    .word 0x655CDA6C
    .word 0x84951E3E
    .word 0xDA345762
    .word 0x3AB6411A
    .word 0x28B8B1DC
    .word 0x0E0368BE
    .word 0x2BB22833
    .word 0x9C766C62
    .word 0xC7671437
    .word 0x6348A562
    .word 0xD6CA0AD6
    .word 0xF8CF15D3
    .word 0x0BAB30B5
    .word 0xCAF5CBDD
    .word 0x10796439
    .word 0xBE23655D
    .word 0xB840D8C6
    .word 0x9CF7569B
    .word 0x406923C9
    .word 0x28CF337B
    .word 0x00000000
    .word 0x00000000
    .word 0x201ABA6F
    .word 0x43C4B6A6
    .word 0xC5DAE12D
    .word 0x28066B4A
    .word 0xC6E73C42
    .word 0xED44653E
    .word 0x5B75CABC
    .word 0x29637089
    .word 0x6C63F826
    .word 0xB33BDB90
    .word 0xAF7ABD51
    .word 0x02BA5890
    .word 0xD9CCF78B
    .word 0xFBAAD4BD
    .word 0x731293BF
    .word 0xA4698518
    .word 0x27F60F34
    .word 0x61AAE9F7
    .word 0x00B3B6ED
    .word 0xC347063B
    .word 0x25873B84
    .word 0x6A8FA113
    .word 0x14801BDE
    .word 0x7F460282
    .word 0x092DB15A
    .word 0x7AC50A4D
    .word 0x93DCF817
    .word 0xC0B603FF
    .word 0xAFF92EEC
    .word 0xEB54F967
    .word 0x00000000
    .word 0x00000000
    .word 0xCF3F4433
    .word 0x00611A45
    .word 0xB40C61B1
    .word 0xD9B01050
    .word 0xD9E37129
    .word 0xAF438983
    .word 0x841ED0AC
    .word 0x9E61611B
    .word 0xD95B752B
    .word 0x75416D70
    .word 0x4F1F5337
    .word 0xDA1FBA3A
    .word 0xADC840B5
    .word 0xB9DC3198
    .word 0xA92C81CF
    .word 0x8D87FEE4
    .word 0x4BAAD81F
    .word 0x65DB5409
    .word 0x0C8E497A
    .word 0xB4C75A6D
    .word 0x70D39E06
    .word 0xFAD1044B
    .word 0x5AA76324
    .word 0x114717A3
    .word 0x579963AA
    .word 0x6B1C5E41
    .word 0x92CF88BD
    .word 0xDE894A95
    .word 0x22334C8F
    .word 0x0D42EAA0
    .word 0x00000000
    .word 0x00000000
    .word 0xF9CC2B18
    .word 0x61279923
    .word 0xCAF930B7
    .word 0x08335CC6
    .word 0x66190F78
    .word 0x6E54603B
    .word 0x96FFF2CF
    .word 0xB71152E6
    .word 0x82806B16
    .word 0x34C2101A
    .word 0x4A781B72
    .word 0xBD02ED41
    .word 0xF73BB700
    .word 0x3625E10B
    .word 0xF58B30E2
    .word 0x7EA85918
    .word 0xAD0E0628
    .word 0x5A7D4E9E
    .word 0xBE63294E
    .word 0xDCE7C637
    .word 0x1E0A7863
    .word 0xF1419E85
    .word 0x97C40DD4
    .word 0xD15250F1
    .word 0x5CFA45D8
    .word 0xE3A10E7C
    .word 0x75F271B1
    .word 0xF3F5B585
    .word 0x10C91223
    .word 0x6BA99D90
    .word 0x00000000
    .word 0x00000000
    .word 0x6DD7F121
    .word 0x4B0161C2
    .word 0x177ABA80
    .word 0x07A68592
    .word 0x100A5676
    .word 0xEC92BCD6
    .word 0x6CA82F33
    .word 0x6C79597D
    .word 0x9E0876E2
    .word 0x7321AF85
    .word 0xC1EF745A
    .word 0xAE2F8083
    .word 0x5F61EBBD
    .word 0x682F1AF6
    .word 0x1404BF08
    .word 0x337A2021
    .word 0xFC1F73E5
    .word 0x80FB2FC9
    .word 0x6EF9FDA2
    .word 0x21E490E0
    .word 0x6072BFF0
    .word 0x5B2592AE
    .word 0x61735C15
    .word 0xAA1F5280
    .word 0x8864BC1F
    .word 0xDC919EAE
    .word 0x4D83B854
    .word 0x8ED3C7D4
    .word 0x92758E3F
    .word 0x3327B787
    .word 0x00000000
    .word 0x00000000
    .word 0x0FF60562
    .word 0x72D786FC
    .word 0x01524C91
    .word 0x78DFD704
    .word 0x31473D6D
    .word 0xCF38A28A
    .word 0xF0DD316B
    .word 0x3C77EF82
    .word 0xE6FB0AF5
    .word 0x4AF7BF59
    .word 0xE4374209
    .word 0xE12AA0E5
    .word 0xC73599D9
    .word 0xE6DF9E19
    .word 0xE47C6350
    .word 0x00D97E5D
    .word 0x1E8DB731
    .word 0x748F7CF6
    .word 0x7CBE4A9A
    .word 0xC4CFF072
    .word 0xC4C24D0A
    .word 0xC20BD771
    .word 0x266AB060
    .word 0xB35B6F75
    .word 0x6DBB15EB
    .word 0xBFCEB02C
    .word 0x32C2AA46
    .word 0x5F070503
    .word 0x20FCF6FC
    .word 0xAEA405A4
    .word 0x00000000
    .word 0x00000000
    .word 0x618CA667
    .word 0x718B05DE
    .word 0x24927855
    .word 0x64587B56
    .word 0x72D6BCCA
    .word 0x462622FC
    .word 0x6B89A192
    .word 0x78DE48A0
    .word 0x94AE7274
    .word 0x79213B5C
    .word 0x25BF8F99
    .word 0xEC8B24F0
    .word 0xB5A25B2C
    .word 0xFD560586
    .word 0xF7D80C14
    .word 0xDBE2B2F4
    .word 0x306CA4C9
    .word 0x085F2FBB
    .word 0xBD83D37A
    .word 0x5F5A15C6
    .word 0x95D1993B
    .word 0x6272C9ED
    .word 0x2C5E5D3F
    .word 0x8035765D
    .word 0x942780B8
    .word 0x6D8E7EC4
    .word 0xA1FEE676
    .word 0xAC4894CC
    .word 0xE0B74E13
    .word 0x7C1DA06F
    .word 0x00000000
    .word 0x00000000
    .word 0x6CD2EFE3
    .word 0xAB4DE422
    .word 0x4ABB7047
    .word 0x01CE8B9F
    .word 0xBB72E743
    .word 0x36619DFA
    .word 0x661AA1DD
    .word 0xAEBB3F72
    .word 0x8B5EE8A4
    .word 0x2C7941F7
    .word 0xB93CA7B8
    .word 0x513DD8D3
    .word 0x97E746A2
    .word 0x3B1F3F59
    .word 0xC01AE139
    .word 0xFFF24A92
    .word 0x5CE70708
    .word 0x8A54B819
    .word 0x7058773E
    .word 0x5081C1CF
    .word 0x2EB2AA4E
    .word 0xD8F8CC81
    .word 0x7810391F
    .word 0xA220A6E5
    .word 0xFD1304C8
    .word 0x9EC5761F
    .word 0xAD568848
    .word 0x91F62A66
    .word 0xACBE8047
    .word 0x66F49657
    .word 0x00000000
    .word 0x00000000


/* The modulus and the first 15 Zetas need to be loaded into */
/* the scratchpad since the data region is not big enough. */
.section .scratchpad
    .globl modulus
    .balign 32
    modulus:
    .zero 32

    .globl ntt_f
    .balign 32
    ntt_f:
    .zero 32

    .globl ntt_modified_zetas_scratch
    .balign 256
    ntt_modified_zetas_scratch:
    .zero 128
