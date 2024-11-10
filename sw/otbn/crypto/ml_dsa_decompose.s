.section .text.start

    /* Set up constants for input/state */
    li x2, 3
    la x3, decompose_r
    bn.lid x2, 0(x3)

    li x2, 4
    la x4, decompose_127_const
    bn.lid x2, 0(x4)

    li x2, 5
    la x5, decompose_const
    bn.lid x2, 0(x5)

    li x2, 6
    la x6, reduce32_const
    bn.lid x2, 0(x6)

    li x2, 7
    la x7, decompose_15_const
    bn.lid x2, 0(x7)

    li x2, 8
    la x8, gamma2_vec_const
    bn.lid x2, 0(x8)

    li x2, 9
    la x9, qm1half_const
    bn.lid x2, 0(x9)

    li x2, 10
    la x10, modulus
    bn.lid x2, 0(x10)

    /* Zero out w31 */
    bn.xor w31, w31, w31

    /* r1 */
    bn.add            w11,  w3,  w4           /* w11 = r + 127 */
    bn.rshi           w11, w31, w11 >> 7      /* w11 = (r + 127) >> 7 */
    bn.mulqacc.wo.z   w11, w11.0, w5.0, 0     /* w11 = w11 * 1025 */
    bn.add            w11, w11,  w6           /* w11 = w11 + (1 << 21) */ 
    bn.rshi           w11, w31, w11 >> 22     /* w11 = w11 >> 22 */
    bn.and            w11, w11,  w7           /* w11 = w11 & 15 */
    la                x11, decompose_r1
    li                 x2, 11
    bn.sid             x2, 0(x11)


    /* r0 */
    bn.mulqacc.wo.z   w12, w11.0, w8.0, 0     /* w12 = r1 * 2*GAMMA2 */
    bn.sub            w12,  w3, w12           /* w12 = r - r1*2*GAMMA2 */
    bn.sub            w13,  w9, w12           /* w13 = (Q-1)/2 - w12 */
    bn.rshi           w13, w31, w13 >> 31     /* w13 = w13 >> 31 */
    bn.and            w13, w13, w10           /* w13 = w13 & Q */ 
    bn.sub            w12, w12, w13           /* w12 = w12 - w13 */
    la                x12, decompose_r0
    li                 x2, 12
    bn.sid             x2, 0(x12)
    
    ecall

.data
    .globl decompose_r
    .balign 32
    decompose_r:
    .word 0x006141C6
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl decompose_127_const
    .balign 32
    decompose_127_const:
    .word 0x0000007f
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl decompose_const
    .balign 32
    decompose_const:
    .word 0x00000401
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl reduce32_const
    .balign 32
    reduce32_const:
    .word 0x00200000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl decompose_15_const
    .balign 32
    decompose_15_const:
    .word 0x0000000F
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl gamma2_vec_const
    .balign 32
    gamma2_vec_const:
    .word 0x0007FE00
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

    .globl qm1half_const
    .balign 32
    qm1half_const:
    .word 0x003FF000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

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

    .globl decompose_r0
    .balign 32
    decompose_r0:
    .word 0x00000000
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
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
