/* Copyright lowRISC contributors (OpenTitan project). */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

/**
 * Unified boot-services OTBN program.
 *
 * During the boot process, this program should remain loaded. This binary has
 * the following modes:
 *   1. MODE_P256_SIGVERIFY: ECDSA-P256 signature verification.
 *   2. MODE_P256_ATTESTATION_KEYGEN: Derive a new attestation keypair (ECDSA-P256).
 *   3. MODE_P256_ATTESTATION_ENDORSE: Sign with a saved attestation signing key (ECDSA-P256).
 *   4. MODE_P256_ATTESTATION_KEY_SAVE: Save an attestation signing key (ECDSA-P256).
 *   5. MODE_MLDSA87_SIGVERIFY: ML-DSA-87 signature verification.
 *
 * Ibex will run `MODE_SEC_BOOT_MODEXP` as part of checking the code
 * signature of the next boot stage. This mode doesn't interact or interfere
 * with any other modes, and can be called at any point.
 *
 * The attestation modes are more entangled with each other. Part of the
 * purpose of this program is to store the attestation key of a particular key
 * manager stage long enough to sign the public key of the next stage, without
 * rebooting. At each key manager stage, Ibex should:
 *   - Call `MODE_P256_ATTESTATION_KEYGEN` to get the current public key
 *   - Construct the attestation certificate for the current stage, including
 *     the public key
 *   - Call `MODE_P256_ATTESTATION_ENDORSE` to sign the certificate with the stored
 *     signing key from the *previous stage* and clear the key
 *   - Call `MODE_P256_ATTESTATION_KEY_SAVE` to save the current stage's signing
 *     key, which will later endorse the next stage's certificate
 *
 * Of course, in the first stage there is no previous stage signing key and no
 * certificate, so Ibex should skip the `MODE_P256_ATTESTATION_ENDORSE` step. Ibex
 * may clear IMEM/DMEM if it needs to run a different OTBN routine (e.g.
 * signature verification for ownership transfer), but doing so will wipe any
 * saved keys. This binary is designed so that it should not need to be
 * cleared and re-loaded on a normal boot.
 *
 * The attestation keys are derived from a key manager seed value, which is
 * XORed with output from a specially seeded DRBG in order to satisfy the FIPS
 * 186-5 requirement that the seed comes from a DRBG (other FIPS documents say
 * it is permissible to XOR DRBG output with implementation-specific values, so
 * the key manager seed is effectively ignored for FIPS compliance).  The saved
 * signing key is stored in OTBN's scratchpad memory, which is not accessible
 * to Ibex over the bus.
 */

/**
 * Mode magic values, generated with
 * $ ./util/design/sparse-fsm-encode.py -d 6 -m 5 -n 11 --avoid-zero -s 3357382482
 *
 * Call the same utility with the same arguments and a higher -m to generate
 * additional value(s) without changing the others or sacrificing mutual HD.
 *
 * TODO(#17727): in some places the OTBN assembler support for .equ directives
 * is lacking, so they cannot be used in bignum instructions or pseudo-ops such
 * as `li`. If support is added, we could use 32-bit values here instead of
 * 11-bit.
 */
.equ MODE_P256_SIGVERIFY, 0x7d3
.equ MODE_P256_ATTESTATION_KEYGEN, 0x2bf
.equ MODE_P256_ATTESTATION_ENDORSE, 0x5e8
.equ MODE_P256_ATTESTATION_KEY_SAVE, 0x64d
.equ MODE_MLDSA87_SIGVERIFY, 0x176

.section .text.start
start:
  /* Read the mode and tail-call the requested operation. */
  la    x2, mode
  lw    x2, 0(x2)

  addi  x3, x0, MODE_P256_SIGVERIFY
  beq   x2, x3, p256_sigverify

  addi  x3, x0, MODE_P256_ATTESTATION_KEYGEN
  beq   x2, x3, p256_attestation_keygen

  addi  x3, x0, MODE_P256_ATTESTATION_ENDORSE
  beq   x2, x3, p256_attestation_endorse

  addi  x3, x0, MODE_P256_ATTESTATION_KEY_SAVE
  beq   x2, x3, p256_attestation_key_save

  addi  x3, x0, MODE_MLDSA87_SIGVERIFY
  beq   x2, x3, mldsa87_verify

  /* Invalid mode; fail. */
start_failed:
  unimp
  unimp
  unimp

/**
 * ECDSA-P256 signature verification.
 *
 * The result of the verification is returned in two variables: `ok`
 * indicates whether the signature passed basic validity checks, and `x_r`
 * indicates the recovered value. A signature passes verification only if BOTH:
 * - `ok` is true, and
 * - `x_r` is equal to the original `r` value.
 *
 * If `ok` is false, the value in `x_r` is meaningless; callers
 * should check both.
 *
 * @param[in]  dmem[msg]: message to be verified (256 bits)
 * @param[in]  dmem[r]:   r component of signature (256 bits)
 * @param[in]  dmem[s]:   s component of signature (256 bits)
 * @param[in]  dmem[x]:   affine x-coordinate of public key (256 bits)
 * @param[in]  dmem[y]:   affine y-coordinate of public key (256 bits)
 * @param[out] dmem[ok]:  success/failure of basic checks (32 bits)
 * @param[out] dmem[x_r]: dmem buffer for reduced affine x_r-coordinate (x_1)
 */
p256_sigverify:
  /* Validate the public key (ends the program on failure). */
  jal      x1, p256_check_public_key

  /* Verify the signature (compute x_r). */
  jal      x1, p256_verify

  ecall

/**
 * Generate an attestation keypair from a sideloaded seed.
 *
 * Takes two input seeds, one from the key manager in the key-sideload slots
 * and one from DMEM that is expected to be the output of a DRBG and fully
 * independent from the first. For both seeds, only the first 320 bits are used
 * and the rest are ignored.
 *
 * @param[in]  dmem[attestation_additional_seed]: DRBG output.
 * @param[out]  dmem[x]: Public key x-coordinate.
 * @param[out]  dmem[y]: Public key y-coordinate.
 */
p256_attestation_keygen:
  /* Initialize all-zero register. */
  bn.xor   w31, w31, w31

  /* Generate secret key in shares.
       w20, w21 <= d0 (first share of secret key)
       w10, w11 <= d1 (second share of secret key) */
  jal      x1, p256_attestation_secret_key_from_seed

  /* Call scalar multiplication with base point.
     R = (x_p, y_p, z_p) = (w8, w9, w10) <= d*G */
  bn.mov    w0, w20
  bn.mov    w2, w10
  bn.mov    w1, w21
  bn.mov    w3, w11
  la        x21, p256_gx
  la        x22, p256_gy
  jal       x1, scalar_mult_int

  /* Convert masked result back to affine coordinates.
     R = (x_a, y_a) = (w11, w12) */
  jal       x1, proj_to_affine

  /* Store public key in DMEM.
     dmem[x] <= x_a = w11
     dmem[y] <= y_a = w12 */
  li        x2, 11
  la        x21, x
  bn.sid    x2++, 0(x21)
  la        x22, y
  bn.sid    x2, 0(x22)

  /* Compute both sides of the Weierstrauss equation.
       w18 <= (x^3 + ax + b) mod p
       w19 <= (y^2) mod p */
  jal      x1, p256_isoncurve

  /* Compare the two sides of the equation to check if the result
     is a valid point as an FI countermeasure.
     The check fails if both sides are not equal.
     FG0.Z <= (y^2) mod p == (x^2 + ax + b) mod p */
  bn.cmp   w18, w19
  jal      x1, trigger_fault_if_fg0_z

  ecall

/**
 * Sign a message using the saved signing key from the scratchpad.
 *
 * Clears the saved key after use, so only one signature is possible with a
 * saved key.
 *
 * @param[in]  dmem[msg]: Message digest (256 bits)
 * @param[in]   dmem[d0]: First share of private key d (320 bits)
 * @param[in]   dmem[d1]: Second share of private key d (320 bits)
 * @param[out]   dmem[r]: Buffer for r component of signature (256 bits)
 * @param[out]   dmem[s]: Buffer for s component of signature (256 bits)
 */
p256_attestation_endorse:
  /* Generate a fresh random scalar for signing.
       dmem[k0] <= first share of k
       dmem[k1] <= second share of k */
  jal      x1, p256_generate_k

  /* Generate the signature.
       dmem[r], dmem[s] <= signature */
  jal      x1, p256_sign

  /* Clear the saved key by overwriting with random data.
       dmem[d0], dmem[d1] <= RND */
  li        x20, 20
  la        x2, d0
  bn.wsrr   w20, RND
  bn.sid    x20, 0(x2++)
  bn.wsrr   w20, RND
  bn.sid    x20, 0(x2)
  la        x2, d1
  bn.wsrr   w20, RND
  bn.sid    x20, 0(x2++)
  bn.wsrr   w20, RND
  bn.sid    x20, 0(x2)

  ecall

/**
 * Save an attestation signing key to the scratchpad.
 *
 * @param[in]  dmem[attestation_additional_seed]: DRBG output.
 * @param[out]  dmem[d0]: First share of private key (320 bits).
 * @param[out]  dmem[d1]: Second share of private key (320 bits).
 */
p256_attestation_key_save:
  /* Initialize all-zero register. */
  bn.xor   w31, w31, w31

  /* Generate secret key in shares.
       w20, w21 <= d0 (first share of secret key)
       w10, w11 <= d1 (second share of secret key) */
  jal      x1, p256_attestation_secret_key_from_seed

  /* Store secret key in DMEM.
     dmem[d0] <= w20, w21 = d0
     dmem[d1] <= w10, w11 = d1 */
  li        x2, 20
  la        x3, d0
  bn.sid    x2++, 0(x3)
  bn.sid    x2, 32(x3)
  li        x2, 10
  la        x3, d1
  bn.sid    x2++, 0(x3)
  bn.sid    x2, 32(x3)

  ecall

/**
 * Generate an attestation secret key from a sideloaded seed.
 *
 * Takes two input seeds, one from the key manager in the key-sideload slots
 * and one from DMEM that is expected to be the output of a DRBG and fully
 * independent from the first. For both seeds, only the first 320 bits are used
 * and the rest are ignored.
 *
 * Returns the key in two 320-bit shares d0 and d1, such that the secret key d
 * = (d0 + d1) mod n.
 *
 * @param[in]   w31: all-zero
 * @param[in]  dmem[attestation_additional_seed]: DRBG output seed
 * @param[out]  w20: Lower 256 bits of first share of secret key (d0)
 * @param[out]  w21: Upper 64 bits of first share of secret key (d0)
 * @param[out]  w10: Lower 256 bits of first share of secret key (d1)
 * @param[out]  w11: Upper 64 bits of second share of secret key (d1)
 *
 * clobbered registers: x2, x3, x20, w1 to w4, w10, w11, w20 to w29
 * clobbered flag groups: FG0
 */
p256_attestation_secret_key_from_seed:
  /* Load keymgr seeds from WSRs.
       w20,w21 <= seed0
       w10,w11 <= seed1 */
  bn.wsrr  w20, KEY_S0_L
  bn.wsrr  w10, KEY_S1_L
  bn.wsrr  w21, KEY_S0_H
  bn.wsrr  w11, KEY_S1_H

  /* Load the additional DRBG seed from DMEM and XOR with one share of the
     sideloaded seed.
       w20, w21 <= seed0 ^ dmem[attestation_additional_seed] */
  la       x2, attestation_additional_seed
  li       x3, 22
  bn.lid   x3++, 0(x2)
  bn.xor   w20, w20, w22
  bn.lid   x3, 32(x2)
  bn.xor   w21, w21, w23

  /* Tail-call `p256_key_from_seed` to generate secret key shares.
       w20, w21 <= d0
       w10, w11 <= d1 */
  jal      x0, p256_key_from_seed

.bss

/* Operation mode. */
.globl mode
.balign 4
mode:
.zero 4

/* Status of validity checks on the public key and signature (for verify). */
.globl ok
.balign 4
ok:
  .zero 4

/* Input buffer for an ECDSA-P256 message digest. */
.globl msg
.balign 32
msg:
.zero 32

/* Output buffer for the first part of an ECDSA-P256 signature. */
.globl r
.balign 32
r:
.zero 32

/* Output buffer for the second part of an ECDSA-P256 signature. */
.globl s
.balign 32
s:
.zero 32

/* ECDSA-P256 public key x-coordinate. */
.globl x
.balign 32
x:
.zero 32

/* ECDSA-P256 public key y-coordinate. */
.globl y
.balign 32
y:
.zero 32

/* Verification result x_r (aka x_1). */
.globl x_r
.balign 32
x_r:
  .zero 32

/* DRBG output to XOR with key manager seed. */
.globl attestation_additional_seed
.balign 32
attestation_additional_seed:
.zero 64

.data
.balign 32

/*
 * ML-DSA-87 verify public key.
 */

.globl mldsa87_verify_pk
.globl mldsa87_verify_pk_rho
.globl mldsa87_verify_pk_t1

mldsa87_verify_pk:
mldsa87_verify_pk_rho:
.zero 32
mldsa87_verify_pk_t1:
.zero 2560

/*
 * ML-DSA-87 verify signature.
 */

.globl mldsa87_verify_sig
.globl mldsa87_verify_sig_c_tilde
.globl mldsa87_verify_sig_z
.globl mldsa87_verify_sig_h

mldsa87_verify_sig:
mldsa87_verify_sig_c_tilde:
.zero 64
mldsa87_verify_sig_z:
.zero 4480
mldsa87_verify_sig_h:
.zero 83
.zero 13 /* Padding */

/*
 * ML-DSA-87 verify message.
 */

.globl mldsa87_verify_mu

mldsa87_verify_mu:
.zero 64

/*
 * ML-DSA-87 verify result.
 */

.globl mldsa87_verify_res_ok
.globl mldsa87_verify_res_c_tilde_prime

mldsa87_verify_res_ok:
.zero 4
.zero 28 /* Padding */
mldsa87_verify_res_c_tilde_prime:
.zero 64

/*
 * ML-DSA-87 verify intermediate variables.
 */

.globl mldsa87_verify_var_rho
.globl mldsa87_verify_var_c
.globl mldsa87_verify_var_h

/* RHO with indices */
mldsa87_verify_var_rho:
.zero 32
.zero 2  /* r, s */
.zero 30 /* Padding */
/* Challenge polynomial */
mldsa87_verify_var_c:
.zero 1024
/* Encoded hint in intermediate representation. */
mldsa87_verify_var_h:
.zero 336
.zero 16 /* Padding */

/*
 * ML-DSA-87 verify polynomial slots.
 */

.globl mldsa87_verify_poly_slot0
.globl mldsa87_verify_poly_slot1
.globl mldsa87_verify_poly_slot2

mldsa87_verify_poly_slot0:
.zero 1024
mldsa87_verify_poly_slot1:
.zero 1024
mldsa87_verify_poly_slot2:
.zero 1024

/*
 * ML-DSA-87 verify constants.
 */

.globl mldsa87_verify_const_params
.globl mldsa87_verify_const_gamma1_beta_bound

/*
 * q  = 8380417 = 2^23 - 2^13 + 1 (ML-DSA modulus)
 * mu = -q^-1 mod R (Montgomery constant)
 * f  = 256^-1 * R^2 mod q (INTT divisor time R in Montgomery domain)
 */
mldsa87_verify_const_params:
.word 0x007fe001 /* q */
.word 0xfc7fdfff /* mu */
.word 0x0000a3fa /* f */
.word 0x00000000
.word 0x00000000
.word 0x00000000
.word 0x00000000
.word 0x00000000

/* GAMMA1 - BETA = 2^19 - 120. */
mldsa87_verify_const_gamma1_beta_bound:
.word 0x0007ff88
.word 0x0007ff88
.word 0x0007ff88
.word 0x0007ff88
.word 0x0007ff88
.word 0x0007ff88
.word 0x0007ff88
.word 0x0007ff88

/* ML-DSA-87 verify call stack, used by mldsa87_verify.s and its callees. */
.globl stack

stack:
.zero 256

.section .scratchpad
.balign 32

/*
 * ML-DSA-87 verify vector slots.
 */
.globl mldsa87_verify_vector_slot0
.globl mldsa87_verify_vector_slot1

mldsa87_verify_vector_slot0:
.zero 8192
mldsa87_verify_vector_slot1:
.zero 8192

/* First share of the saved attestation ECDSA-P256 private key (d).
   Aliased into mldsa87_verify_vector_slot0. */
.globl d0
.equ d0, mldsa87_verify_vector_slot0

/* Second share of the saved attestation ECDSA-P256 private key (d). */
.globl d1
.equ d1, d0 + 64

/* First share of the per-signature ECDSA-P256 secret scalar (k). */
.globl k0
.equ k0, d1 + 64

/* Second share of the per-signature ECDSA-P256 secret scalar (k). */
.globl k1
.equ k1, k0 + 64

/* Buffer for the squared Montgomery Radix RR = (2^3072)^2 mod M.
   Populated by the RSA-3072 implementation. */
.globl rr
.equ rr, k1 + 64

/* Switch back to .text: some files assembled after this one (e.g.
   mldsa87_verify_encoding.s) have no leading section directive of their own
   and would otherwise silently inherit whatever section is active here. */
.text
