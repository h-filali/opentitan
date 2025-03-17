.section .text.start

    /* Set up constants for input/state */
    la  x6, gamma_1
    la  x7, gamma_2
    lw  x8, 0(x6)
    lw  x9, 0(x7)
    la x10, inp_vec_z
    la x12, result

    lw x4, 0(x10)
    sub x4, x4, x8
    srai x4, x4, 31
    beq  x4, x0, reject

    li x4, 1
    sw x4, 0(x12)
    ecall

reject:

    li x4, 0
    sw x4, 0(x12)
    ecall

.data
    .globl gamma_1
    .balign 8
    gamma_1:
    .word 0x0007ff88

    .globl gamma_2
    .balign 8
    gamma_2:
    .word 0x0003fe88

    .globl inp_vec_z
    .balign 8
    inp_vec_z:
    .word 0x00000001

    .globl result
    .balign 8
    result:
    .zero 4
