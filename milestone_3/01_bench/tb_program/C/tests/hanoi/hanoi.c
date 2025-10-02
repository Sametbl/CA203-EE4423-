#include "my_printf.h"

#define CYCLE_LO_ADDR   ((volatile uint32_t*)0x80000000)
#define CYCLE_HI_ADDR   ((volatile uint32_t*)0x80000004)
#define TICK_CNT_ADDR   ((volatile uint32_t*)0x60000000)
#define HALT_ADDR       ((volatile uint32_t*)0x8FFFFFF0)
#define HALT_DATA       ((uint32_t)0x000000AA)

#define RESULT_ADDR     ((volatile uint32_t*)0x00004000)
#define NUM_DISKS       (4)   // number of disks


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

// Recursive Tower of Hanoi function
void towerOfHanoi(int n, char from_rod, char to_rod, char aux_rod) {
    if (n == 1) {
        ee_printf("\nMove disk 1 from rod %c to rod %c", from_rod, to_rod);
        return;
    }
    towerOfHanoi(n - 1, from_rod, aux_rod, to_rod);
    ee_printf("\nMove disk %d from rod %c to rod %c", n, from_rod, to_rod);
    towerOfHanoi(n - 1, aux_rod, to_rod, from_rod);
}

int main() {
    uint64_t start = barebones_clock();

    // Run Tower of Hanoi
    towerOfHanoi(NUM_DISKS, 'A', 'C', 'B');

    uint64_t end   = barebones_clock();
    uint64_t ticks = (uint32_t)(end - start);
    poke32(TICK_CNT_ADDR, (uint32_t)(ticks));

    // store the number of moves = 2^n - 1
    uint32_t moves = (1u << NUM_DISKS) - 1;
    poke32(RESULT_ADDR, moves);

    ee_printf("\nNumber of moves for %0d disks = %0d", NUM_DISKS, moves);

    core_halt();
    return 0;
}
