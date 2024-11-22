// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "sw/device/lib/base/status.h"
#include "sw/device/lib/ujson/ujson.h"

status_t handle_ml_dsa_pentest_init(ujson_t *uj);
status_t handle_ml_dsa_sca_single_ntt(ujson_t *uj);
status_t handle_ml_dsa_sca(ujson_t *uj);
