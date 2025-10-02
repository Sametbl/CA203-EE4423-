#include <stdint.h>

#ifdef BARE_METAL
    #include "my_printf.h"
    #define print ee_printf

    // MMIO registers
    #define CYCLE_LO_ADDR   ((volatile uint32_t*)0x80000000)
    #define CYCLE_HI_ADDR   ((volatile uint32_t*)0x80000004)
    #define TICK_CNT_ADDR   ((volatile uint32_t*)0x60000000)
    #define HALT_ADDR       ((volatile uint32_t*)0x8FFFFFF0)
    #define HALT_DATA       ((uint32_t)0x000000AA)

    // Write 32-bit value to MMIO
    static inline void poke32(volatile uint32_t* addr, uint32_t data) {
        *addr = data;
    }

    // Halt the CPU
    static inline void core_halt(void) {
        poke32(HALT_ADDR, HALT_DATA);
    }

    // Read 64-bit clock cycle counter
    static inline uint64_t barebones_clock(void) {
        uint32_t hi1, lo, hi2;
        do {
            hi1 = *CYCLE_HI_ADDR;
            lo  = *CYCLE_LO_ADDR;
            hi2 = *CYCLE_HI_ADDR;
        } while (hi1 != hi2);
        return ((uint64_t)hi2 << 32) | lo;
    }
#else
    #include <stdio.h>
    #define print printf

    // Stubs for host PC
    static inline void poke32(volatile uint32_t* addr, uint32_t data) {
        (void)addr; (void)data;
    }
    static inline void core_halt(void) {
        // Do nothing on PC
    }
    static inline uint64_t barebones_clock(void) {
        return 0; // No cycle counter on PC
    }
    #define TICK_CNT_ADDR ((volatile uint32_t*)0)
#endif

int main(void) {
    // Start counting cycles
    uint64_t start = barebones_clock();

    // Top banner line
    print("#######################################################\n");
    print(" M.A.R.S group - DOELAB-203 HCMUT\n");
    print("#######################################################\n");

    // ASCII Art Logo
    print(" /OO      /OO      /OOOOOO      /OOOOOOO       /OOOOOO \n");
    print("| OOO    /OOO     /OO__  OO    | OO__  OO     /OO__  OO\n");
    print("| OOOO  /OOOO    | OO  \\ OO    | OO  \\ OO    | OO  \\__/\n");
    print("| OO OO/OO OO    | OOOOOOOO    | OOOOOOO/    |  OOOOOO \n");
    print("| OO  OOO| OO    | OO__ /OO    | OO__ /OO     /___  OO\n");
    print("| OO\\  O | OO    | OO  | OO    | OO  \\ OO     /OO  \\ OO\n");
    print("| OO \\/  | OO /OO| OO  | OO /OO| OO  | OO /OO|  OOOOOO/\n");
    print("|_/      |_/|__/|_/   |_/|__/|_/   |_/|__/ \\_____/ \n");

    // Bottom line
    print("#######################################################\n");

    // End counting cycles
    uint64_t end = barebones_clock();
    uint32_t ticks = (uint32_t)(end - start);

    // Store ticks to MMIO (bare-metal only)
#ifdef BARE_METAL
    poke32(TICK_CNT_ADDR, ticks);
    print("\n[INFO] Banner printed in %u cycles.\n", ticks);
#else
    print("\n[INFO] Banner printed successfully (ticks not measured on PC).\n");
#endif

    // Halt the core on bare-metal
    core_halt();

    return 0;
}
