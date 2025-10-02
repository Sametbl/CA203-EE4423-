// factorial_print_portable.c
#include <stdint.h>
#include <limits.h>

#ifdef BARE_METAL
  #include "my_printf.h"
  #define ee_print  ee_printf
  #define MMIO32(a) ((volatile uint32_t*)(uintptr_t)(a))

  #define CYCLE_LO_ADDR   MMIO32(0x80000000)
  #define CYCLE_HI_ADDR   MMIO32(0x80000004)
  #define TICK_CNT_ADDR   MMIO32(0x60000000)
  #define HALT_ADDR       MMIO32(0x8FFFFFF0)
  #define HALT_DATA       ((uint32_t)0x000000AA)
  #define RESULT_ADDR     MMIO32(0x00004000)

  static inline void poke32(volatile uint32_t* addr, uint32_t data){ *addr = data; }
  static inline void core_halt(void){ poke32(HALT_ADDR, HALT_DATA); }
  static inline uint64_t barebones_clock(void) {
      uint32_t hi1, lo, hi2;
      do { hi1 = *CYCLE_HI_ADDR; lo = *CYCLE_LO_ADDR; hi2 = *CYCLE_HI_ADDR; } while (hi1 != hi2);
      return ((uint64_t)hi2 << 32) | lo;
  }
#else
  #include <stdio.h>
  #define ee_print  printf
  static uint32_t fake_mem[8];
  #define CYCLE_LO_ADDR   (&fake_mem[0])
  #define CYCLE_HI_ADDR   (&fake_mem[1])
  #define TICK_CNT_ADDR   (&fake_mem[2])
  #define HALT_ADDR       (&fake_mem[3])
  #define RESULT_ADDR     (&fake_mem[4])
  #define HALT_DATA       ((uint32_t)0x000000AA)

  static inline void poke32(volatile uint32_t* addr, uint32_t data){ *addr = data; }
  static inline void core_halt(void){ (void)0; }
  static inline uint64_t barebones_clock(void){ return 0; }
#endif

int main(void) {
    // Optional timing on hardware:
    // uint64_t start = barebones_clock();

    // We’ll accumulate factorial in 32-bit, but use 64-bit to check overflow before updating.
    uint32_t fact = 1u;  // 0! = 1
    unsigned n = 0;

    ee_print("\n%u! = %u", n, fact);  // print 0!

    // Keep multiplying while the next value fits in 32-bit (signed or unsigned). 12! fits, 13! overflows 32-bit.
    while (1) {
        unsigned next_n = n + 1;
        uint64_t next64 = (uint64_t)fact * (uint64_t)next_n;  // overflow-safe check

        if (next64 > (uint64_t)UINT32_MAX) {
            // Stop before overflow; n!, fact are the last valid 32-bit values.
            break;
        }

        fact = (uint32_t)next64;
        n = next_n;
        ee_print("\n%u! = %u", n, fact);
    }

    // Expose results via MMIO (or host stubs):
    // - RESULT_ADDR: last factorial value that fits in 32-bit (should be 12! = 479001600)
    // - TICK_CNT_ADDR: corresponding n (should be 12)
    poke32(RESULT_ADDR, fact);
    poke32(TICK_CNT_ADDR, n);

    ee_print("\n\nMax 32-bit factorial is %u! = %u", n, fact);

    // Optional timing:
    // uint64_t end = barebones_clock();
    // poke32(TICK_CNT_ADDR, (uint32_t)(end - start));

    core_halt();
#ifndef BAREMETAL
    ee_print("\n[HOST] RESULT_ADDR=0x%08X, N=%u\n", *RESULT_ADDR, *TICK_CNT_ADDR);
#endif
    return 0;
}
