.section .text.start

    /* Zero out w0 */
    bn.xor w0, w0, w0

    /* Init mask */
    bn.addi w7, w0, 1
    bn.or w7, w0, w7 << 32
    bn.subi w7, w7, 1

    /* Set up constants for input/state */
    li x9, 9
    li x8, 8
    li x6, 2
    li x5, 3

    la        x3, modulus
    bn.lid    x8, 0(x3)
    bn.wsrw  MOD, w8
    bn.rshi  w11, w8, w0 >> 255                     /* w11 = 2*w8 */

    la        x2, barrett_const_r
    bn.lid    x9, 0(x2)

    la x10, vec_mul_a
    la x11, vec_mul_b
    la x12, vec_mul_a

    LOOPI 32, 19
        bn.lid x6, 0(x10++)                         /* x6 = x10[i] */
        bn.lid x5, 0(x11++)                         /* x5 = x11[i] */

        LOOPI 8, 15
            /* Mask one coefficient to working registers */
            bn.and w4, w2, w7                       /* w4 = w2 & w7 */
            bn.and w5, w3, w7                       /* w5 = w3 & w7 */
            /* Shift out used coefficient */
            bn.rshi w2, w0, w2 >> 32                /* w2 = (w0 || w2) >> 32 */

            /* Barrett multiplication */
            bn.mulqacc.wo.z w4, w4.0, w5.0, 0       /* w4 = w4*w5 */
            bn.or w10, w4, w0                       /* Copy w4 to w10 */
            bn.rshi w4, w0, w4 >> 22                /* w4 = (w0 || w4) >> 22 */
            bn.mulqacc.wo.z w4, w4.0, w9.0, 0       /* w4 = w4*R */
            bn.rshi w4, w0, w4 >> 24                /* w4 = (w0 || w4) >> 24 */
            bn.mulqacc.wo.z w4, w4.0, w8.0, 0       /* w4 = w4*q */
            bn.sub w4, w10, w4                      /* w4 = w10 - w4 */

            /* Get w4 from the range [0:3q) into the range [0:q) */
            bn.wsrw MOD, w11
            bn.subm w4, w4, w8
            bn.wsrw MOD, w8
            bn.subm w4, w4, w8

            /* Shift in result coefficient */
            bn.rshi w3, w4, w3 >> 32                /*w3 = (w4 || w3) >> 32*/
        
        bn.sid x5, 0(x12++)                         /*x12[i] = x5*/

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

    .globl barrett_const_r
    .balign 32
    barrett_const_r:
    .word 0x00802007
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl vec_mul_a
    .balign 32
    vec_mul_a:
    .word 0x00000004
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001

    .globl vec_mul_b
    .balign 32
    vec_mul_b:
    .word 0x00000002
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
    .word 0x00000001
