// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// otbn_sec_add_pkg

package otbn_sec_add_pkg;

  typedef enum logic [1:0] {
    ModeSecAdd    = 2'b00,
    ModeSecAddMod = 2'b01,
    ModeA2B       = 2'b10,
    ModeB2A       = 2'b11
  } adder_mode_e;

endpackage : otbn_sec_add_pkg
