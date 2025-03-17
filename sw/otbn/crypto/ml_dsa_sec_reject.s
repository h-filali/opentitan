.section .text.start

    /* Zero out w0 */
    bn.xor w0, w0, w0

    /* Load the modulus into MOD and w30 */
    li x8, 30
    la x3, ml_dsa_modulus
    bn.lid  x8, 0(x3)
    bn.and  w30,  w8, w7
    bn.wsrw MOD, w30

    /* Load the lambda0/1 - Beta into w23 and w24 */
    li x8, 23
    la x3, lambda_0
    bn.lid  x8, 0(x3)
    li x8, 24
    la x3, lambda_1
    bn.lid  x8, 0(x3)

    /* Set up input coefficients */
    li x8, 21
    la x10, inp_z_s0
    bn.lid  x8, 0(x10)

    /* Dummy instruction */
    bn.xor w0, w0, w0

    li x8, 22
    la x11, inp_z_s1
    bn.lid  x8, 0(x11)

    /* Call the secure bound check function. */
    jal  x1, ml_dsa_sec_bound_check

    /* Write output to memory. */
    li x8, 5
    la x12, result
    bn.sid x8, 0(x12)

    ecall

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

    .globl lambda_0
    .balign 32
    lambda_0:
    .word 0x0007ff88
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl lambda_1
    .balign 32
    lambda_1:
    .word 0x0007ff88
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl inp_z_s0
    .balign 32
    inp_z_s0:
    .word 0x00000001
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl inp_z_s1
    .balign 32
    inp_z_s1:
    .word 0x00000001
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl result
    .balign 32
    result:
    .zero 32
