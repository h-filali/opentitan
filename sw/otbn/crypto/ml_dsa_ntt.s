.section .text.start
    /* Zero some registers */
    bn.xor  w0,  w0,  w0

    /* Set up constants for input/state */
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

    /* Load the first 15 Zetas into the scratchpad */
    li x8, 0x00CA2087
    sw x8, 0(x13)
    li x9, 0x92E0BB09
    sw x9, 4(x13)
    li x8, 0xB04E1826
    sw x8, 8(x13)
    li x9, 0x73078EFD
    sw x9, 12(x13)
    li x8, 0xF0260FA4
    sw x8, 16(x13)
    li x9, 0x72E78AFC
    sw x9, 20(x13)
    li x8, 0x073E5788
    sw x8, 24(x13)
    li x9, 0x9E33E1BC
    sw x9, 28(x13)
    li x8, 0xE83C3F40
    sw x8, 32(x13)
    li x9, 0xA7E8DEE7
    sw x9, 36(x13)
    li x8, 0xE53B9F1E
    sw x8, 40(x13)
    li x9, 0x9FE85ED7
    sw x9, 44(x13)
    li x8, 0x0E3FD7DA
    sw x8, 48(x13)
    li x9, 0x9E3461DC
    sw x9, 52(x13)
    li x8, 0x37CA4823
    sw x8, 56(x13)
    li x9, 0xED9EC1D5
    sw x9, 60(x13)
    li x8, 0x47E44E84
    sw x8, 64(x13)
    li x9, 0x6C36B6D5
    sw x9, 68(x13)
    li x8, 0xF5069BBD
    sw x8, 72(x13)
    li x9, 0x51EFDB52
    sw x9, 76(x13)
    li x8, 0xC01904C1
    sw x8, 80(x13)
    li x9, 0x41100B80
    sw x9, 84(x13)
    li x8, 0x5F4CBC71
    sw x8, 88(x13)
    li x9, 0x7301C58B
    sw x9, 92(x13)
    li x8, 0xA7E00AB3
    sw x8, 96(x13)
    li x9, 0xE14AE4F6
    sw x9, 100(x13)
    li x8, 0x5F0C5457
    sw x8, 104(x13)
    li x9, 0x110765B7
    sw x9, 108(x13)
    li x8, 0x51DEC50E
    sw x8, 112(x13)
    li x9, 0xDAB23AD9
    sw x9, 116(x13)
    li x9, 0x00000000
    sw x9, 120(x13)
    sw x9, 124(x13)

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

    loopi 2, 264
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

        loopi 8, 237
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

            /* Round 1 */

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w9.0, w30.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w9, w1, w0
            bn.addm w1, w1, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w10.0, w30.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w10, w2, w0
            bn.addm w2, w2, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w11.0, w30.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w11, w3, w0
            bn.addm w3, w3, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w12.0, w30.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w12, w4, w0
            bn.addm w4, w4, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w13.0, w30.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w13, w5, w0
            bn.addm w5, w5, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w14.0, w30.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w14, w6, w0
            bn.addm w6, w6, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w15.0, w30.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w15, w7, w0
            bn.addm w7, w7, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w16.0, w30.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w16, w8, w0
            bn.addm w8, w8, w0

            /* Round 2 */

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w5.0, w30.1, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w5, w1, w0
            bn.addm w1, w1, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w6.0, w30.1, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w6, w2, w0
            bn.addm w2, w2, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w7.0, w30.1, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w7, w3, w0
            bn.addm w3, w3, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w8.0, w30.1, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w8, w4, w0
            bn.addm w4, w4, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w13.0, w30.2, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w13, w9, w0
            bn.addm w9, w9, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w14.0, w30.2, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w14, w10, w0
            bn.addm w10, w10, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w15.0, w30.2, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w15, w11, w0
            bn.addm w11, w11, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w16.0, w30.2, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w16, w12, w0
            bn.addm w12, w12, w0

            /* Round 3 */

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w3.0, w30.3, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w3, w1, w0
            bn.addm w1, w1, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w4.0, w30.3, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w4, w2, w0
            bn.addm w2, w2, w0

            /* Load next 4 zetas into the zetas register */
            bn.lid x30, 32(x13)

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w7.0, w30.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w7, w5, w0
            bn.addm w5, w5, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w8.0, w30.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w8, w6, w0
            bn.addm w6, w6, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w11.0, w30.1, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w11, w9, w0
            bn.addm w9, w9, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w12.0, w30.1, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w12, w10, w0
            bn.addm w10, w10, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w15.0, w30.2, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w15, w13, w0
            bn.addm w13, w13, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w16.0, w30.2, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w16, w14, w0
            bn.addm w14, w14, w0

            /* Round 4 */

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w2.0, w30.3, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w2, w1, w0
            bn.addm w1, w1, w0

            /* Load next 4 zetas into the zetas register */
            bn.lid x30, 64(x13)

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w4.0, w30.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w4, w3, w0
            bn.addm w3, w3, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w6.0, w30.1, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w6, w5, w0
            bn.addm w5, w5, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w8.0, w30.2, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w8, w7, w0
            bn.addm w7, w7, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w10.0, w30.3, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w10, w9, w0
            bn.addm w9, w9, w0

            /* Load next 4 zetas into the zetas register */
            bn.lid x30, 96(x13)

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w12.0, w30.0, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w12, w11, w0
            bn.addm w11, w11, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w14.0, w30.1, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w14, w13, w0
            bn.addm w13, w13, w0

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z w0, w16.0, w30.2, 192
            /* t = (t >> 32) + 1 */
            bn.add w0, w31, w0 >> 96
            /* t *= q */
            bn.mulqacc.wo.z w0, w0.2, w31.1, 0
            /* t = t >> 32 */
            bn.rshi w0, w31, w0 >> 32
            /* Butterfly */
            bn.subm w16, w15, w0
            bn.addm w15, w15, w0

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

    /* Set x10 back to its original value */
    addi x10, x10, -64

    /* Create mask */
    bn.xor w0, w0, w0
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

        /* Round 5 */

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w9.0, w30.0, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w9, w1, w0
        bn.addm w1, w1, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w10.0, w30.0, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w10, w2, w0
        bn.addm w2, w2, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w11.0, w30.0, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w11, w3, w0
        bn.addm w3, w3, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w12.0, w30.0, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w12, w4, w0
        bn.addm w4, w4, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w13.0, w30.0, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w13, w5, w0
        bn.addm w5, w5, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w14.0, w30.0, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w14, w6, w0
        bn.addm w6, w6, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w15.0, w30.0, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w15, w7, w0
        bn.addm w7, w7, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w16.0, w30.0, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w16, w8, w0
        bn.addm w8, w8, w0

        /* Round 6 */

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w5.0, w30.1, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w5, w1, w0
        bn.addm w1, w1, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w6.0, w30.1, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w6, w2, w0
        bn.addm w2, w2, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w7.0, w30.1, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w7, w3, w0
        bn.addm w3, w3, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w8.0, w30.1, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w8, w4, w0
        bn.addm w4, w4, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w13.0, w30.2, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w13, w9, w0
        bn.addm w9, w9, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w14.0, w30.2, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w14, w10, w0
        bn.addm w10, w10, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w15.0, w30.2, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w15, w11, w0
        bn.addm w11, w11, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w16.0, w30.2, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w16, w12, w0
        bn.addm w12, w12, w0

        /* Round 7 */

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w3.0, w30.3, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w3, w1, w0
        bn.addm w1, w1, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w4.0, w30.3, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w4, w2, w0
        bn.addm w2, w2, w0

        /* Load next 4 zetas into the zetas register */
        bn.lid x30, 0(x11++)

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w7.0, w30.0, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w7, w5, w0
        bn.addm w5, w5, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w8.0, w30.0, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w8, w6, w0
        bn.addm w6, w6, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w11.0, w30.1, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w11, w9, w0
        bn.addm w9, w9, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w12.0, w30.1, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w12, w10, w0
        bn.addm w10, w10, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w15.0, w30.2, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w15, w13, w0
        bn.addm w13, w13, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w16.0, w30.2, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w16, w14, w0
        bn.addm w14, w14, w0

        /* Round 8 */

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w2.0, w30.3, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w2, w1, w0
        bn.addm w1, w1, w0

        /* Load next 4 zetas into the zetas register */
        bn.lid x30, 0(x11++)

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w4.0, w30.0, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w4, w3, w0
        bn.addm w3, w3, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w6.0, w30.1, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w6, w5, w0
        bn.addm w5, w5, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w8.0, w30.2, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w8, w7, w0
        bn.addm w7, w7, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w10.0, w30.3, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w10, w9, w0
        bn.addm w9, w9, w0

        /* Load next 4 zetas into the zetas register */
        bn.lid x30, 0(x11++)

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w12.0, w30.0, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w12, w11, w0
        bn.addm w11, w11, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w14.0, w30.1, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w14, w13, w0
        bn.addm w13, w13, w0

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z w0, w16.0, w30.2, 192
        /* t = (t >> 32) + 1 */
        bn.add w0, w31, w0 >> 96
        /* t *= q */
        bn.mulqacc.wo.z w0, w0.2, w31.1, 0
        /* t = t >> 32 */
        bn.rshi w0, w31, w0 >> 32
        /* Butterfly */
        bn.subm w16, w15, w0
        bn.addm w15, w15, w0

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
    .word 0x53417FBA
    .word 0x990B69A8
    .word 0x52A977B9
    .word 0x6E09D599
    .word 0x02ECFB39
    .word 0x613A89E0
    .word 0x87EFC6E2
    .word 0x5DDF591A
    .word 0xD14D55B3
    .word 0x2707337E
    .word 0x8FA788C3
    .word 0xAF7E3E30
    .word 0xA318F8F9
    .word 0x75AB47E6
    .word 0x3FE51EC8
    .word 0x000DB56D
    .word 0x6818B95F
    .word 0xC4E0C0A6
    .word 0x46C35849
    .word 0xAEC2272C
    .word 0x74A1175D
    .word 0xD386BE08
    .word 0x99E55E24
    .word 0x5144C08D
    .word 0x448D18BE
    .word 0xC99E6205
    .word 0xB5448FBA
    .word 0xFE317460
    .word 0x932D101E
    .word 0x54B21BDD
    .word 0x00000000
    .word 0x00000000
    .word 0x1F48B1EE
    .word 0x83E25F90
    .word 0x5E01198B
    .word 0x53B76B33
    .word 0x6BD87F49
    .word 0x9271813B
    .word 0xD3A1A2C2
    .word 0x7FCA89A2
    .word 0x6A2E66C6
    .word 0x9D8D3612
    .word 0x427C2C87
    .word 0xA0A5EA39
    .word 0xCF935B38
    .word 0xF7A0D044
    .word 0x0827F3ED
    .word 0x241D4D0B
    .word 0x4A5DA4D5
    .word 0x02A9FA79
    .word 0xDA407068
    .word 0x1374DB0F
    .word 0x6B518D8D
    .word 0x86DEC4A3
    .word 0x94765E6F
    .word 0x8721B75F
    .word 0x8D294337
    .word 0xB9D9DD03
    .word 0xDB6D87AC
    .word 0x9BA784A9
    .word 0x9E73599A
    .word 0x8E74FA21
    .word 0x00000000
    .word 0x00000000
    .word 0xDF030905
    .word 0x515BFA5B
    .word 0xCD3D55BB
    .word 0xA0F8FAFC
    .word 0x9244EA16
    .word 0x40314FD3
    .word 0xD9954FA1
    .word 0x4CA4908A
    .word 0x3B3DB2F7
    .word 0x3DF4288E
    .word 0x8341B567
    .word 0x3B300F8D
    .word 0xE17248D0
    .word 0x8B708309
    .word 0x1B839CB1
    .word 0xFF2681A2
    .word 0x38CA6628
    .word 0x192061E6
    .word 0x1BC8BDF8
    .word 0x1ED55F1A
    .word 0x1904F50C
    .word 0xB50840A6
    .word 0x0F22CE96
    .word 0xC388107D
    .word 0xCEB8C294
    .word 0x30C75D75
    .word 0xFEADB370
    .word 0x872028FB
    .word 0xF009FA9F
    .word 0x8D287903
    .word 0x00000000
    .word 0x00000000
    .word 0x6D8A71C2
    .word 0xCCD84878
    .word 0xB27C47AD
    .word 0x712C382B
    .word 0x779B43E2
    .word 0x236E6151
    .word 0x9E8CA3EC
    .word 0x55E0AD7F
    .word 0x9F8D4011
    .word 0xA4DA6D51
    .word 0x9106025F
    .word 0xDE1B6F1F
    .word 0x03E08C1C
    .word 0x7F04D036
    .word 0xEBFB40F9
    .word 0xCC85DFDE
    .word 0xA09E1444
    .word 0x97D0E509
    .word 0x3E108BA7
    .word 0x51D07F7C
    .word 0x61F7891F
    .word 0x8CDE507A
    .word 0x9357D0CE
    .word 0x9386A682
    .word 0xEFF5A98B
    .word 0x136D4329
    .word 0xE8854581
    .word 0xF8597A6D
    .word 0x92280EE0
    .word 0xB4FE9E3D
    .word 0x00000000
    .word 0x00000000
    .word 0xEF36EDDE
    .word 0x9456626F
    .word 0x8A0D8E50
    .word 0x0C0A4A7A
    .word 0xA305BA29
    .word 0x1C5EF183
    .word 0x683BF22D
    .word 0x2EADAF0E
    .word 0xE1F5879E
    .word 0x0EBE617A
    .word 0x419CD6B3
    .word 0x231839C8
    .word 0x52F1F9D9
    .word 0xA582B161
    .word 0x0A74CF1F
    .word 0x8157A6E7
    .word 0x08C44901
    .word 0xC9DA1EF4
    .word 0xB587E48F
    .word 0x42FD12BE
    .word 0x7D7F94EB
    .word 0xCB3DEFE5
    .word 0x69000D32
    .word 0x48EEAD19
    .word 0x99E6F089
    .word 0x91AB9FC4
    .word 0x3506CF4A
    .word 0xF7CCA339
    .word 0x0633D4E9
    .word 0x9ED866DC
    .word 0x00000000
    .word 0x00000000
    .word 0xDDCCB372
    .word 0xF2BD155F
    .word 0x6D307744
    .word 0x2176B56A
    .word 0xA8669C57
    .word 0x94E3A1BE
    .word 0xA5589CDD
    .word 0xEEB8E85C
    .word 0x8F2C61FB
    .word 0x052EFBB4
    .word 0xF371B687
    .word 0x4B38A592
    .word 0xB45527E2
    .word 0x9A24ABF6
    .word 0x56D37E32
    .word 0x7278011B
    .word 0x5237BF4C
    .word 0x4623CE67
    .word 0xB0E0ACCA
    .word 0x25E045C5
    .word 0x26A48AD6
    .word 0x8ABE928F
    .word 0x7BE12F55
    .word 0x619E9EE4
    .word 0x261C8ED8
    .word 0x50BC767C
    .word 0x4BF39E50
    .word 0x264FEFAF
    .word 0x30C0BBCE
    .word 0xFF9EE5BA
    .word 0x00000000
    .word 0x00000000
    .word 0x5006D115
    .word 0x14AB0698
    .word 0x6C2307EA
    .word 0x3F49FC00
    .word 0xF6D24EA7
    .word 0x853AF5B2
    .word 0xEB7FE423
    .word 0x80B9FD7D
    .word 0xDA78C47D
    .word 0x95705EEC
    .word 0xFF4C4914
    .word 0x3CB8F9C4
    .word 0xD809F0CD
    .word 0x9E551608
    .word 0x8CED6C42
    .word 0x5B967AE7
    .word 0x26330876
    .word 0x04552B42
    .word 0x508542B0
    .word 0xFD45A76F
    .word 0x939C07DB
    .word 0x4CC4246F
    .word 0xA48A3545
    .word 0xD69C8F76
    .word 0x3918C3BF
    .word 0x12BB9AC1
    .word 0x3A251ED4
    .word 0xD7F994B5
    .word 0xDFE54592
    .word 0xBC3B4959
    .word 0x00000000
    .word 0x00000000
    .word 0xBF96DC38
    .word 0xD730CC84
    .word 0x47BF273B
    .word 0x6308A964
    .word 0xEF869BC8
    .word 0x41DC9AA2
    .word 0xF454CF4C
    .word 0x350A3422
    .word 0x2935F52B
    .word 0x0730EA2C
    .word 0x3898EBCA
    .word 0x9CB75A9D
    .word 0xD44DD7CE
    .word 0x6389939D
    .word 0xD7474E25
    .word 0xF1FC9741
    .word 0x25CBA89F
    .word 0xC549BEE5
    .word 0x9AA32595
    .word 0x7B6AE1C1
    .word 0xD44F7234
    .word 0x95EFF2D0
    .word 0xF2385632
    .word 0x3E4A621B
    .word 0x28179395
    .word 0xC6931939
    .word 0x64FE44C8
    .word 0xE6FD2D7D
    .word 0xC40BDF70
    .word 0xBD703291
    .word 0x00000000
    .word 0x00000000
    .word 0xBF4B7F62
    .word 0x9D659229
    .word 0xCC178048
    .word 0x68524DC2
    .word 0xCDC91EAD
    .word 0x35BE5529
    .word 0x99DE4A5F
    .word 0xB135E416
    .word 0x0817E5EA
    .word 0x369DF510
    .word 0x0F8C10E6
    .word 0xB6F55BE9
    .word 0x5EA2B7F1
    .word 0xBB1FBA78
    .word 0xD8E8E087
    .word 0xCE6926AC
    .word 0x3A8FD581
    .word 0x404F9F67
    .word 0xB2377E7C
    .word 0xB777DA87
    .word 0xD600DA8B
    .word 0xC1DF5A52
    .word 0x2DD37E84
    .word 0x11E87BFB
    .word 0x17BDBD40
    .word 0xDBF74419
    .word 0x444CE2B1
    .word 0x1020E218
    .word 0x680BA018
    .word 0xAC322731
    .word 0x00000000
    .word 0x00000000
    .word 0x8A185502
    .word 0x345E0518
    .word 0x6B1700EB
    .word 0xE706C1E2
    .word 0x8B41834B
    .word 0x92CF30A6
    .word 0x015A5693
    .word 0x6A5F5300
    .word 0xDE651589
    .word 0x80390941
    .word 0x1BA17025
    .word 0xD849B2BC
    .word 0x78ECEE4A
    .word 0xB7D858A6
    .word 0xEF6E43B3
    .word 0xD2E1C6CB
    .word 0xA97E784C
    .word 0x3CE9B5F3
    .word 0xCCF32D32
    .word 0x4C1A8007
    .word 0xC7949396
    .word 0xD5714EA8
    .word 0xB10E7A3D
    .word 0x0F840EE4
    .word 0x8E3BB3D1
    .word 0xDBB693ED
    .word 0x1226396B
    .word 0xE9DBEF28
    .word 0x8C9F66C1
    .word 0xC7F5C1E0
    .word 0x00000000
    .word 0x00000000
    .word 0xD53F3E26
    .word 0x4AF67B08
    .word 0x6B2345FC
    .word 0x72C29BC1
    .word 0xBE9BD579
    .word 0xC4DDC9E8
    .word 0x8E3B23AD
    .word 0xD7BF9435
    .word 0xFFBCEB3C
    .word 0x4B306181
    .word 0x327F2F67
    .word 0x5CBDC6B8
    .word 0x9CBAAF73
    .word 0x12F9963F
    .word 0xC27D4FCF
    .word 0xA353B9A7
    .word 0x4A4DA8D6
    .word 0xF5A98275
    .word 0x4AFA2BF6
    .word 0x50E3AC49
    .word 0xFAF7DC02
    .word 0x5BF0A370
    .word 0x3BCA2211
    .word 0xB02F2268
    .word 0x66EAE9ED
    .word 0x7EB99768
    .word 0x05AAE0AD
    .word 0x16E5CB45
    .word 0xDB1E15D0
    .word 0x851D8C58
    .word 0x00000000
    .word 0x00000000
    .word 0x9BE028D3
    .word 0x2C9F0367
    .word 0xCF1C7F82
    .word 0xCB8CEBA3
    .word 0x710357F4
    .word 0x87560C74
    .word 0x48FD16B4
    .word 0x772E0A94
    .word 0xF98E2196
    .word 0xDA875820
    .word 0x17370F96
    .word 0x5960475F
    .word 0xD7C601D1
    .word 0x671317F7
    .word 0x9EC12D0E
    .word 0x7998D341
    .word 0x04F97654
    .word 0x4E7A03E4
    .word 0x316067B8
    .word 0xCEA655F8
    .word 0x5C11E5C2
    .word 0x34A3E28F
    .word 0x18BF79AD
    .word 0x32DF035B
    .word 0x327BD290
    .word 0x3DF38866
    .word 0x8F269888
    .word 0x238B7E98
    .word 0xC90ABD1E
    .word 0x9913D3C2
    .word 0x00000000
    .word 0x00000000
    .word 0x35ADD50A
    .word 0xEC5E8FCB
    .word 0x18CD8330
    .word 0xA77E9C58
    .word 0x103B42B1
    .word 0x6184A466
    .word 0x05CA4A88
    .word 0x296F9B94
    .word 0x9374EE15
    .word 0xAB3537F7
    .word 0x6085A4A9
    .word 0x51F7893E
    .word 0xC771C8E4
    .word 0xAB1D8009
    .word 0xA32B438B
    .word 0x7A06DEC3
    .word 0x6BA55A80
    .word 0xFFA31AC7
    .word 0x761FB101
    .word 0xD6225EEB
    .word 0x083D8F54
    .word 0x5C43E240
    .word 0x439AD42E
    .word 0x66BF5B09
    .word 0xE2307459
    .word 0x0690640B
    .word 0x3478EBD3
    .word 0x10A8EA19
    .word 0x0E6BB6D1
    .word 0xE8770BF2
    .word 0x00000000
    .word 0x00000000
    .word 0xFF681E09
    .word 0x927C0BDD
    .word 0x1D263554
    .word 0x1102B08A
    .word 0x768E48A6
    .word 0x763A67AD
    .word 0xB666C044
    .word 0x9612636C
    .word 0xFA946525
    .word 0x46A6B51F
    .word 0x283015B6
    .word 0xEC0B4CFB
    .word 0x28F96207
    .word 0xF1F9486E
    .word 0xF2F747ED
    .word 0x5EDDE2BA
    .word 0x34A6C94A
    .word 0xDE4BB330
    .word 0xC8EB9754
    .word 0x0F85C351
    .word 0x3A5B6665
    .word 0xEF15D998
    .word 0xCD107483
    .word 0x1A467167
    .word 0xDE43F742
    .word 0x68CA79CC
    .word 0xF809B67E
    .word 0x0448BA25
    .word 0x8AE26F87
    .word 0xD1BF2024
    .word 0x00000000
    .word 0x00000000
    .word 0x7A82A1B4
    .word 0x5602ADFF
    .word 0x7728311E
    .word 0x591DFACC
    .word 0xB1E4D9D3
    .word 0x38A103CF
    .word 0x27461B39
    .word 0x0AA7C1DB
    .word 0xCF95A5CB
    .word 0xF5FC2F1F
    .word 0xE72C5347
    .word 0x1EE3E6BB
    .word 0xD405059A
    .word 0xB815B7FD
    .word 0xA63856CA
    .word 0xBD40589B
    .word 0xBBB24B1C
    .word 0x5F6C3E50
    .word 0xF324833B
    .word 0x480ACC22
    .word 0xBA289CB3
    .word 0xBD01C2F6
    .word 0x059A8C98
    .word 0xA3EAD36D
    .word 0xE2289461
    .word 0xCB8E47FA
    .word 0x3144A4C7
    .word 0x596223D6
    .word 0x93B03EE9
    .word 0xF400FA56
    .word 0x00000000
    .word 0x00000000
    .word 0x088DAD5B
    .word 0x45C31A3B
    .word 0x3F4A7A20
    .word 0x6635E2AC
    .word 0xAA88FCEB
    .word 0x38C510D2
    .word 0xA3C63647
    .word 0x8B59D15D
    .word 0x89719553
    .word 0xC547B863
    .word 0x9124F81C
    .word 0xBBAC7FA8
    .word 0x754D0457
    .word 0x354A4827
    .word 0xEF10643B
    .word 0xF6BE75AF
    .word 0x77BC4623
    .word 0x6BDEB0D4
    .word 0xFE863D93
    .word 0x8696FCB1
    .word 0xD663572A
    .word 0x8CB8E920
    .word 0x7849A579
    .word 0x3A0AAA36
    .word 0x2AC7818B
    .word 0xE81DA198
    .word 0xE626F5F2
    .word 0x20362949
    .word 0x3C62B435
    .word 0xE9A81632
    .word 0x00000000
    .word 0x00000000

/* The modulus and the first 15 Zetas need to be loaded into */
/* the scratchpad since the data region is not big enough. */
.section .scratchpad
    .globl modulus
    .balign 32
    modulus:
    .zero 32

    .globl ntt_modified_zetas_scratch
    .balign 256
    ntt_modified_zetas_scratch:
    .zero 128
