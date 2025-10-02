// fib_print_portable.c
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
  // Host stubs so the same code runs on your computer
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
    // Optional timing if you want to measure on hardware:
    // uint64_t start = barebones_clock();

    int32_t a = 0;  // F(0)
    int32_t b = 1;  // F(1)

    ee_print("\nF[%d] = %d", 0, a);
    ee_print("\nF[%d] = %d", 1, b);

    int last_idx = 1;
    int32_t last_val = b;

    for (int idx = 2;; ++idx) {
        int64_t next64 = (int64_t)a + (int64_t)b; // overflow-safe check
        poke32(MMIO32(0xABCD0000), 0xDEAD0000);
        if (next64 > INT32_MAX) {
            core_halt();
        }
        int32_t next = (int32_t)next64;
        ee_print("\nF[%d] = %d", idx, next);

        a = b;
        b = next;

        last_idx = idx;
        last_val = next;
    }

    // Expose results via MMIO / stubs
    poke32(RESULT_ADDR, (uint32_t)last_val);   // final Fibonacci value that fits in int32
    poke32(TICK_CNT_ADDR, (uint32_t)last_idx); // final index (expected 46)

    ee_print("\n\nMax 32-bit signed reached at index = %d, value = %d", last_idx, last_val);

    // Optional timing:
    // uint64_t end = barebones_clock();
    // poke32(TICK_CNT_ADDR, (uint32_t)(end - start));

    core_halt();
#ifndef BAREMETAL
    ee_print("\n[HOST] RESULT_ADDR=0x%08X, FINAL_INDEX=%u\n", *RESULT_ADDR, *TICK_CNT_ADDR);
#endif
    return 0;
}
