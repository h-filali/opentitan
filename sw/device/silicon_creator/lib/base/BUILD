# Copyright lowRISC contributors (OpenTitan project).
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

load("//rules:cross_platform.bzl", "dual_cc_device_library_of", "dual_cc_library", "dual_inputs")
load("//rules:linker.bzl", "ld_library")

package(default_visibility = ["//visibility:public"])

exports_files([
    "mock_csr.h",
    "mock_csr.cc",
    "mock_csr_test.cc",
])

dual_cc_library(
    name = "sec_mmio",
    srcs = dual_inputs(
        device = ["sec_mmio.c"],
        host = ["mock_sec_mmio.cc"],
    ),
    hdrs = dual_inputs(
        host = ["mock_sec_mmio.h"],
        shared = ["sec_mmio.h"],
    ),
    deps = dual_inputs(
        host = [
            "//sw/device/lib/base:global_mock",
            "//sw/device/silicon_creator/testing:rom_test",
            "@googletest//:gtest",
        ],
        shared = [
            "//sw/device/lib/base:abs_mmio",
            "//sw/device/lib/base:hardened",
            "//sw/device/lib/base:macros",
            "//sw/device/silicon_creator/lib:error",
        ],
    ),
)

cc_test(
    name = "sec_mmio_unittest",
    srcs = ["sec_mmio_unittest.cc"],
    deps = [
        dual_cc_device_library_of(":sec_mmio"),
        "//sw/device/silicon_creator/testing:rom_test",
        "@googletest//:gtest_main",
    ],
)

cc_library(
    name = "static_critical_sec_mmio",
    srcs = ["static_critical_sec_mmio.c"],
    deps = [
        ":sec_mmio",
        "//sw/device/lib/base:macros",
    ],
    # This library provides a special symbol that the linker will find.
    # We want this to be a linker input to ensure the weak version in
    # sec_mmio.c is overriden.
    alwayslink = True,
)

cc_library(
    name = "boot_measurements",
    srcs = ["boot_measurements.c"],
    hdrs = ["boot_measurements.h"],
    deps = [
        "//sw/device/lib/base:macros",
        "//sw/device/silicon_creator/lib:keymgr_binding",
    ],
)

cc_library(
    name = "static_critical_epmp_state",
    srcs = ["static_critical_epmp_state.c"],
    deps = [
        "//sw/device/silicon_creator/lib:epmp_state",
    ],
    # This library provides a special symbol that the linker will find.
    # We want this to be a linker input to ensure the weak version in
    # epmp_state.c is overriden.
    alwayslink = True,
)

cc_library(
    name = "static_critical_boot_measurements",
    srcs = ["static_critical_boot_measurements.c"],
    deps = [
        ":boot_measurements",
    ],
    # This library provides a special symbol that the linker will find.
    # We want this to be a linker input to ensure the weak version in
    # boot_measurements.c is overriden.
    alwayslink = True,
)

cc_library(
    name = "static_critical_version",
    srcs = ["static_critical_version.c"],
    hdrs = ["static_critical_version.h"],
    deps = [
        "//sw/device/lib/base:macros",
    ],
    # This library provides a special symbol that the linker will find.
    alwayslink = True,
)

ld_library(
    name = "static_critical_sections",
    includes = [
        "static_critical.ld",
    ],
)

cc_library(
    name = "static_critical",
    deps = [
        ":static_critical_boot_measurements",
        ":static_critical_epmp_state",
        ":static_critical_sec_mmio",
        ":static_critical_sections",
        ":static_critical_version",
    ],
)

cc_library(
    name = "static_dice_cdi_0",
    srcs = ["static_dice_cdi_0.c"],
    hdrs = ["static_dice_cdi_0.h"],
    deps = [
        "//sw/device/lib/base:macros",
        "//sw/device/silicon_creator/lib/drivers:hmac",
        "//sw/device/silicon_creator/lib/sigverify:ecdsa_p256_key",
    ],
    # This library provides a special symbol that the linker will find.
    alwayslink = True,
)

ld_library(
    name = "static_dice_sections",
    includes = [
        "static_dice.ld",
    ],
)

cc_library(
    name = "static_dice",
    deps = [
        ":static_dice_cdi_0",
    ],
)

cc_library(
    name = "chip",
    hdrs = ["chip.h"],
)

cc_library(
    name = "util",
    srcs = ["util.c"],
    hdrs = ["util.h"],
)
