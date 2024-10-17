.text
.globl poly_add_ntt
poly_add_ntt:

    /* Init mask */
    bn.addi w7, w31, 1
    bn.or w7, w31, w7 << 32
    bn.subi w7, w7, 1

    /* Set up constants for input/state */
    li x6, 2
    li x5, 3

    LOOPI 32, 9
        bn.lid x6, 0(x10++)                         /*x6 = x10[i]*/
        bn.lid x5, 0(x11++)                         /*x5 = x11[i]*/

        LOOPI 8, 5
            /* Mask one coefficient to working registers */
            bn.and w4, w2, w7                       /*w4 = w2 & w7*/
            bn.and w5, w3, w7                       /*w5 = w3 & w7*/
            /* Shift out used coefficient */
            bn.rshi w2, w31, w2 >> 32               /*w2 = (w31 || w2) >> 32*/

            bn.addm w4, w4, w5                      /*w4 = w4 + w5 % MOD*/
            bn.rshi w3, w4, w3 >> 32                /*w3 = (w4 || w3) >> 32*/
        
        bn.sid x5, 0(x12++)                         /*x12[i] = x5*/

    ret

.globl poly_sub_ntt
poly_sub_ntt:

    /* Init mask */
    bn.addi w7, w31, 1
    bn.or w7, w31, w7 << 32
    bn.subi w7, w7, 1

    /* Set up constants for input/state */
    li x6, 2
    li x5, 3

    LOOPI 32, 9
        bn.lid x6, 0(x10++)                         /*x6 = x10[i]*/
        bn.lid x5, 0(x11++)                         /*x5 = x11[i]*/

        LOOPI 8, 5
            /* Mask one coefficient to working registers */
            bn.and w4, w2, w7                       /*w4 = w2 & w7*/
            bn.and w5, w3, w7                       /*w5 = w3 & w7*/
            /* Shift out used coefficient */
            bn.rshi w2, w31, w2 >> 32               /*w2 = (w31 || w2) >> 32*/

            bn.subm w4, w4, w5                      /*w4 = w4 - w5 % MOD*/
            /* Shift in result coefficient */
            bn.rshi w3, w4, w3 >> 32                /*w3 = (w4 || w3) >> 32*/
        
        bn.sid x5, 0(x12++)                         /*x12[i] = x5*/

    ret

.globl poly_mul_ntt
poly_mul_ntt:

    /* Init mask */
    bn.addi w7, w31, 1
    bn.or w7, w31, w7 << 32
    bn.subi w7, w7, 1

    /* Set up constants for input/state */
    li x6, 2
    li x5, 3

    LOOPI 32, 19
        bn.lid x6, 0(x10++)                         /*x6 = x10[i]*/
        bn.lid x5, 0(x11++)                         /*x5 = x11[i]*/

        LOOPI 8, 15
            /* Mask one coefficient to working registers */
            bn.and w4, w2, w7                       /*w4 = w2 & w7*/
            bn.and w5, w3, w7                       /*w5 = w3 & w7*/
            /* Shift out used coefficient */
            bn.rshi w2, w31, w2 >> 32               /*w2 = (w31 || w2) >> 32*/

            /* Barrett multiplication */
            bn.mulqacc.wo.z w4, w4.0, w5.0, 225     /* w4 = w4*w5 % (2**31) */
            bn.rshi w4, w31, w4 >> 225              /* Shift the result down to the first quarter */
            bn.or w10, w4, w31                      /* Copy w4 to w10 */
            bn.mulqacc.wo.z w4, w4.0, w9.0, 223     /* w4 = w4*R % (2**33) */
            bn.rshi w4, w31, w4 >> 223              /* Shift the result down to the first quarter */
            bn.mulqacc.wo.z w4, w4.0, w8.0, 0       /* w4 = w4*q */
            bn.sub w4, w10, w4                      /* w4 = w10 - w4 */

            /* Get w4 from the range [0:3q) into the range [0:q) */
            bn.rshi MOD, w8, w31 >> 255
            bn.subm w4, w4, w8
            bn.rshi MOD, w31, w8 >> 0
            bn.subm w4, w4, w8

            /* Shift in result coefficient */
            bn.rshi w3, w4, w3 >> 32                /*w3 = (w4 || w3) >> 32*/
        
        bn.sid x5, 0(x12++)                         /*x12[i] = x5*/

    ret

.globl poly_mul_acc_ntt
poly_mul_acc_ntt:

    /* Init mask */
    bn.addi w7, w31, 1
    bn.or w7, w31, w7 << 32
    bn.subi w7, w7, 1

    /* Set up constants for input/state */
    li x6, 2
    li x5, 3
    li x4, 11
    bn.addi w11, w31, 0

    LOOPI 32, 19
        bn.lid x6, 0(x10++)                         /*x6 = x10[i]*/
        bn.lid x5, 0(x11++)                         /*x5 = x11[i]*/

        LOOPI 8, 16
            /* Mask one coefficient to working registers */
            bn.and w4, w2, w7                       /*w4 = w2 & w7*/
            bn.and w5, w3, w7                       /*w5 = w3 & w7*/
            /* Shift out used coefficient */
            bn.rshi w2, w31, w2 >> 32               /*w2 = (w31 || w2) >> 32*/

            /* Barrett multiplication */
            bn.mulqacc.wo.z w4, w4.0, w5.0, 225     /* w4 = w4*w5 % (2**31) */
            bn.rshi w4, w31, w4 >> 225              /* Shift the result down to the first quarter */
            bn.or w10, w4, w31                      /* Copy w4 to w10 */
            bn.mulqacc.wo.z w4, w4.0, w9.0, 223     /* w4 = w4*R % (2**33) */
            bn.rshi w4, w31, w4 >> 223              /* Shift the result down to the first quarter */
            bn.mulqacc.wo.z w4, w4.0, w8.0, 0       /* w4 = w4*q */
            bn.sub w4, w10, w4                      /* w4 = w10 - w4 */

            /* Get w4 from the range [0:3q) into the range [0:q) */
            bn.rshi MOD, w8, w31 >> 255
            bn.subm w4, w4, w8
            bn.rshi MOD, w31, w8 >> 0
            bn.subm w4, w4, w8

            /* Shift in result coefficient */
            bn.rshi w3, w4, w3 >> 32                /*w3 = (w4 || w3) >> 32*/

            /* Accumulate result into w11 */
            bn.addm w11, w11, w4                    /*w11 = w11 + w4 % q*/
        
    bn.sid x4, 0(x12)                               /* MEM[x12] = w11 */

    ret
