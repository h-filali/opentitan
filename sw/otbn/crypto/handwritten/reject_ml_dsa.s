.text
.globl rejection_sampling
rejection_sampling:
    /* Set up constants for input/state */
    lw x8, 0(x12)
    lw x9, 4(x12)

    LOOPI 256, 10
        lw x4, 0(x10)
        addi x10, x10, 4
        sub x4, x4, x8
        srai x4, x4, 31
        bne  x4, x0, reject

        lw x5, 0(x11)
        addi x11, x11, 4
        sub x5, x5, x9
        srai x5, x5, 31
        bne  x5, x0, reject

    li x4, 1
    sw x4, 0(x13)                                   /*x13 = 1*/
    ret

reject:

    li x4, 0
    sw x4, 0(x13)                                   /*x13 = 0*/
    ret
