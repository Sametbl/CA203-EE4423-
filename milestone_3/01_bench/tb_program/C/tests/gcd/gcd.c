#include "my_printf.h"

#define CYCLE_LO_ADDR   ((volatile uint32_t*)0x80000000)
#define CYCLE_HI_ADDR   ((volatile uint32_t*)0x80000004)
#define TICK_CNT_ADDR   ((volatile uint32_t*)0x60000000)
#define HALT_ADDR       ((volatile uint32_t*)0x8FFFFFF0)
#define HALT_DATA       ((uint32_t)0x000000AA)

#define RESULT_ADDR     ((volatile uint32_t*)0x00004000)


void poke32(volatile uint32_t* addr, uint32_t data){
    *addr = data; 
}

void core_halt(void){
    poke32(HALT_ADDR, HALT_DATA);
}

uint64_t barebones_clock(void) {
    uint32_t hi1, lo, hi2;
    do {
        hi1 = *CYCLE_HI_ADDR;
        lo  = *CYCLE_LO_ADDR;
        hi2 = *CYCLE_HI_ADDR;
    } while (hi1 != hi2);
    return ((uint64_t)hi2 << 32) | lo;
}

int32_t gcd(int32_t a, int32_t b) {
    if (a < 0) a = -a;
    if (b < 0) b = -b;

    while (b != 0) {
        int32_t temp = b;
        b = a % b;
        a = temp;
    }
    return a;
}

int main() {
    uint64_t start = barebones_clock();

    // Example inputs (20 pairs for wide range testing)
    uint32_t inputs[20][2] = {
        {12, 18}, {48, 18}, {56, 98}, {101, 103}, {270, 192},
        {81, 153}, {100, 250}, {4294967295u, 4294967290u}, // big numbers
        {144, 60}, {391, 299}, {252, 105}, {1000, 10}, {37, 600},
        {462, 1071}, {120, 84}, {2025, 405}, {65535, 255}, {5000, 123},
        {777, 999}, {99991, 12345}
    };

    for (int i = 0; i < 20; i++) {
        uint32_t a = inputs[i][0];
        uint32_t b = inputs[i][1];
        uint32_t result = gcd(a, b);

        // Print to UART
        ee_printf("\nGCD(%0d, %0d)\t\t= %0d", a, b, result);

        // Optionally store last result in memory (overwrites each time)
        poke32(RESULT_ADDR, result);
    }

    uint64_t end   = barebones_clock();
    uint64_t ticks = (uint32_t)(end - start);
    poke32(TICK_CNT_ADDR, (uint32_t)(ticks));

    core_halt();
    return 0;
}
