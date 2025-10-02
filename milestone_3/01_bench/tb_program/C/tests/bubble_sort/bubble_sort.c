#include "my_printf.h"
#include <stdint.h>

#define CYCLE_LO_ADDR   ((volatile uint32_t*)0x80000000)
#define CYCLE_HI_ADDR   ((volatile uint32_t*)0x80000004)
#define TICK_CNT_ADDR   ((volatile uint32_t*)0x60000000)
#define HALT_ADDR       ((volatile uint32_t*)0x8FFFFFF0)
#define HALT_DATA       ((uint32_t)0x000000AA)

#define RESULT_ADDR     ((volatile int32_t*)0x00004000)


void poke32(volatile int32_t* addr, int32_t data){
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

// Bubble sort implementation
void bubbleSort(int32_t arr[], int n) {
    for (int i = 0; i < n - 1; i++) {
        for (int j = 0; j < n - i - 1; j++) {
            if (arr[j] > arr[j + 1]) {
                int32_t temp = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = temp;
            }
        }
    }
}

int main() {
    uint64_t start = barebones_clock();

    // Input array (25 values, includes negatives)
    int32_t arr[25] = {
        64, -34, 25, -12, 22, 11, 90, 1000, -500, 250,
        -2147483648, 2147483647, -77, 123, 999, 0, 65535, -42, 31415, 2718,
        8888, 42, -73, 19, -2048
    };
    int n = sizeof(arr) / sizeof(arr[0]);

    // Copy original array
    int32_t orig[25];
    for (int i = 0; i < n; i++) orig[i] = arr[i];

    // Sort
    bubbleSort(arr, n);

    // Print header
    ee_printf("\nOriginal\t\t|vs|\t\tSorted values:");

    // Print each pair row by row
    for (int i = 0; i < n; i++) {
        ee_printf("\nOriginal: %0d\t\t|\t\tSorted: %0d", orig[i], arr[i]);
    }

    // Store sorted array sequentially in memory
    for (int i = 0; i < n; i++) {
        poke32(RESULT_ADDR + i, arr[i]);
    }

    uint64_t end   = barebones_clock();
    uint64_t ticks = (uint32_t)(end - start);
    poke32(TICK_CNT_ADDR, (uint32_t)(ticks));

    ee_printf("\nSorting finished in %d cycles", (uint32_t)ticks);

    core_halt();
    return 0;
}
