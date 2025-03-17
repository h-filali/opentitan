.section .text.start
.equ w0,  temp
/* The temporary registers are also used for coeff1-3 */
.equ w1,  temp1
.equ w2,  temp2
.equ w3,  temp3
/* The temporary registers are also used for coeff_buf12 */
.equ w29, temp4

.equ w1,  coeff0
.equ w2,  coeff1
.equ w3,  coeff2
.equ w4,  coeff3
.equ w5,  coeff4
.equ w6,  coeff5
.equ w7,  coeff6
.equ w8,  coeff7
.equ w9,  coeff8
.equ w10, coeff9
.equ w11, coeff10
.equ w12, coeff11
.equ w13, coeff12
.equ w14, coeff13
.equ w15, coeff14
.equ w16, coeff15

.equ w17, coeff_buf0
.equ w18, coeff_buf1
.equ w19, coeff_buf2
.equ w20, coeff_buf3
.equ w21, coeff_buf4
.equ w22, coeff_buf5
.equ w23, coeff_buf6
.equ w24, coeff_buf7
.equ w25, coeff_buf8
.equ w26, coeff_buf9
.equ w27, coeff_buf10
.equ w28, coeff_buf11
.equ w29, coeff_buf12

.equ w30, zetas
.equ w31, consts

.equ x10, ntt_w_addr
.equ x11, zetas_addr
.equ x12, modulus_addr

.equ x17, coeff_buf_reg0_id
.equ x18, coeff_buf_reg1_id
.equ x19, coeff_buf_reg2_id
.equ x20, coeff_buf_reg3_id
.equ x21, coeff_buf_reg4_id
.equ x22, coeff_buf_reg5_id
.equ x23, coeff_buf_reg6_id
.equ x24, coeff_buf_reg7_id
.equ x25, coeff_buf_reg8_id
.equ x26, coeff_buf_reg9_id
.equ x27, coeff_buf_reg10_id
.equ x28, coeff_buf_reg11_id
.equ x29, coeff_buf_reg12_id

.equ x30, zetas_reg_id
.equ x31, consts_reg_id

    /* Zero out temp */
    bn.xor temp, temp, temp

    /* Set up constants for input/state */
    la ntt_w_addr, ntt_w
    la zetas_addr, ntt_modified_zetas
    la modulus_addr, modulus

    li coeff_buf_reg0_id,  17
    li coeff_buf_reg1_id,  18
    li coeff_buf_reg2_id,  19
    li coeff_buf_reg3_id,  20
    li coeff_buf_reg4_id,  21
    li coeff_buf_reg5_id,  22
    li coeff_buf_reg6_id,  23
    li coeff_buf_reg7_id,  24
    li coeff_buf_reg8_id,  25
    li coeff_buf_reg9_id,  26
    li coeff_buf_reg10_id, 27
    li coeff_buf_reg11_id, 28
    li coeff_buf_reg12_id, 29
    li zetas_reg_id,       30
    li consts_reg_id,      31

    /* Load modulus into consts.1 and have consts.0 be all zeros*/
    bn.lid consts_reg_id, 0(x31)
    bn.rshi consts, consts, temp, 192

    /* Load 0x1 into consts.2 */
    bn.addi temp2, temp, 1
    bn.or consts, consts, temp2 << 128

    /* Load mask into consts.3 */
    bn.addi temp1, temp, 1
    bn.or temp1, temp, temp1 << 32
    bn.subi temp1, temp1, 1
    bn.or consts, consts, temp1 << 192

    loopi 2, 264
        /* Load coefficients into the buffers */
        bn.lid coeff_buf_reg0_id,    0(ntt_w_curr)
        bn.lid coeff_buf_reg1_id,   64(ntt_w_curr)
        bn.lid coeff_buf_reg2_id,  128(ntt_w_curr)
        bn.lid coeff_buf_reg3_id,  192(ntt_w_curr)
        bn.lid coeff_buf_reg4_id,  256(ntt_w_curr)
        bn.lid coeff_buf_reg5_id,  320(ntt_w_curr)
        bn.lid coeff_buf_reg6_id,  384(ntt_w_curr)
        bn.lid coeff_buf_reg7_id,  448(ntt_w_curr)
        bn.lid coeff_buf_reg8_id,  512(ntt_w_curr)
        bn.lid coeff_buf_reg9_id,  576(ntt_w_curr)
        bn.lid coeff_buf_reg10_id, 640(ntt_w_curr)
        bn.lid coeff_buf_reg11_id, 704(ntt_w_curr)
        bn.lid coeff_buf_reg12_id, 768(ntt_w_curr)

        /* Load zetas into the zetas register */
        bn.lid zetas_reg_id, 0(zetas_addr)

        loopi 8, 236
            /* Load coefficients that don't have a buffer */
            bn.lid temp1, 832(ntt_w_curr)
            bn.and coeff13, temp1, consts >> 192
            bn.lid temp2, 896(ntt_w_curr)
            bn.and coeff14, temp2, consts >> 192
            bn.lid temp3, 960(ntt_w_curr)
            bn.and coeff15, temp3, consts >> 192

            /* Load the rest of the coefficients from the buffers */
            bn.and coeff0,  coeff_buf0,  consts >> 192
            bn.and coeff1,  coeff_buf1,  consts >> 192
            bn.and coeff2,  coeff_buf2,  consts >> 192
            bn.and coeff3,  coeff_buf3,  consts >> 192
            bn.and coeff4,  coeff_buf4,  consts >> 192
            bn.and coeff5,  coeff_buf5,  consts >> 192
            bn.and coeff6,  coeff_buf6,  consts >> 192
            bn.and coeff7,  coeff_buf7,  consts >> 192
            bn.and coeff8,  coeff_buf8,  consts >> 192
            bn.and coeff9,  coeff_buf9,  consts >> 192
            bn.and coeff10, coeff_buf10, consts >> 192
            bn.and coeff11, coeff_buf11, consts >> 192
            bn.and coeff12, coeff_buf12, consts >> 192

            /* Round 1 */

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff8.0, zetas.0, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff8, coeff0, temp
            bn.addm coeff0, coeff0, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff9.0, zetas.0, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff9, coeff1, temp
            bn.addm coeff1, coeff1, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff10.0, zetas.0, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff10, coeff2, temp
            bn.addm coeff2, coeff2, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff11.0, zetas.0, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff11, coeff3, temp
            bn.addm coeff3, coeff3, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff12.0, zetas.0, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff12, coeff4, temp
            bn.addm coeff4, coeff4, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff13.0, zetas.0, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff13, coeff5, temp
            bn.addm coeff5, coeff5, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff14.0, zetas.0, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff14, coeff6, temp
            bn.addm coeff6, coeff6, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff15.0, zetas.0, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff15, coeff7, temp
            bn.addm coeff7, coeff7, temp

            /* Round 2 */

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff4.0, zetas.1, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff4, coeff0, temp
            bn.addm coeff0, coeff0, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff5.0, zetas.1, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff5, coeff1, temp
            bn.addm coeff1, coeff1, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff6.0, zetas.1, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff6, coeff2, temp
            bn.addm coeff2, coeff2, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff7.0, zetas.1, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff7, coeff3, temp
            bn.addm coeff3, coeff3, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff12.0, zetas.2, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff12, coeff8, temp
            bn.addm coeff8, coeff8, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff13.0, zetas.2, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff13, coeff9, temp
            bn.addm coeff9, coeff9, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff14.0, zetas.2, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff14, coeff10, temp
            bn.addm coeff10, coeff10, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff15.0, zetas.2, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff15, coeff11, temp
            bn.addm coeff11, coeff11, temp

            /* Round 3 */

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff2.0, zetas.3, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff2, coeff0, temp
            bn.addm coeff0, coeff0, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff3.0, zetas.3, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff3, coeff1, temp
            bn.addm coeff1, coeff1, temp

            /* Load next 4 zetas into the zetas register */
            bn.lid zetas_reg_id, 32(zetas_addr)

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff6.0, zetas.0, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff6, coeff4, temp
            bn.addm coeff4, coeff4, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff7.0, zetas.0, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff7, coeff5, temp
            bn.addm coeff5, coeff5, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff10.0, zetas.1, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff10, coeff8, temp
            bn.addm coeff8, coeff8, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff11.0, zetas.1, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff11, coeff9, temp
            bn.addm coeff9, coeff9, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff14.0, zetas.2, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff14, coeff12, temp
            bn.addm coeff12, coeff12, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff15.0, zetas.2, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff15, coeff13, temp
            bn.addm coeff13, coeff13, temp

            /* Round 4 */

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff1.0, zetas.3, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff1, coeff0, temp
            bn.addm coeff0, coeff0, temp

            /* Load next 4 zetas into the zetas register */
            bn.lid zetas_reg_id, 64(zetas_addr)

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff3.0, zetas.0, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff3, coeff2, temp
            bn.addm coeff2, coeff2, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff5.0, zetas.1, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff5, coeff4, temp
            bn.addm coeff4, coeff4, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff7.0, zetas.2, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff7, coeff6, temp
            bn.addm coeff6, coeff6, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff9.0, zetas.3, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff9, coeff8, temp
            bn.addm coeff8, coeff8, temp

            /* Load next 4 zetas into the zetas register */
            bn.lid zetas_reg_id, 96(zetas_addr)

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff11.0, zetas.0, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff11, coeff10, temp
            bn.addm coeff10, coeff10, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff13.0, zetas.1, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff13, coeff12, temp
            bn.addm coeff12, coeff12, temp

            /* Plantard multiplication: zetas[m] * w[j + len] */
            /* t = (z * w[j + len]) % (2**64) */
            bn.mulqacc.wo.z temp, coeff15.0, zetas.2, 192
            /* t = (t >> 32) + 1 */
            bn.add temp, consts, temp >> 160
            /* t *= q */
            bn.mulqacc.wo.z temp, temp.0, consts.1, 0
            /* t = t >> 32 */
            bn.rshi temp, consts, temp >> 32
            /* Butterfly */
            bn.subm coeff15, coeff14, temp
            bn.addm coeff14, coeff14, temp

            /* Shift the results back into the top of the buffers */
            bn.rshi coeff_buf0,   coeff0,  coeff_buf0 >> 64
            bn.rshi coeff_buf1,   coeff1,  coeff_buf1 >> 64
            bn.rshi coeff_buf2,   coeff2,  coeff_buf2 >> 64
            bn.rshi coeff_buf3,   coeff3,  coeff_buf3 >> 64
            bn.rshi coeff_buf4,   coeff4,  coeff_buf4 >> 64
            bn.rshi coeff_buf5,   coeff5,  coeff_buf5 >> 64
            bn.rshi coeff_buf6,   coeff6,  coeff_buf6 >> 64
            bn.rshi coeff_buf7,   coeff7,  coeff_buf7 >> 64
            bn.rshi coeff_buf8,   coeff8,  coeff_buf8 >> 64
            bn.rshi coeff_buf9,   coeff9,  coeff_buf9 >> 64
            bn.rshi coeff_buf10, coeff10, coeff_buf10 >> 64
            bn.rshi coeff_buf11, coeff11, coeff_buf11 >> 64
            bn.rshi coeff_buf12, coeff12, coeff_buf12 >> 64

            /* Shift the results back into the top of the temp WDRs */
            /* Write the temp WDR content back to DMEM */
            bn.lid  temp1, 832(ntt_w_curr)
            bn.rshi temp1, coeff13, temp1 >> 64
            bn.sid  temp1, 832(ntt_w_curr)
            bn.lid  temp2, 896(ntt_w_curr)
            bn.rshi temp2, coeff14, temp2 >> 64
            bn.sid  temp2, 896(ntt_w_curr)
            bn.lid  temp3, 960(ntt_w_curr)
            bn.rshi temp3, coeff15, temp3 >> 64
            bn.sid  temp3, 960(ntt_w_curr)

        /* Write back the coefficients from buffers to memory */
        bn.sid coeff_buf_reg0_id,    0(ntt_w_curr)
        bn.sid coeff_buf_reg1_id,   64(ntt_w_curr)
        bn.sid coeff_buf_reg2_id,  128(ntt_w_curr)
        bn.sid coeff_buf_reg3_id,  192(ntt_w_curr)
        bn.sid coeff_buf_reg4_id,  256(ntt_w_curr)
        bn.sid coeff_buf_reg5_id,  320(ntt_w_curr)
        bn.sid coeff_buf_reg6_id,  384(ntt_w_curr)
        bn.sid coeff_buf_reg7_id,  448(ntt_w_curr)
        bn.sid coeff_buf_reg8_id,  512(ntt_w_curr)
        bn.sid coeff_buf_reg9_id,  576(ntt_w_curr)
        bn.sid coeff_buf_reg10_id, 640(ntt_w_curr)
        bn.sid coeff_buf_reg11_id, 704(ntt_w_curr)
        /* Add 32 bytes to the address of ntt_w for the next iteration */
        bn.sid coeff_buf_reg12_id, 768(ntt_w_curr++)

    /* Set ntt_w_curr back to its original value */
    addi ntt_w_curr, ntt_w_curr, -64

    /* Create mask */
    bn.xor temp, temp, temp
    bn.rshi temp4, temp, consts >> 192

    /* Skip all the zetas that were used in the first four rounds */
    addi zetas_addr, zetas_addr, 128

    loopi 16, 232
        /* Load zetas into the zetas register */
        bn.lid zetas_reg_id, 0(zetas_addr++)

        /* Load coefficients into the buffers */
        bn.lid coeff_buf_reg0_id, 0(ntt_w_curr)
        bn.and coeff0, temp4, coeff_buf0 >> 0
        bn.and coeff1, temp4, coeff_buf0 >> 32
        bn.and coeff2, temp4, coeff_buf0 >> 64
        bn.and coeff3, temp4, coeff_buf0 >> 96
        bn.and coeff4, temp4, coeff_buf0 >> 128
        bn.and coeff5, temp4, coeff_buf0 >> 160
        bn.and coeff6, temp4, coeff_buf0 >> 192
        bn.and coeff7, temp4, coeff_buf0 >> 224

        bn.lid coeff_buf_reg1_id, 32(ntt_w_curr)
        bn.and coeff8,  temp4, coeff_buf1 >> 0
        bn.and coeff9,  temp4, coeff_buf1 >> 32
        bn.and coeff10, temp4, coeff_buf1 >> 64
        bn.and coeff11, temp4, coeff_buf1 >> 96
        bn.and coeff12, temp4, coeff_buf1 >> 128
        bn.and coeff13, temp4, coeff_buf1 >> 160
        bn.and coeff14, temp4, coeff_buf1 >> 192
        bn.and coeff15, temp4, coeff_buf1 >> 224

        /* Round 5 */

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff8.0, zetas.0, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff8, coeff0, temp
        bn.addm coeff0, coeff0, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff9.0, zetas.0, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff9, coeff1, temp
        bn.addm coeff1, coeff1, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff10.0, zetas.0, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff10, coeff2, temp
        bn.addm coeff2, coeff2, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff11.0, zetas.0, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff11, coeff3, temp
        bn.addm coeff3, coeff3, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff12.0, zetas.0, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff12, coeff4, temp
        bn.addm coeff4, coeff4, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff13.0, zetas.0, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff13, coeff5, temp
        bn.addm coeff5, coeff5, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff14.0, zetas.0, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff14, coeff6, temp
        bn.addm coeff6, coeff6, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff15.0, zetas.0, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff15, coeff7, temp
        bn.addm coeff7, coeff7, temp

        /* Round 6 */

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff4.0, zetas.1, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff4, coeff0, temp
        bn.addm coeff0, coeff0, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff5.0, zetas.1, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff5, coeff1, temp
        bn.addm coeff1, coeff1, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff6.0, zetas.1, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff6, coeff2, temp
        bn.addm coeff2, coeff2, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff7.0, zetas.1, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff7, coeff3, temp
        bn.addm coeff3, coeff3, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff12.0, zetas.2, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff12, coeff8, temp
        bn.addm coeff8, coeff8, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff13.0, zetas.2, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff13, coeff9, temp
        bn.addm coeff9, coeff9, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff14.0, zetas.2, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff14, coeff10, temp
        bn.addm coeff10, coeff10, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff15.0, zetas.2, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff15, coeff11, temp
        bn.addm coeff11, coeff11, temp

        /* Round 7 */

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff2.0, zetas.3, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff2, coeff0, temp
        bn.addm coeff0, coeff0, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff3.0, zetas.3, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff3, coeff1, temp
        bn.addm coeff1, coeff1, temp

        /* Load next 4 zetas into the zetas register */
        bn.lid zetas_reg_id, 0(zetas_addr++)

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff6.0, zetas.0, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff6, coeff4, temp
        bn.addm coeff4, coeff4, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff7.0, zetas.0, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff7, coeff5, temp
        bn.addm coeff5, coeff5, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff10.0, zetas.1, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff10, coeff8, temp
        bn.addm coeff8, coeff8, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff11.0, zetas.1, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff11, coeff9, temp
        bn.addm coeff9, coeff9, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff14.0, zetas.2, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff14, coeff12, temp
        bn.addm coeff12, coeff12, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff15.0, zetas.2, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff15, coeff13, temp
        bn.addm coeff13, coeff13, temp

        /* Round 8 */

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff1.0, zetas.3, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff1, coeff0, temp
        bn.addm coeff0, coeff0, temp

        /* Load next 4 zetas into the zetas register */
        bn.lid zetas_reg_id, 0(zetas_addr++)

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff3.0, zetas.0, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff3, coeff2, temp
        bn.addm coeff2, coeff2, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff5.0, zetas.1, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff5, coeff4, temp
        bn.addm coeff4, coeff4, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff7.0, zetas.2, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff7, coeff6, temp
        bn.addm coeff6, coeff6, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff9.0, zetas.3, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff9, coeff8, temp
        bn.addm coeff8, coeff8, temp

        /* Load next 4 zetas into the zetas register */
        bn.lid zetas_reg_id, 0(zetas_addr++)

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff11.0, zetas.0, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff11, coeff10, temp
        bn.addm coeff10, coeff10, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff13.0, zetas.1, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff13, coeff12, temp
        bn.addm coeff12, coeff12, temp

        /* Plantard multiplication: zetas[m] * w[j + len] */
        /* t = (z * w[j + len]) % (2**64) */
        bn.mulqacc.wo.z temp, coeff15.0, zetas.2, 192
        /* t = (t >> 32) + 1 */
        bn.add temp, consts, temp >> 160
        /* t *= q */
        bn.mulqacc.wo.z temp, temp.0, consts.1, 0
        /* t = t >> 32 */
        bn.rshi temp, consts, temp >> 32
        /* Butterfly */
        bn.subm coeff15, coeff14, temp
        bn.addm coeff14, coeff14, temp

        /* Write back the coefficients from buffers to memory */
        bn.rshi coeff_buf0, coeff0, coeff_buf0 >> 32
        bn.rshi coeff_buf0, coeff1, coeff_buf0 >> 32
        bn.rshi coeff_buf0, coeff2, coeff_buf0 >> 32
        bn.rshi coeff_buf0, coeff3, coeff_buf0 >> 32
        bn.rshi coeff_buf0, coeff4, coeff_buf0 >> 32
        bn.rshi coeff_buf0, coeff5, coeff_buf0 >> 32
        bn.rshi coeff_buf0, coeff6, coeff_buf0 >> 32
        bn.rshi coeff_buf0, coeff7, coeff_buf0 >> 32
        bn.sid coeff_buf_reg0_id, 0(ntt_w_curr++)

        bn.rshi coeff_buf1,  coeff8, coeff_buf1 >> 32
        bn.rshi coeff_buf1,  coeff9, coeff_buf1 >> 32
        bn.rshi coeff_buf1, coeff10, coeff_buf1 >> 32
        bn.rshi coeff_buf1, coeff11, coeff_buf1 >> 32
        bn.rshi coeff_buf1, coeff12, coeff_buf1 >> 32
        bn.rshi coeff_buf1, coeff13, coeff_buf1 >> 32
        bn.rshi coeff_buf1, coeff14, coeff_buf1 >> 32
        bn.rshi coeff_buf1, coeff15, coeff_buf1 >> 32
        bn.sid coeff_buf_reg1_id, 0(ntt_w_curr++)

    ecall

.data
    .globl modulus
    .balign 32
    modulus:
    .word 0x007FE001
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl ntt_w
    .balign 256
    ntt_w:
    .word 0x007F92CC
    .word 0x001EDEBD
    .word 0x0033F973
    .word 0x003DF383
    .word 0x0073C5C9
    .word 0x0078F88E
    .word 0x00020DC5
    .word 0x0014A087
    .word 0x000BDA07
    .word 0x001A2D1B
    .word 0x002C8173
    .word 0x000EADAD
    .word 0x00251335
    .word 0x00745A77
    .word 0x004EF87F
    .word 0x0035FF14
    .word 0x004BB439
    .word 0x0071DA66
    .word 0x006D1A18
    .word 0x0060E103
    .word 0x0040FA3A
    .word 0x0054402E
    .word 0x001C334B
    .word 0x0052D07A
    .word 0x00188213
    .word 0x001B0884
    .word 0x00469C72
    .word 0x00699207
    .word 0x0037A17F
    .word 0x000DCC6D
    .word 0x007AEDCF
    .word 0x002006A3
    .word 0x00068527
    .word 0x000E3DF6
    .word 0x00030683
    .word 0x00203461
    .word 0x000408D8
    .word 0x004A585C
    .word 0x004D5F32
    .word 0x00541CFE
    .word 0x00552C57
    .word 0x0038D2BB
    .word 0x006D28DF
    .word 0x0045954C
    .word 0x00506379
    .word 0x0075863B
    .word 0x0069A406
    .word 0x003F58DD
    .word 0x003BA909
    .word 0x0025DCE0
    .word 0x001BDAD4
    .word 0x00124286
    .word 0x00760A92
    .word 0x005394BD
    .word 0x007D71CA
    .word 0x00291A1D
    .word 0x0069D73B
    .word 0x0006EE86
    .word 0x00488738
    .word 0x0028BC5F
    .word 0x0046964E
    .word 0x0050500F
    .word 0x00374044
    .word 0x00509304
    .word 0x004D9D2E
    .word 0x007352FC
    .word 0x006343C7
    .word 0x006A3490
    .word 0x0046F72B
    .word 0x0035F422
    .word 0x0033F2A2
    .word 0x001C5A5D
    .word 0x003C407E
    .word 0x0051DA55
    .word 0x0063A777
    .word 0x0054A000
    .word 0x0034F8AC
    .word 0x003248FC
    .word 0x00310CBA
    .word 0x002CAAB2
    .word 0x006336B2
    .word 0x000F5E1A
    .word 0x000A853E
    .word 0x00268418
    .word 0x0074FB09
    .word 0x00284144
    .word 0x00337BD1
    .word 0x0074D6FB
    .word 0x004FF447
    .word 0x007A1370
    .word 0x006E0795
    .word 0x0056B4DA
    .word 0x0032FFAB
    .word 0x00263E95
    .word 0x005F5FE1
    .word 0x0008A918
    .word 0x0075E092
    .word 0x000764AB
    .word 0x002D3C19
    .word 0x0018F43A
    .word 0x002F6759
    .word 0x00231459
    .word 0x00400030
    .word 0x005877BC
    .word 0x00755082
    .word 0x00314D42
    .word 0x000C097B
    .word 0x00153AFB
    .word 0x00247052
    .word 0x004D1725
    .word 0x001C04AA
    .word 0x001EB4A2
    .word 0x00096577
    .word 0x0015DDFC
    .word 0x00180F6F
    .word 0x007BC590
    .word 0x002D9512
    .word 0x00070685
    .word 0x00721B74
    .word 0x0019BC3F
    .word 0x0067F62E
    .word 0x00247495
    .word 0x006D2553
    .word 0x00318FE1
    .word 0x005B3B62
    .word 0x003B8566
    .word 0x002B4428
    .word 0x007B6D47
    .word 0x005D3F1B
    .word 0x0042FF02
    .word 0x00063231
    .word 0x0057EDD0
    .word 0x004454C1
    .word 0x0072FE07
    .word 0x0022B01F
    .word 0x007E2E76
    .word 0x0074ED37
    .word 0x00158251
    .word 0x0054876E
    .word 0x000AD425
    .word 0x00739382
    .word 0x002120C3
    .word 0x00652064
    .word 0x000DD719
    .word 0x00534776
    .word 0x00032C1A
    .word 0x003B7FFB
    .word 0x001E3804
    .word 0x0070B75E
    .word 0x00536F64
    .word 0x000BE6D1
    .word 0x00445430
    .word 0x0077A24E
    .word 0x004594F7
    .word 0x0071520F
    .word 0x00148F7C
    .word 0x00328CCD
    .word 0x00253BF0
    .word 0x00202B32
    .word 0x007D4E8F
    .word 0x007599D0
    .word 0x006C97C5
    .word 0x0078E5DA
    .word 0x006351AD
    .word 0x006BB2EC
    .word 0x007C2CC4
    .word 0x000E49E1
    .word 0x001A1E26
    .word 0x0051558D
    .word 0x003D0EA0
    .word 0x005338E2
    .word 0x002090B8
    .word 0x004506E4
    .word 0x004F07F0
    .word 0x005D19F7
    .word 0x0034B898
    .word 0x0049B760
    .word 0x00039219
    .word 0x001428B9
    .word 0x0058B69C
    .word 0x00105E2A
    .word 0x007810ED
    .word 0x0037CD76
    .word 0x0035ACD2
    .word 0x001A7215
    .word 0x0038C078
    .word 0x006C4E7C
    .word 0x003177D0
    .word 0x002DAA06
    .word 0x004D965C
    .word 0x002B7FF1
    .word 0x003BAAFA
    .word 0x0031363B
    .word 0x006C03D1
    .word 0x00402558
    .word 0x00017C9B
    .word 0x0027DDCB
    .word 0x0042DF94
    .word 0x0052A0CB
    .word 0x0020F150
    .word 0x0024BA6A
    .word 0x003DC4FF
    .word 0x00251B0E
    .word 0x007415B0
    .word 0x002C3A1B
    .word 0x0003A98F
    .word 0x0050ABAB
    .word 0x007ADE64
    .word 0x00688ADE
    .word 0x005193A6
    .word 0x001D4849
    .word 0x0061393F
    .word 0x004B0D0B
    .word 0x0034D0CF
    .word 0x001321AA
    .word 0x00690E9C
    .word 0x0055B615
    .word 0x007BCC25
    .word 0x00242AA3
    .word 0x002ADAEA
    .word 0x0065E127
    .word 0x0013DF3E
    .word 0x002DF527
    .word 0x00609DD2
    .word 0x003AEA20
    .word 0x0075D799
    .word 0x0006503A
    .word 0x00216BAF
    .word 0x00446821
    .word 0x00429FD4
    .word 0x002C7E9F
    .word 0x004DF5BD
    .word 0x004F1FB3
    .word 0x00324802
    .word 0x00475DD3
    .word 0x001F448C
    .word 0x00666F00
    .word 0x00675862
    .word 0x002891DE
    .word 0x003403E1
    .word 0x0004850E
    .word 0x00018EAF
    .word 0x006708B6
    .word 0x000AE29A
    .word 0x002AFB96
    .word 0x0000FD68
    .word 0x0022119C
    .word 0x003811AB
    .word 0x0014676B
    .word 0x004AC88A
    .word 0x005AE9D0
    .word 0x000DC5C5
    .word 0x003F776B
    .word 0x00613460
    .word 0x004BE43E
    .word 0x0055BCAC

    .globl ntt_modified_zetas
    .balign 256
    ntt_modified_zetas:
    .word 0x00CA2087
    .word 0x92E0BB09
    .word 0xB04E1826
    .word 0x73078EFD
    .word 0xF0260FA4
    .word 0x72E78AFC
    .word 0x073E5788
    .word 0x9E33E1BC
    .word 0xE83C3F40
    .word 0xA7E8DEE7
    .word 0xE53B9F1E
    .word 0x9FE85ED7
    .word 0x0E3FD7DA
    .word 0x9E3461DC
    .word 0x37CA4823
    .word 0xED9EC1D5
    .word 0x47E44E84
    .word 0x6C36B6D5
    .word 0xF5069BBD
    .word 0x51EFDB52
    .word 0xC01904C1
    .word 0x41100B80
    .word 0x5F4CBC71
    .word 0x7301C58B
    .word 0xA7E00AB3
    .word 0xE14AE4F6
    .word 0x5F0C5457
    .word 0x110765B7
    .word 0x51DEC50E
    .word 0xDAB23AD9
    .word 0x00000000
    .word 0x00000000
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
