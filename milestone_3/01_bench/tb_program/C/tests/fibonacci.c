#include <stdint.h>
#include <limits.h>
#include "my_printf.h"

#define CYCLE_LO_ADDR   ((volatile uint32_t*)0x80000000)
#define CYCLE_HI_ADDR   ((volatile uint32_t*)0x80000004)
#define TICK_CNT_ADDR   ((volatile uint32_t*)0x60000000)
#define HALT_ADDR       ((volatile uint32_t*)0x8FFFFFF0)
#define HALT_DATA       ((uint32_t)0x000000AA)

#define RESULT_ADDR     ((volatile uint32_t*)0x00004000)

static inline void poke32(volatile uint32_t* addr, uint32_t data){ *addr = data; }
static inline void core_halt(void){ poke32(HALT_ADDR, HALT_DATA); }

static inline uint64_t barebones_clock(void) {
    uint32_t hi1, lo, hi2;
    do {
        hi1 = *CYCLE_HI_ADDR;
        lo  = *CYCLE_LO_ADDR;
        hi2 = *CYCLE_HI_ADDR;
    } while (hi1 != hi2);
    return ((uint64_t)hi2 << 32) | lo;
}

int main(void) {
    // Optional timing (uncomment if you want cycles)
    // uint64_t start = barebones_clock();

    int32_t a = 0;   // F(0)
    int32_t b = 1;   // F(1)

    // Print the first two terms
    ee_printf("\nF[%d] = %d", 0, a);
    ee_printf("\nF[%d] = %d", 1, b);

    int last_idx = 1;        // last printed index
    int32_t last_val = b;    // last printed value

    // Generate and print until the next value would overflow int32_t
    for (int idx = 2; ; ++idx) {
        // Use 64-bit temp to detect overflow before assigning to int32_t
        int64_t next64 = (int64_t)a + (int64_t)b;
        if (next64 > INT32_MAX) break;

        int32_t next = (int32_t)next64;
        ee_printf("\nF[%d] = %d", idx, next);

        // advance
        a = b;
        b = next;

        last_idx = idx;
        last_val = next;
    }

    // Expose results via MMIO
    poke32(RESULT_ADDR, (uint32_t)last_val);  // final valid Fibonacci value
    poke32(TICK_CNT_ADDR, (uint32_t)last_idx); // final valid index (should be 46)

    // Optional timing
    // uint64_t end   = barebones_clock();
    // uint64_t ticks = end - start;
    // poke32(TICK_CNT_ADDR, (uint32_t)(ticks));

    ee_printf("\n\nMax 32-bit signed reached at index = %d, value = %d", last_idx, last_val);

    core_halt();
    return 0;
}
