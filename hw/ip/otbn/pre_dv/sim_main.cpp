#include <cstdint>
#include <cstdio>
#include <queue>
#include <random>

#include "Votbn_sec_add.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

static constexpr int TOT_STIMS = 1'000'000;
static constexpr int RST_HALF_CLK = 20;  // 10 full clock cycles

// result_o is [1:0][32:0] = 66 bits → Verilator WData[3].
// Packed layout: share0[32:0] in bits [32:0], share1[32:0] in bits [65:33].
// WData[0] = bits[31:0],  WData[1] = bits[63:32],  WData[2] = bits[65:64].
static uint64_t result_share(const uint32_t *r, int share) {
  if (share == 0)
    // share0[31:0] = WData[0], share0[32] = WData[1] bit 0
    return (uint64_t)r[0] | ((uint64_t)(r[1] & 1u) << 32);
  else
    // share1[30:0] = WData[1][31:1], share1[31] = WData[2] bit 0, share1[32] =
    // WData[2] bit 1
    return (uint64_t)(r[1] >> 1) | ((uint64_t)(r[2] & 3u) << 31);
}

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);

  Votbn_sec_add *const dut = new Votbn_sec_add;
  VerilatedVcdC *const vcd = new VerilatedVcdC;
  dut->trace(vcd, 99);
  vcd->open("dump.vcd");

  // inp1_i / inp2_i are [1:0][31:0] = 64 bits → QData (uint64_t).
  // rand_i is [321:0] = 322 bits → WData[11].
  static constexpr int RAND_WORDS = 11;

  std::mt19937 rng(42);
  std::uniform_int_distribution<uint32_t> dist;

  std::queue<uint64_t> exp_queue;
  int n_stims = 0, n_checks = 0, n_errs = 0;
  vluint64_t t = 0;

  dut->clk_i = 0;
  dut->rst_ni = 0;
  dut->valid_i = 0;
  dut->stall_i = 0;
  dut->inp1_i = 0;
  dut->inp2_i = 0;
  for (int i = 0; i < RAND_WORDS; i++)
    dut->rand_i[i] = 0;
  dut->eval();

  while (n_checks < TOT_STIMS) {
    dut->clk_i = !dut->clk_i;
    if (t == (vluint64_t)RST_HALF_CLK)
      dut->rst_ni = 1;

    if (dut->clk_i && dut->rst_ni) {
      // Drive stimulus and push golden for what the DUT will capture this edge.
      if (n_stims < TOT_STIMS) {
        const uint32_t inp1 = dist(rng), inp2 = dist(rng);
        const uint32_t b0 = dist(rng), b1 = dist(rng);
        dut->inp1_i = ((uint64_t)inp2 << 32) | inp1;
        dut->inp2_i = ((uint64_t)b1 << 32) | b0;
        dut->valid_i = 1;
        for (int i = 0; i < RAND_WORDS; i++)
          dut->rand_i[i] = dist(rng);
        exp_queue.push((uint64_t)(inp1 ^ inp2) + (uint64_t)(b0 ^ b1));
        n_stims++;
      } else {
        dut->valid_i = 0;
      }
    }

    dut->eval();

    if (dut->clk_i && dut->rst_ni && dut->valid_o && !exp_queue.empty()) {
      const uint64_t s0 = result_share(dut->result_o, 0);
      const uint64_t s1 = result_share(dut->result_o, 1);
      const uint64_t got = (s0 ^ s1) & 0x1FFFFFFFFull;
      const uint64_t exp = exp_queue.front() & 0x1FFFFFFFFull;
      exp_queue.pop();
      n_checks++;
      if (got != exp) {
        n_errs++;
        printf(
            "[FAIL] t=%-8llu | exp=%09llx got=%09llx (s0=%09llx s1=%09llx)\n",
            (unsigned long long)t, (unsigned long long)exp,
            (unsigned long long)got, (unsigned long long)s0,
            (unsigned long long)s1);
      }
    }

    vcd->dump(t);
    Verilated::timeInc(1);
    t++;
  }

  printf(
      n_errs ? "Test ***FAILED*** %d / %d\n" : "Test ***PASSED*** %d checks\n",
      n_errs ? n_errs : n_checks, n_checks);

  dut->final();
  vcd->close();
  delete vcd;
  delete dut;
  return n_errs ? 1 : 0;
}
