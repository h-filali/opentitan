.section .text.start

/**
 * Name:        crypto_sign_signature_internal
 *
 * Description: Computes signature. Internal API.
 *
 * Returns: 0 (success)
 *
 * Flags: TODO
 *
 * @param[in]  x10: *sig   (pointer to output signature)
 * @param[in]  x11: *msg   (pointer to message to be signed)
 * @param[in]  x12: msglen (length of message)
 * @param[in]  x13: *sk    (pointer to bit-packed secret key)
 * @param[out] x10: 0      (output 0 on success)
 * @param[out] x11: siglen (output length of signature)
 *
 * clobbered registers: TODO
 *                      TODO
 */
.global rej_sign_dilithium
rej_sign_dilithium:

    /**
    *     _
    *    / \          _   _
    *   / _ \    _   | | | |
    *  / ___ \  (_)  | |_| |
    * /_/   \_\       \__, |
    *                 |___/
    */

    /* Zero out w0 */
    bn.xor w0, w0, w0

    /* Init 32 bit mask */
    bn.addi w7, w0, 1
    bn.or w7, w0, w7 << 32
    bn.subi w7, w7, 1

    /* Load the modulus into w8 */
    li x8, 8
    la x3, constants
    bn.lid x8, 0(x3)
    bn.and w8, w8, w7

    /* Load the barret constant into w9 */
    li x9, 9
    la x2, constants
    bn.lid x9, 0(x2)
    bn.and w9, w7, w9 >> 32

    /* Do the matrix multiplication for share 1 of A*y */
    la x10, ml_dsa_mat_a_hat
    la x11, ml_dsa_y_s1
    la x12, ml_dsa_w_s1

    LOOPI 4, 6
        LOOPI 4, 3
            jal x1, ml_dsa_mac
            addi x10, x10, 32
            addi x11, x11, 32

        addi x12, x12, 32
        la x11, ml_dsa_y_s1

    /* Do the matrix multiplication for share 2 of A*y */
    la x10, ml_dsa_mat_a_hat
    la x11, ml_dsa_y_s2
    la x12, ml_dsa_w_s2

    LOOPI 4, 6
        LOOPI 4, 3
            jal x1, ml_dsa_mac
            addi x10, x10, 32
            addi x11, x11, 32

        addi x12, x12, 32
        la x11, ml_dsa_y_s2

    /**
    *                     ___ _   _ _____ _____    __     _                  __  
    * __      __  _____  |_ _| \ | |_   _|_   _|  / /    / \          _   _  \ \ 
    * \ \ /\ / / |_____|  | ||  \| | | |   | |   | |    / _ \    _   | | | |  | |
    *  \ V  V /  |_____|  | || |\  | | |   | |   | |   / ___ \  (_)  | |_| |  | |
    *   \_/\_/           |___|_| \_| |_|   |_|   | |  /_/   \_\       \__, |  | |
    *                                             \_\                 |___/  /_/ 
    */

    /* Do preparations for the INTT */
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

    /* Perform the INTT on the first share of the result of A*y */

    /* Set up constants for input/state of polynomial 1 */
    bn.xor w0, w0, w0
    la  x9, ntt_f
    la x10, ml_dsa_w_s1
    la x11, intt_modified_zetas
    la x12, constants

    /* Run the INTT */
    jal x1, ml_dsa_intt

    /* Set up constants for input/state of polynomial 2 */
    bn.xor w0, w0, w0
    la    x9, ntt_f
    la   x10, ml_dsa_w_s1
    addi x10, x10, 32
    la   x11, intt_modified_zetas
    la   x12, constants

    /* Run the INTT */
    jal  x1, ml_dsa_intt

    /* Set up constants for input/state of polynomial 3 */
    bn.xor w0, w0, w0
    la    x9, ntt_f
    la   x10, ml_dsa_w_s1
    addi x10, x10, 64
    la   x11, intt_modified_zetas
    la   x12, constants

    /* Run the INTT */
    jal  x1, ml_dsa_intt

    /* Set up constants for input/state of polynomial 4 */
    bn.xor w0, w0, w0
    la    x9, ntt_f
    la   x10, ml_dsa_w_s1
    addi x10, x10, 96
    la   x11, intt_modified_zetas
    la   x12, constants

    /* Run the INTT */
    jal  x1, ml_dsa_intt

    /* Perform the INTT on the second share of the result of A*y */

    /* Set up constants for input/state of polynomial 1 */
    bn.xor w0, w0, w0
    la  x9, ntt_f
    la x10, ml_dsa_w_s2
    la x11, intt_modified_zetas
    la x12, constants

    /* Run the INTT */
    jal x1, ml_dsa_intt

    /* Set up constants for input/state of polynomial 2 */
    bn.xor w0, w0, w0
    la    x9, ntt_f
    la   x10, ml_dsa_w_s2
    addi x10, x10, 32
    la   x11, intt_modified_zetas
    la   x12, constants

    /* Run the INTT */
    jal  x1, ml_dsa_intt

    /* Set up constants for input/state of polynomial 3 */
    bn.xor w0, w0, w0
    la    x9, ntt_f
    la   x10, ml_dsa_w_s2
    addi x10, x10, 64
    la   x11, intt_modified_zetas
    la   x12, constants

    /* Run the INTT */
    jal  x1, ml_dsa_intt

    /* Set up constants for input/state of polynomial 4 */
    bn.xor w0, w0, w0
    la    x9, ntt_f
    la   x10, ml_dsa_w_s2
    addi x10, x10, 96
    la   x11, intt_modified_zetas
    la   x12, constants

    /* Run the INTT */
    jal  x1, ml_dsa_intt

    /**
    *   __          ___              ___            ____                                  __        __  
    *  / /_      __/ _ \   __      _/ \ \   _____  |  _ \  ___  ___ ___  _ __ ___  _ __  / /_      _\ \ 
    * | |\ \ /\ / / | | |  \ \ /\ / / || | |_____| | | | |/ _ \/ __/ _ \| '_ ` _ \| '_ \| |\ \ /\ / /| |
    * | | \ V  V /| |_| |   \ V  V /| || | |_____| | |_| |  __/ (_| (_) | | | | | | |_) | | \ V  V / | |
    * | |  \_/\_/  \___( )   \_/\_/ |_|| |         |____/ \___|\___\___/|_| |_| |_| .__/| |  \_/\_/  | |
    *  \_\             |/             /_/                                         |_|    \_\        /_/ 
    */

    /* Decompose the vector w into its high bits w1 and its low bits w0. */
    /* (w0 replaces w in memory) */

    /* Load the barrett reduction constant and the modulus into the scratch pad. */
    la x29, barrett_r_scratch
    li  x3, 0x0002E8BA
    sw  x3,  0(x29)
    sw  x0,  4(x29)
    sw  x0,  8(x29)
    sw  x0, 12(x29)
    sw  x0, 16(x29)
    sw  x0, 20(x29)
    sw  x0, 24(x29)
    sw  x0, 28(x29)

    la x30, modulus_scratch
    li  x3, 0x007FE001
    sw  x3,  0(x30)
    sw  x0,  4(x30)
    sw  x0,  8(x30)
    sw  x0, 12(x30)
    sw  x0, 16(x30)
    sw  x0, 20(x30)
    sw  x0, 24(x30)
    sw  x0, 28(x30)

    /* Load the barrett reduction constant into w29 */
    li x8, 29
    bn.lid x8, 0(x29)

    /* Zero w0. */
    bn.xor w0, w0, w0

    /* Set x10 to the address for the ML-DSA constants. */
    la x10, constants

    /* Set up constants for input/state of polynomial 1 */
    la x11, ml_dsa_w_s1
    la x12, ml_dsa_w_s2
    la x13, ml_dsa_w1

    /* Run the decompose routine. */
    jal x1, ml_dsa_decompose_vec

    /* Set up constants for input/state of polynomial 2 */
    la   x11, ml_dsa_w_s1
    addi x11, x11, 32
    la   x12, ml_dsa_w_s2
    addi x12, x12, 32
    la   x13, ml_dsa_w1
    addi x13, x13, 32

    /* Run the decompose routine. */
    jal x1, ml_dsa_decompose_vec

    /* Set up constants for input/state of polynomial 3 */
    la   x11, ml_dsa_w_s1
    addi x11, x11, 64
    la   x12, ml_dsa_w_s2
    addi x12, x12, 64
    la   x13, ml_dsa_w1
    addi x13, x13, 64

    /* Run the decompose routine. */
    jal x1, ml_dsa_decompose_vec

    /* Set up constants for input/state of polynomial 4 */
    la   x11, ml_dsa_w_s1
    addi x11, x11, 96
    la   x12, ml_dsa_w_s2
    addi x12, x12, 96
    la   x13, ml_dsa_w1
    addi x13, x13, 96

    /* Run the decompose routine. */
    jal x1, ml_dsa_decompose_vec

    /**
    *                                _ _                        _     _               _     
    *   ___ ___  _ __ ___  _ __ ___ (_) |_ _ __ ___   ___ _ __ | |_  | |__   __ _ ___| |__  
    *  / __/ _ \| '_ ` _ \| '_ ` _ \| | __| '_ ` _ \ / _ \ '_ \| __| | '_ \ / _` / __| '_ \ 
    * | (_| (_) | | | | | | | | | | | | |_| | | | | |  __/ | | | |_  | | | | (_| \__ \ | | |
    *  \___\___/|_| |_| |_|_| |_| |_|_|\__|_| |_| |_|\___|_| |_|\__| |_| |_|\__,_|___/_| |_|
    */

    /**
    *                 _  __ _                      _           _ _                       
    * __   _____ _ __(_)/ _(_) ___ _ __ ___    ___| |__   __ _| | | ___ _ __   __ _  ___ 
    * \ \ / / _ \ '__| | |_| |/ _ \ '__/ __|  / __| '_ \ / _` | | |/ _ \ '_ \ / _` |/ _ \
    *  \ V /  __/ |  | |  _| |  __/ |  \__ \ | (__| | | | (_| | | |  __/ | | | (_| |  __/
    *   \_/ \___|_|  |_|_| |_|\___|_|  |___/  \___|_| |_|\__,_|_|_|\___|_| |_|\__, |\___|
    *                                                                         |___/      
    */

    /**
    *                 _   _ _____ _____    __        __  
    *   ___   _____  | \ | |_   _|_   _|  / /   ___  \ \ 
    *  / __| |_____| |  \| | | |   | |   | |   / __|  | |
    * | (__  |_____| | |\  | | |   | |   | |  | (__   | |
    *  \___|         |_| \_| |_|   |_|   | |   \___|  | |
    *                                     \_\        /_/ 
    */

    /* Perform the NTT on the result of SampleInBall(c^(~)) */

    /* Set up constants for input/state of the polynomial */
    bn.xor w0, w0, w0
    la x10, ml_dsa_c
    la x11, ntt_modified_zetas
    la x12, constants

    /* Run the NTT */
    jal x1, ml_dsa_ntt

    /**
    *      _                          _ 
    *  ___/ |  _____    ___       ___/ |
    * / __| | |_____|  / __|  _  / __| |
    * \__ \ | |_____| | (__  (_) \__ \ |
    * |___/_|          \___|     |___/_|
    *
    */

    /* Zero out w0 */
    bn.xor w0, w0, w0

    /* Init 32 bit mask */
    bn.addi w7, w0, 1
    bn.or w7, w0, w7 << 32
    bn.subi w7, w7, 1

    /* Load the modulus into w8 */
    li x8, 8
    la x3, constants
    bn.lid x8, 0(x3)
    bn.and w8, w8, w7

    /* Load the barret constant into w9 */
    li x9, 9
    la x2, constants
    bn.lid x9, 0(x2)
    bn.and w9, w7, w9 >> 32

    /* Do the coefficient-wise multiplication for share 1 of s1 */
    la x10, ml_dsa_s1_s1
    la x12, ml_dsa_s1_s1

    LOOPI 4, 2
        la x11, ml_dsa_c
        jal x1, ml_dsa_mul

    /* Do the coefficient-wise multiplication for share 2 of s1 */
    la x10, ml_dsa_s1_s2
    la x12, ml_dsa_s1_s2

    LOOPI 4, 2
        la x11, ml_dsa_c
        jal x1, ml_dsa_mul

    /**
    *      ____                           ____  
    *  ___|___ \   _____    ___       ___|___ \ 
    * / __| __) | |_____|  / __|  _  / __| __) |
    * \__ \/ __/  |_____| | (__  (_) \__ \/ __/ 
    * |___/_____|          \___|     |___/_____|
    *
    */

    /* Do the coefficient-wise multiplication for share 1 of s2 */
    la x10, ml_dsa_s2_s1
    la x12, ml_dsa_s2_s1

    LOOPI 4, 2
        la x11, ml_dsa_c
        jal x1, ml_dsa_mul

    /* Do the coefficient-wise multiplication for share 2 of s2 */
    la x10, ml_dsa_s2_s2
    la x12, ml_dsa_s2_s2

    LOOPI 4, 2
        la x11, ml_dsa_c
        jal x1, ml_dsa_mul


    /**
    *           _           ___ _   _ _____ _____    __                 _  __  
    *   ___ ___/ |  _____  |_ _| \ | |_   _|_   _|  / /   ___       ___/ | \ \ 
    *  / __/ __| | |_____|  | ||  \| | | |   | |   | |   / __|  _  / __| |  | |
    * | (__\__ \ | |_____|  | || |\  | | |   | |   | |  | (__  (_) \__ \ |  | |
    *  \___|___/_|         |___|_| \_| |_|   |_|   | |   \___|     |___/_|  | |
    *                                               \_\                    /_/ 
    */

    /* Perform the INTT on the first share of the result of c*s1 */

    /* Set up constants for input/state of polynomial 1 */
    bn.xor w0, w0, w0
    la  x9, ntt_f
    la x10, ml_dsa_s1_s1
    la x11, intt_modified_zetas
    la x12, constants

    /* Run the INTT */
    jal x1, ml_dsa_intt

    /* Set up constants for input/state of polynomial 2 */
    bn.xor w0, w0, w0
    la    x9, ntt_f
    la   x10, ml_dsa_s1_s1
    addi x10, x10, 32
    la   x11, intt_modified_zetas
    la   x12, constants

    /* Run the INTT */
    jal  x1, ml_dsa_intt

    /* Set up constants for input/state of polynomial 3 */
    bn.xor w0, w0, w0
    la    x9, ntt_f
    la   x10, ml_dsa_s1_s1
    addi x10, x10, 64
    la   x11, intt_modified_zetas
    la   x12, constants

    /* Run the INTT */
    jal  x1, ml_dsa_intt

    /* Set up constants for input/state of polynomial 4 */
    bn.xor w0, w0, w0
    la    x9, ntt_f
    la   x10, ml_dsa_s1_s1
    addi x10, x10, 96
    la   x11, intt_modified_zetas
    la   x12, constants

    /* Run the INTT */
    jal  x1, ml_dsa_intt

    /* Perform the INTT on the second share of the result of c*s1 */

    /* Set up constants for input/state of polynomial 1 */
    bn.xor w0, w0, w0
    la  x9, ntt_f
    la x10, ml_dsa_s1_s2
    la x11, intt_modified_zetas
    la x12, constants

    /* Run the INTT */
    jal x1, ml_dsa_intt

    /* Set up constants for input/state of polynomial 2 */
    bn.xor w0, w0, w0
    la    x9, ntt_f
    la   x10, ml_dsa_s1_s2
    addi x10, x10, 32
    la   x11, intt_modified_zetas
    la   x12, constants

    /* Run the INTT */
    jal  x1, ml_dsa_intt

    /* Set up constants for input/state of polynomial 3 */
    bn.xor w0, w0, w0
    la    x9, ntt_f
    la   x10, ml_dsa_s1_s2
    addi x10, x10, 64
    la   x11, intt_modified_zetas
    la   x12, constants

    /* Run the INTT */
    jal  x1, ml_dsa_intt

    /* Set up constants for input/state of polynomial 4 */
    bn.xor w0, w0, w0
    la    x9, ntt_f
    la   x10, ml_dsa_s1_s2
    addi x10, x10, 96
    la   x11, intt_modified_zetas
    la   x12, constants

    /* Run the INTT */
    jal  x1, ml_dsa_intt

    /**
    *                                         _
    *  ____  _____   _   _     _      ___ ___/ |
    * |_  / |_____| | | | |  _| |_   / __/ __| |
    *  / /  |_____| | |_| | |_   _| | (__\__ \ |
    * /___|          \__, |   |_|    \___|___/_|
    *                |___/
    *
    */

    /* Zero out w0 */
    bn.xor w0, w0, w0

    /* Init 32 bit mask */
    bn.addi w7, w0, 1
    bn.or w7, w0, w7 << 32
    bn.subi w7, w7, 1

    /* Load the modulus into MOD */
    li x8, 8
    la x3, constants
    bn.lid   x8, 0(x3)
    bn.and   w8,  w8, w7
    bn.wsrw MOD,  w8

    /* Do the coefficient-wise addition for share 1 of s1 */
    la x10, ml_dsa_s1_s1
    la x11, ml_dsa_y_s1
    la x12, ml_dsa_s1_s1

    LOOPI 4, 1
        jal x1, ml_dsa_add

    /* Do the coefficient-wise addition for share 2 of s1 */
    la x10, ml_dsa_s1_s2
    la x11, ml_dsa_y_s2
    la x12, ml_dsa_s1_s2

    LOOPI 4, 1
        jal x1, ml_dsa_add

    /**
    *            _                             _ _                   
    *  _ __ ___ (_)  ___  __ _ _ __ ___  _ __ | (_)_ __   __ _   ____
    * | '__/ _ \| | / __|/ _` | '_ ` _ \| '_ \| | | '_ \ / _` | |_  /
    * | | |  __/| | \__ \ (_| | | | | | | |_) | | | | | | (_| |  / / 
    * |_|  \___|/ | |___/\__,_|_| |_| |_| .__/|_|_|_| |_|\__, | /___|
    *         |__/                      |_|              |___/
    */

    /* Zero out w0 */
    bn.xor w0, w0, w0

    /* Init 32 bit mask */
    bn.addi w7, w0, 1
    bn.or w7, w0, w7 << 32
    bn.subi w7, w7, 1

    /* Load the modulus into MOD and w30 */
    li x8, 8
    la x3, constants
    bn.lid   x8, 0(x3)
    bn.and  w30,  w8, w7
    bn.wsrw MOD, w30

    /* Load the Gamma1 - Beta into w23 and w24 */
    li x8, 23
    la x3, constants
    bn.lid x8, 0(x3)
    bn.and w23, w7, w23 >> 128
    bn.or  w24, w23, w0

    /* Do the rejection sampling for z. */
    la x11, ml_dsa_s1_s1
    la x12, ml_dsa_s1_s2

    LOOPI 4, 6
        jal x1, ml_dsa_sec_bound_check_vec

        /* And the result with the current rejection state. */
        li x8, 8
        la x3, ml_dsa_rej
        bn.lid x8, 0(x3)
        bn.and w8, w8, w29
        bn.sid x8, 0(x3)
        
    
    /**
    *           ____            ___ _   _ _____ _____    __                 ____   __  
    *   ___ ___|___ \   _____  |_ _| \ | |_   _|_   _|  / /   ___       ___|___ \  \ \ 
    *  / __/ __| __) | |_____|  | ||  \| | | |   | |   | |   / __|  _  / __| __) |  | |
    * | (__\__ \/ __/  |_____|  | || |\  | | |   | |   | |  | (__  (_) \__ \/ __/   | |
    *  \___|___/_____|         |___|_| \_| |_|   |_|   | |   \___|     |___/_____|  | |
    *                                                   \_\                        /_/ 
    */

    /* Perform the INTT on the first share of the result of c*s2 */

    /* Set up constants for input/state of polynomial 1 */
    bn.xor w0, w0, w0
    la  x9, ntt_f
    la x10, ml_dsa_s2_s1
    la x11, intt_modified_zetas
    la x12, constants

    /* Run the INTT */
    jal x1, ml_dsa_intt

    /* Set up constants for input/state of polynomial 2 */
    bn.xor w0, w0, w0
    la    x9, ntt_f
    la   x10, ml_dsa_s2_s1
    addi x10, x10, 32
    la   x11, intt_modified_zetas
    la   x12, constants

    /* Run the INTT */
    jal  x1, ml_dsa_intt

    /* Set up constants for input/state of polynomial 3 */
    bn.xor w0, w0, w0
    la    x9, ntt_f
    la   x10, ml_dsa_s2_s1
    addi x10, x10, 64
    la   x11, intt_modified_zetas
    la   x12, constants

    /* Run the INTT */
    jal  x1, ml_dsa_intt

    /* Set up constants for input/state of polynomial 4 */
    bn.xor w0, w0, w0
    la    x9, ntt_f
    la   x10, ml_dsa_s2_s1
    addi x10, x10, 96
    la   x11, intt_modified_zetas
    la   x12, constants

    /* Run the INTT */
    jal  x1, ml_dsa_intt

    /* Perform the INTT on the second share of the result of c*s2 */

    /* Set up constants for input/state of polynomial 1 */
    bn.xor w0, w0, w0
    la  x9, ntt_f
    la x10, ml_dsa_s2_s2
    la x11, intt_modified_zetas
    la x12, constants

    /* Run the INTT */
    jal x1, ml_dsa_intt

    /* Set up constants for input/state of polynomial 2 */
    bn.xor w0, w0, w0
    la    x9, ntt_f
    la   x10, ml_dsa_s2_s2
    addi x10, x10, 32
    la   x11, intt_modified_zetas
    la   x12, constants

    /* Run the INTT */
    jal  x1, ml_dsa_intt

    /* Set up constants for input/state of polynomial 3 */
    bn.xor w0, w0, w0
    la    x9, ntt_f
    la   x10, ml_dsa_s2_s2
    addi x10, x10, 64
    la   x11, intt_modified_zetas
    la   x12, constants

    /* Run the INTT */
    jal  x1, ml_dsa_intt

    /* Set up constants for input/state of polynomial 4 */
    bn.xor w0, w0, w0
    la    x9, ntt_f
    la   x10, ml_dsa_s2_s2
    addi x10, x10, 96
    la   x11, intt_modified_zetas
    la   x12, constants

    /* Run the INTT */
    jal  x1, ml_dsa_intt

    /**
    *        ___                      ___                     ____  
    *  _ __ / _ \   _____  __      __/ _ \            ___ ___|___ \ 
    * | '__| | | | |_____| \ \ /\ / / | | |  _____   / __/ __| __) |
    * | |  | |_| | |_____|  \ V  V /| |_| | |_____| | (__\__ \/ __/ 
    * |_|   \___/            \_/\_/  \___/           \___|___/_____|
    */

    /* Zero out w0 */
    bn.xor w0, w0, w0

    /* Init 32 bit mask */
    bn.addi w7, w0, 1
    bn.or w7, w0, w7 << 32
    bn.subi w7, w7, 1

    /* Load the modulus into MOD */
    li x8, 8
    la x3, constants
    bn.lid   x8, 0(x3)
    bn.and   w8,  w8, w7
    bn.wsrw MOD,  w8

    /* Do the coefficient-wise subtraction for share 1 of s1 */
    la x10, ml_dsa_w_s1
    la x11, ml_dsa_s2_s1
    la x12, ml_dsa_s2_s1

    LOOPI 4, 1
        jal x1, ml_dsa_sub

    /* Do the coefficient-wise subtraction for share 2 of s1 */
    la x10, ml_dsa_w_s2
    la x11, ml_dsa_s2_s2
    la x12, ml_dsa_s2_s2

    LOOPI 4, 1
        jal x1, ml_dsa_sub

    /**
    *            _                             _ _                     ___  
    *  _ __ ___ (_)  ___  __ _ _ __ ___  _ __ | (_)_ __   __ _   _ __ / _ \ 
    * | '__/ _ \| | / __|/ _` | '_ ` _ \| '_ \| | | '_ \ / _` | | '__| | | |
    * | | |  __/| | \__ \ (_| | | | | | | |_) | | | | | | (_| | | |  | |_| |
    * |_|  \___|/ | |___/\__,_|_| |_| |_| .__/|_|_|_| |_|\__, | |_|   \___/ 
    *         |__/                      |_|              |___/
    */

    /* Zero out w0 */
    bn.xor w0, w0, w0

    /* Init 32 bit mask */
    bn.addi w7, w0, 1
    bn.or w7, w0, w7 << 32
    bn.subi w7, w7, 1

    /* Load the modulus into MOD and w30 */
    li x8, 8
    la x3, constants
    bn.lid   x8, 0(x3)
    bn.and  w30,  w8, w7
    bn.wsrw MOD, w30

    /* Load the Gamma2 - Beta into w23 and w24 */
    li x8, 23
    la x3, constants
    bn.lid x8, 0(x3)
    bn.and w23, w7, w23 >> 160
    bn.or  w24, w23, w0

    /* Do the rejection sampling for r0. */
    la x11, ml_dsa_w_s1
    la x12, ml_dsa_w_s2

    LOOPI 4, 6
        jal x1, ml_dsa_sec_bound_check_vec

        /* And the result with the current rejection state. */
        li x8, 8
        la x3, ml_dsa_rej
        bn.lid x8, 0(x3)
        bn.and w8, w8, w29
        bn.sid x8, 0(x3)


    ecall


/**
 * Name:        ml_dsa_add
 *
 * Description: Computes the coefficient wise addition of
 *              two vectors.
 *
 * Returns:
 *
 * Flags:
 *
 * @param[in]  x10: *veca       (pointer to input vector A)
 * @param[in]  x11: *vecb       (pointer to input vector B)
 * @param[in]   w0: zero        (all zeros)
 * @param[in]   w7: mask        (a mask for the lowest 32 bits)
 * @param[in]  MOD: modulus     (the modulus)
 * @param[out] x12: *vecc       (pointer to output vector C)
 *
 * clobbered registers: TODO
 *                      TODO
 */
.globl ml_dsa_add
ml_dsa_add:

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
            bn.rshi w2, w0, w2 >> 32                /*w2 = (w0 || w2) >> 32*/

            bn.addm w4, w4, w5                      /*w4 = w4 + w5 % MOD*/
            bn.rshi w3, w4, w3 >> 32                /*w3 = (w4 || w3) >> 32*/
        
        bn.sid x5, 0(x12++)                         /*x12[i] = x5*/

    ret


/**
 * Name:        ml_dsa_sub
 *
 * Description: Computes the coefficient wise subtraction of
 *              two vectors.
 *
 * Returns:
 *
 * Flags:
 *
 * @param[in]  x10: *veca       (pointer to input vector A)
 * @param[in]  x11: *vecb       (pointer to input vector B)
 * @param[in]   w0: zero        (all zeros)
 * @param[in]   w7: mask        (a mask for the lowest 32 bits)
 * @param[in]  MOD: modulus     (the modulus)
 * @param[out] x12: *vecc       (pointer to output vector C)
 *
 * clobbered registers: TODO
 *                      TODO
 */
.globl ml_dsa_sub
ml_dsa_sub:

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
            bn.rshi w2, w0, w2 >> 32                /*w2 = (w0 || w2) >> 32*/

            bn.subm w4, w4, w5                      /*w4 = w4 - w5 % MOD*/
            bn.rshi w3, w4, w3 >> 32                /*w3 = (w4 || w3) >> 32*/
        
        bn.sid x5, 0(x12++)                         /*x12[i] = x5*/

    ret


/**
 * Name:        ml_dsa_mul
 *
 * Description: Computes the coefficient wise multiplication of
 *              two vectors.
 *
 * Returns:
 *
 * Flags:
 *
 * @param[in]  x10: *veca       (pointer to input vector A)
 * @param[in]  x11: *vecb       (pointer to input vector B)
 * @param[in]   w0: zero        (all zeros)
 * @param[in]   w7: mask        (a mask for the lowest 32 bits)
 * @param[in]   w8: modulus     (the modulus)
 * @param[in]   w9: barrconst   (a constant used for barret multiplication)
 * @param[out] x12: *vecc       (pointer to output vector C)
 *
 * clobbered registers: TODO
 *                      TODO
 */
.globl ml_dsa_mul
ml_dsa_mul:

    /* Set up constants for input/state */
    li x6, 2
    li x5, 3

    bn.wsrw  MOD, w8
    bn.rshi  w11, w8, w0 >> 255                     /* w11 = 2*w8 */

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

    ret


/**
 * Name:        ml_dsa_mac
 *
 * Description: Computes the coefficient wise multiplication of
 *              two vectors and adds the result to a third vector.
 *
 * Returns:
 *
 * Flags:
 *
 * @param[in]  x10: *veca       (pointer to input vector A)
 * @param[in]  x11: *vecb       (pointer to input vector B)
 * @param[in]   w0: zero        (all zeros)
 * @param[in]   w7: mask        (a mask for the lowest 32 bits)
 * @param[in]   w8: modulus     (the modulus)
 * @param[in]   w9: barrconst   (a constant used for barret multiplication)
 * @param[out] x12: *vecc       (pointer to output vector C)
 *
 * clobbered registers: TODO
 *                      TODO
 */
.globl ml_dsa_mac
ml_dsa_mac:

    /* Set up constants for input/state */
    li x6, 2
    li x5, 3
    li x7, 12

    /* Copy the vector pointers. */
    add x13, x10, x0
    add x14, x11, x0
    add x15, x12, x0

    bn.wsrw  MOD, w8
    bn.rshi  w11, w8, w0 >> 255                     /* w11 = 2*w8 */

    LOOPI 32, 23
        bn.lid x6, 0(x13++)                         /* w2  = x13[i] */
        bn.lid x5, 0(x14++)                         /* w3  = x14[i] */
        bn.lid x7, 0(x15)                           /* w12 = x15[i] */

        LOOPI 8, 18
            /* Mask one coefficient to working registers */
            bn.and  w4,  w2, w7                     /*  w4 =  w2 & w7 */
            bn.and  w5,  w3, w7                     /*  w5 =  w3 & w7 */
            bn.and w13, w12, w7                     /* w13 = w12 & w7 */

            /* Shift out used coefficient */
            bn.rshi  w2, w0,  w2 >> 32              /* w2 = (w0 || w2) >> 32 */
            bn.rshi w12, w0, w12 >> 32              /* w12 = (w0 || w12) >> 32 */

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
            bn.addm w4, w4, w13

            /* Shift in result coefficient */
            bn.rshi w3, w4, w3 >> 32                /*w3 = (w4 || w3) >> 32*/
        
        bn.sid x5, 0(x15++)                         /*x15[i] = w3*/

    ret


/**
 * Name:        ml_dsa_ntt
 *
 * Description: Computes the number theoretic transform
 *              (NTT) of a vector.
 *
 * Returns:
 *
 * Flags:
 * 
 * @param[in]  x10: *ntt_w              (pointer to the input vector)
 * @param[in]  x11: *ntt_modified_zetas (pointer to the modified zetas)
 * @param[in]  x12: *constants          (pointer to the constants containing the modulus)
 * @param[in]   w0: zero                (all zeros)
 *
 * clobbered registers: TODO
 *                      TODO
 */
.globl ml_dsa_ntt
ml_dsa_ntt:

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

    /* Create mask */
    bn.addi w29,  w0, 1
    bn.or   w29,  w0, w29 << 32
    bn.subi w29, w29, 1

    /* Load modulus into w31 */
    bn.xor w31, w31, w31
    bn.lid x31, 0(x12)
    bn.and w31, w29, w31

    /* Set the modulus for modular operations */
    bn.wsrw MOD, w31

    /* Load modulus into w31.1 and have w31.0 be all zeros */
    bn.or w31, w31, w31 << 64

    /* Load 0x1 into w31.2 */
    bn.addi w2, w0, 1
    bn.or w31, w31, w2 << 128

    /* Load 32b mask into w31.3 */
    bn.or w31, w31, w29 << 192

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

    ret


/**
 * Name:        ml_dsa_intt
 *
 * Description: Computes the inverse number theoretic transform
 *              (INTT) of a vector.
 *
 * Returns:
 *
 * Flags:
 * 
 * @param[in]   x9: *ntt_f               (pointer to intt factor f)
 * @param[in]  x10: *ntt_w               (pointer to the input vector)
 * @param[in]  x11: *intt_modified_zetas (pointer to the modified zetas)
 * @param[in]  x12: *constants           (pointer to the constants containing the modulus)
 * @param[in]   w0: zero                 (all zeros)
 *
 * clobbered registers: TODO
 *                      TODO
 */

.globl ml_dsa_intt
ml_dsa_intt:

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

    /* Create mask */
    bn.addi w29,  w0, 1
    bn.or   w29,  w0, w29 << 32
    bn.subi w29, w29, 1

    /* Load modulus into w31 */
    bn.xor w31, w31, w31
    bn.lid x31, 0(x12)
    bn.and w31, w29, w31

    /* Set the modulus for modular operations */
    bn.wsrw MOD, w31

    /* Load modulus into w31.1 and have w31.0 be all zeros */
    bn.or w31, w31, w31 << 64

    /* Load 0x1 into w31.2 */
    bn.addi w2, w0, 1
    bn.or w31, w31, w2 << 128

    /* Load 32b mask into w31.3 */
    bn.or w31, w31, w29 << 192

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

    /* Set *ntt_w back to its original value */
    addi x10, x10, -32

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
            bn.lid x30, 0(x11)

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
            bn.lid x30, 32(x11)

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
            bn.lid x30, 64(x11)

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
            bn.lid x30, 96(x11)

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

    ret

/**
 * Returns (r0, r1) from the output of Decompose (r).
 * In memory, r is replaced by r0.
 *
 * Returns Integer r1.
 *
 * @param[in]      [x10]:       address for the ML-DSA constants
 * @param[in]      [x29]:       address for the barrett reduction constant
 * @param[in]      [x30]:       address for the modulus
 * @param[in]      [w0]:        all-zero
 * @param[in]      [w29]:       (q-1)/44 = 190464
 * @param[in/out]  [x11]:       address for the first share of the input vector r
 * @param[in/out]  [x12]:       address for the second share of the input vector r
 * @param[out]     [x13]:       address for the output vector r1
 *
 * clobbered registers:     w1 to w31, x1, x2, x11 to x13, x31
 */
.globl ml_dsa_decompose_vec
ml_dsa_decompose_vec:

    /* Loop over the vector. */
    loopi 32, 37

        /* Apply the decompose sub-routine coefficient-wise. */
        loopi 8, 33

            /* Init 32 bit mask */
            bn.addi w7, w0, 1
            bn.or w7, w0, w7 << 32
            bn.subi w7, w7, 1

            /* Load the plantard constant into w23 */
            li  x8, 23
            bn.lid x8, 0(x10)
            bn.and w23, w7, w23 >> 64

            /* Load the barrett constant (q-1)/44 into w29 */
            li  x8, 29
            bn.lid x8, 0(x10)
            bn.and w29, w7, w29 >> 96

            /* Load the modulus into w30 */
            li x8, 30
            bn.lid x8, 0(x30)

            /* Load both shares of the first coefficient of r into w27 and w28. */
            li  x8, 27
            bn.lid x8, 0(x11)
            bn.and w27, w7, w27

            li  x8, 28
            bn.lid x8, 0(x12)
            bn.and w28, w7, w28

            /* Run the decompose routine. */
            jal  x1, ml_dsa_sec_decompose

            /* Load the current eight coefficients for r0 and r1 into w1, w2 and w3. */
            li  x8, 1
            bn.lid x8, 0(x11)

            li  x8, 2
            bn.lid x8, 0(x12)

            li  x8, 3
            bn.lid x8, 0(x13)

            /* Shift in the result for r0 and r1 from the decompose routine. */
            bn.rshi w27, w1, w27 >> 32
            bn.rshi w28, w2, w28 >> 32
            bn.rshi w23, w3, w23 >> 32

            /* Store the current eight coefficients back to memory. */
            li  x8, 27
            bn.sid x8, 0(x11)

            li  x8, 28
            bn.sid x8, 0(x12)

            li  x8, 23
            bn.sid x8, 0(x13)

        /* Increment the vector addresses. */
        addi x11, x11, 1
        addi x12, x12, 1
        addi x13, x13, 1

    ret


/**
 * Decomposes r into (r1, r0) such that r ≡ r1(2*GAMMA2) + r0 mod q.
 *
 * Returns Integers (r1, r0).
 *
 * @param[in]  [x29]:       address for the barrett reduction constant
 * @param[in]  [x30]:       address for the modulus
 * @param[in]  [w0]:        all-zero
 * @param[in]  [w23]:       plantard constant (-44 in plantard space)
 * @param[in]  [w27:w28]:   r^(A,k)
 * @param[in]  [w29]:       (q-1)/44 = 190464
 * @param[in]  [w30]:       modulus
 * @param[out] [w23]:       r1
 * @param[out] [w27:w28]:   r0^(A,k)
 *
 * clobbered registers:     w1 to w28, w30, w31, x1, x2, x31
 */
.globl ml_dsa_sec_decompose
ml_dsa_sec_decompose:

    /* Copy [w27:w28] to [w21:w22] */
    bn.add w21, w27, w0
    bn.add w22, w28, w0

    /* Set w1 = 1 */
    bn.addi w1, w0, 1

    /* Plantard multiplication: plantard(-44) * r[0] */
    /* t = (0xDE3CEF7F65FA7FD5 * r[0]) % (2**64) */
    bn.mulqacc.wo.z w21, w21.0, w23.0, 192
    /* t = (t >> 32) + 1 */
    bn.add w21, w1, w21 >> 224
    /* t *= q */
    bn.mulqacc.wo.z w21, w21.0, w30.0, 0
    /* t = t >> 32 */
    bn.rshi w21, w0, w21 >> 32
    bn.subm w21, w30, w21

    /* Plantard multiplication: plantard(-44) * r[0] */
    /* t = (0xDE3CEF7F65FA7FD5 * r[0]) % (2**64) */
    bn.mulqacc.wo.z w22, w22.0, w23.0, 192
    /* t = (t >> 32) + 1 */
    bn.add w22, w1, w22 >> 224
    /* t *= q */
    bn.mulqacc.wo.z w22, w22.0, w30.0, 0
    /* t = t >> 32 */
    bn.rshi w22, w0, w22 >> 32
    bn.subm w22, w30, w22

    /* Set w21 to s^(B,k)_0 = s^(B,k)_0 + (q-1)/2 */
    bn.rshi w2, w0, w30 >> 1
    bn.addm w21, w21, w2

    /* Set [w5:w6] to s'^(B,k) = A2B(s^(A_q)) */
    jal  x1, ml_dsa_sec_a2b

    /* Set the modulus for modular operations */
    bn.addi w30, w0, 44
    bn.wsrw MOD, w30

    /* Move [w5:w6] to [w25:w26] */
    bn.add w25, w5, w0
    bn.add w26, w6, w0

    /* Set [w23:w24] to s'^(B,k) = B2A(s^(A_q)) */
    jal  x1, ml_dsa_sec_b2a_44

    /* Calculate r0 */
    bn.add w23, w23, w24

    /* Barrett reduction for r0 */
    li x2, 5
    bn.lid x2, 0(x29)

    bn.addi w6, w0, 44

    bn.mulqacc.wo.z w24, w23.0, w5.0, 0
    bn.rshi w24, w0, w24 >> 23
    bn.mulqacc.wo.z w24, w24.0, w6.0, 0
    bn.sub  w23, w23, w24
    bn.addm w23, w23, w0

    /* Set the modulus back to it's original value. */
    li x2, 30
    bn.lid x2, 0(x30)
    bn.wsrw MOD, w30

    bn.add w24, w0, w29
    bn.mulqacc.wo.z w24, w23.0, w24.0, 0
    bn.subm w27, w27, w24

    ret


/**
 * Checks if arithmetic sharing x^(A,k) is between two values -lambda0 <= x <= lambda1.
 *
 * Returns a public bit b with b = 1 if -lambda0 <= x <= lambda1 and b = 0 otherwise.
 *
 * @param[in]  [x11]:   address for the first share of the input vector r
 * @param[in]  [x12]:   address for the second share of the input vector r
 * @param[in]  [w0]:    all-zero
 * @param[in]  [w23]:   lambda0
 * @param[in]  [w24]:   lambda1
 * @param[in]  [w30]:   modulus
 * @param[out] [w29]:   result bit b
 *
 * clobbered registers:     w1 to w24, w31, x1, x2, x5, x6, x31
 */

.globl ml_dsa_sec_bound_check_vec
ml_dsa_sec_bound_check_vec:

    /* Set the result bit b to it's initial value. */
    bn.addi w29, w0, 1

    /* Init mask */
    bn.addi w27, w0, 1
    bn.or w27, w0, w27 << 32
    bn.subi w27, w27, 1

    li x5, 25
    li x6, 26

    LOOPI 32, 10
        bn.lid x5, 0(x11++)
        bn.lid x6, 0(x12++)

        LOOPI 8, 6
            /* Mask one coefficient to working registers */
            bn.and w21, w25, w27
            bn.and w22, w26, w27

            /* Shift out used coefficient */
            bn.rshi w21, w0, w21 >> 32
            bn.rshi w22, w0, w22 >> 32

            /* Execute the coefficient secure bound check. */
            jal x1, ml_dsa_sec_bound_check

            /* And the the coefficient result bit with the vector result bit. */
            bn.and w29, w29, w5

        /* Dummy instruction to close the outer loop. */
        bn.xor w0, w0, w0

    ret


/**
 * Checks if arithmetic sharing x^(A,k) is between two values -lambda0 <= x <= lambda1.
 *
 * Returns a public bit b with b = 1 if -lambda0 <= x <= lambda1 and b = 0 otherwise.
 *
 * @param[in]  [w0]:        all-zero
 * @param[in]  [w21:w22]:   x^(A,k)
 * @param[in]  [w23]:       lambda0
 * @param[in]  [w24]:       lambda1
 * @param[in]  [w30]:       modulus
 * @param[out] [w5]:        b
 *
 * clobbered registers:     w1 to w24, w31, x1, x2, x31
 */
.globl ml_dsa_sec_bound_check
ml_dsa_sec_bound_check:

    /* Add lambda0 to x^(A,k)_0 */
    bn.addm w21, w21, w23

    /* Set [w5:w6] to x^(B,k) = A2B(x^(A_q)) */
    jal  x1, ml_dsa_sec_a2b

    /* Move [w5:w6] to [w1:w2] */
    bn.add w1, w5, w0
    bn.add w2, w6, w0

    /* Set w4 to psi = lambda0 + lambda1. */
    bn.add w4, w23, w24

    /* Set w5 to b = 1 if x <= psi and b = 0 otherwise. */
    jal  x1, ml_dsa_sec_leq

    ret


/**
 * Checks if boolean sharing x^(B,k) is less or equal to some value psi.
 *
 * Returns a public bit b with b = 1 if x <= psi and b = 0 otherwise.
 *
 * @param[in]  [w0]:      all-zero
 * @param[in]  [w1:w2]:   x^(B,k)
 * @param[in]  [w4]:      psi
 * @param[out] [w5]:      b
 *
 * clobbered registers: w1 to w20, w31
 */
.globl ml_dsa_sec_leq
ml_dsa_sec_leq:

    /* Crate 23 bit mask. */
    bn.addi w7, w0, 1
    bn.rshi w7, w7, w0 >> 232
    bn.subi w7, w7, 1

    /* Set [w3:w4] to t^(B,k) = (2^(k+1) - gamma_1 + beta - 1, 0) */
    bn.sub w3, w7, w4
    bn.xor w4, w4, w4

    /* Set [w5:w6] to x'^(B,k+1) = x^(B,k) + t^(B,k) */
    jal  x1, ml_dsa_sec_add

    /* Set [w5:w6] to x'^(B,k+1)[k] */
    bn.addi w8, w0, 1
    bn.rshi w5, w0, w5 >> 23
    bn.and  w5, w5, w8
    bn.rshi w6, w0, w6 >> 23
    bn.and  w6, w6, w8

    /* Get one bit of randomness to refresh x'^(B,k+1)[k] */
    bn.wsrr  w9, URND
    bn.and  w10, w9, w8

    /* Unmask x'^(B,k+1)[k] */
    bn.xor w5, w5, w10
    bn.xor w6, w6, w10
    bn.xor w5, w5, w6

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
.globl ml_dsa_sec_b2a_44
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
    bn.add w23, w0, w21

    bn.sub w21, w30, w21
    bn.xor w22, w22, w22

    /* Set [w5:w6] to a^(B,k) = A2B(z'^(A_p)) */
    jal  x1, ml_dsa_sec_a2b

    /* Move [w5:w6] to [w1:w2] */
    bn.add w1, w5, w0
    bn.add w2, w6, w0

    /* Load x^(B,k) into w3 and w4 */
    bn.add w3, w25, w0
    bn.add w4, w26, w0

    /* Set [w5:w6] to b^(B,k) = a^(B,k) + x^(B,k) % q */
    jal  x1, ml_dsa_sec_addm

    /* Refresh b^(B,k) */
    bn.xor w5, w5, w24 >> 32
    bn.xor w6, w6, w24 >> 32

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
.globl ml_dsa_sec_a2b
ml_dsa_sec_a2b:

    /* p^(B,k+1) = (2^k - q, 0) */
    bn.addi w3, w0, 1
    bn.rshi w3, w3, w0 >> 232
    bn.sub  w3, w3, w30

    bn.xor w4, w4, w4

    /* y^(B,k) = (x^(B,k)[0], 0) */
    bn.add w1, w0, w21
    bn.xor w2, w2,  w2

    /* Set [w5:w6] to s^(B,k+1) = p^(B,k+1) + y^(B,k) */
    jal  x1, ml_dsa_sec_add

    /* Move [w5:w6] to [w1:w2] */
    bn.add w1, w5, w0
    bn.add w2, w6, w0

    /* s'^(B,k) = (0, x^(B,k)[1]) */
    bn.xor w3, w3, w3
    bn.add w4, w0, w22

    /* Set [w5:w6] to u^(B,k+1) = s^(B,k+1) + s'^(B,k) */
    jal  x1, ml_dsa_sec_add

    /* Move [w5:w6] to [w1:w2] */
    bn.add w1, w5, w0
    bn.add w2, w6, w0

    /* Set [w3:w4] to a^(B,k) = u^(B,k+1)[k] * q */
    bn.rshi w3, w0, w5 >> 23
    bn.rshi w4, w0, w6 >> 23

    bn.mulqacc.wo.z w3, w3.0, w30.0, 0
    bn.mulqacc.wo.z w4, w4.0, w30.0, 0

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
.globl ml_dsa_sec_addm
ml_dsa_sec_addm:

    /* Set [w5:w6] to s^(B,k+1) = x^(B,k) + y^(B,k) */
    jal  x1, ml_dsa_sec_add

    /* p^(B,k+1) = (2^k - q, 0) */
    bn.addi w3, w0, 1
    bn.rshi w3, w3, w0 >> 232
    bn.sub  w3, w3, w30

    /* Zero out w4 */
    bn.xor w4, w4, w4

    /* Move [w5:w6] to [w1:w2] */
    bn.add w1, w5, w0
    bn.add w2, w6, w0

    /* Set [w5:w6] to s'^(B,k+1) = s^(B,k+1) + p^(B,k+1) */
    jal  x1, ml_dsa_sec_add

    /* Move [w5:w6] to [w1:w2] */
    bn.add w1, w5, w0
    bn.add w2, w6, w0

    /* Set [w3:w4] to a^(B,k) = s'^(B,k+1)[k] * q */
    bn.rshi w3, w0, w5 >> 23
    bn.rshi w4, w0, w6 >> 23

    bn.mulqacc.wo.z w3, w3.0, w30.0, 0
    bn.mulqacc.wo.z w4, w4.0, w30.0, 0

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
.globl ml_dsa_sec_add
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

    LOOPI 23, 32
        /* move the ith share bits of x into w9 and w10 */
        bn.and  w9, w1, w31
        bn.and w10, w2, w31

        /* move the ith share bits of y into w11 and w12 */
        bn.and w11, w3, w31
        bn.and w12, w4, w31

        /* move the ith bit of r into w17 */
        bn.and w17, w15, w31

        /* b = x ^ z */
        bn.xor w13,  w9, w7
        bn.xor w14, w10, w8

        /* a = x ^ y */
        bn.xor w11,  w9, w11
        bn.xor w12, w10, w12

        /* c = z ^ a */
        bn.xor w7, w7, w11
        bn.xor w8, w8, w12

        /* SecAnd */
        /* t = a & r */
        bn.and w19, w11, w17
        bn.and w20, w12, w17

        /* t = t ^ r */
        bn.xor w19, w19, w17
        bn.xor w20, w20, w17

        /* r = r ^ b */
        bn.xor w18, w17, w13
        bn.xor w17, w17, w14

        /* r = r & a */
        bn.and w17, w17, w11
        bn.and w18, w18, w12

        /* r = r ^ t */
        bn.xor w17, w17, w19
        bn.xor w18, w18, w20

        /* a = a & b */
        bn.and w11, w11, w13
        bn.and w12, w12, w14

        /* a = a ^ r */
        bn.xor w11, w11, w17
        bn.xor w12, w12, w18

        /* End of SecAnd */

        /* x = x ^ a */
        bn.xor  w9,  w9, w11
        bn.xor w10, w10, w12

        /* z = z | x */
        bn.or w5, w5, w7
        bn.or w6, w6, w8

        /* Shift bit mask and c one bit to the left */
        bn.rshi w31, w31, w0 >> 255
        bn.rshi  w7,  w9, w0 >> 255
        bn.rshi  w8, w10, w0 >> 255
    
    /* move the 24th share bits of x into w9 and w10 */
    bn.and  w9, w1, w31
    bn.and w10, w2, w31

    /* move the 24th share bits of y into w11 and w12 */
    bn.and w11, w3, w31
    bn.and w12, w4, w31

    /* x = x ^ c */
    bn.xor  w9,  w9, w7
    bn.xor w10, w10, w8

    /* x = x ^ y */
    bn.xor  w9,  w9, w11
    bn.xor w10, w10, w12

    /* z = z | x */
    bn.or w5, w5,  w9
    bn.or w6, w6, w10

    ret

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

    .globl intt_modified_zetas
    .balign 256
    intt_modified_zetas:
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
    .word 0xAE213AF3
    .word 0x254DC526
    .word 0xA0F3ABAA
    .word 0xEEF89A48
    .word 0x581FF54E
    .word 0x1EB51B09
    .word 0xA0B34390
    .word 0x8CFE3A74
    .word 0x3FE6FB40
    .word 0xBEEFF47F
    .word 0x0AF96444
    .word 0xAE1024AD
    .word 0xB81BB17D
    .word 0x93C9492A
    .word 0xC835B7DE
    .word 0x12613E2A
    .word 0xF1C02827
    .word 0x61CB9E23
    .word 0x1AC460E3
    .word 0x6017A128
    .word 0x17C3C0C1
    .word 0x58172118
    .word 0xF8C1A879
    .word 0x61CC1E43
    .word 0x0FD9F05D
    .word 0x8D187503
    .word 0x4FB1E7DB
    .word 0x8CF87102
    .word 0xFF35DF7A
    .word 0x6D1F44F6
    .word 0x00000000
    .word 0x00000000

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

    .globl ml_dsa_s1_s1
    .balign 32
    ml_dsa_s1_s1:
    .zero 4096

    .globl ml_dsa_s1_s2
    .balign 32
    ml_dsa_s1_s2:
    .zero 4096

    .globl ml_dsa_s2_s1
    .balign 32
    ml_dsa_s2_s1:
    .zero 4096

    .globl ml_dsa_s2_s2
    .balign 32
    ml_dsa_s2_s2:
    .zero 4096

    .globl ml_dsa_mat_a_hat
    .balign 32
    ml_dsa_mat_a_hat:
    .zero 16384

    .globl ml_dsa_y_s1
    .balign 32
    ml_dsa_y_s1:
    .zero 4096

    .globl ml_dsa_y_s2
    .balign 32
    ml_dsa_y_s2:
    .zero 4096

    .globl ml_dsa_w_s1
    .balign 32
    ml_dsa_w_s1:
    .zero 4096

    .globl ml_dsa_w_s2
    .balign 32
    ml_dsa_w_s2:
    .zero 4096

    .globl ml_dsa_w1
    .balign 32
    ml_dsa_w1:
    .zero 4096

    .globl ml_dsa_c
    .balign 32
    ml_dsa_c:
    .zero 4096

    .globl ml_dsa_rej
    .balign 32
    ml_dsa_rej:
    .word 0x00000001
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000
    .word 0x00000000

/**
 * Constants:
 * - modulus
 * - barrett multiplication constant r
 * - plantard multiplication constant (-44 in plantard space)
 * - barrett multiplication constant ((q-1)/44)
 * - Gamma1 - Beta
 * - Gamma2 - Beta
 * - Gamma2
 *
 */
    .globl constants
    .balign 32
    constants:
    .word 0x007FE001
    .word 0x00802007
    .word 0x04D10839
    .word 0x0002E8BA
    .word 0x0007ff88
    .word 0x0003fe88
    .word 0x00017400
    .word 0x00000000

.section .scratchpad
    .globl ntt_f
    .balign 32
    ntt_f:
    .zero 32

    .globl modulus_scratch
    .balign 32
    modulus_scratch:
    .zero 32

    .globl barrett_r_scratch
    .balign 32
    barrett_r_scratch:
    .zero 32
