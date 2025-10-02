#include "my_printf.h"
#include <stdint.h>

/* ------------------ MMIO ------------------ */
#define CYCLE_LO_ADDR   ((volatile uint32_t*)0x80000000)
#define CYCLE_HI_ADDR   ((volatile uint32_t*)0x80000004)
#define TICK_CNT_ADDR   ((volatile uint32_t*)0x60000000)
#define HALT_ADDR       ((volatile uint32_t*)0x8FFFFFF0)
#define HALT_DATA       ((uint32_t)0x000000AA)

/* RESULT LAYOUT:
 * [0]  = N (array length)
 * [1]  = CRC32 (over int32 words)
 * [2]  = SUM32 (sum of elements, 32-bit)
 * [3]  = GCD of |elements|
 * [4..] sorted array values (N words)
 */
#define RESULT_ADDR     ((volatile uint32_t*)0x00004000)

/* ------------------ Utils ------------------ */
static inline void poke32(volatile uint32_t* addr, uint32_t data){ *addr = data; }
static inline void core_halt(void){ poke32(HALT_ADDR, HALT_DATA); }

static uint64_t barebones_clock(void) {
    uint32_t hi1, lo, hi2;
    do { hi1 = *CYCLE_HI_ADDR; lo = *CYCLE_LO_ADDR; hi2 = *CYCLE_HI_ADDR; } while (hi1 != hi2);
    return ((uint64_t)hi2 << 32) | lo;
}

/* ------------------ Random (LCG) ------------------
 * x(n+1) = a*x + c (mod 2^32)
 * Produces full 32-bit patterns; we cast to int32_t to include negatives.
 */
static uint32_t lcg_next(uint32_t *state) {
    const uint32_t A = 1664525u;
    const uint32_t C = 1013904223u;
    *state = (*state * A) + C;
    return *state;
}

/* ------------------ GCD (handles negatives) ------------------ */
static int32_t iabs32(int32_t x){ return (x < 0) ? -x : x; }

static int32_t gcd32(int32_t a, int32_t b) {
    a = iabs32(a); b = iabs32(b);
    while (b != 0) {
        int32_t t = b;
        b = a % b;
        a = t;
    }
    return a;
}

/* ------------------ CRC32 (word-wise) ------------------
 * Standard poly 0xEDB88320, initial ~0, final ~crc.
 * Feeds the 4 bytes of each int32_t in little-endian order.
 */
static uint32_t crc32_words(const int32_t *data, int n) {
    uint32_t crc = 0xFFFFFFFFu;
    for (int i = 0; i < n; i++) {
        uint32_t w = (uint32_t)data[i];
        for (int b = 0; b < 4; b++) {
            uint8_t byte = (uint8_t)(w & 0xFFu);
            crc ^= byte;
            for (int k = 0; k < 8; k++) {
                uint32_t mask = -(crc & 1u);
                crc = (crc >> 1) ^ (0xEDB88320u & mask);
            }
            w >>= 8;
        }
    }
    return ~crc;
}

/* ------------------ Quicksort ------------------ */
static void swap32(int32_t *a, int32_t *b){ int32_t t = *a; *a = *b; *b = t; }

static int partition(int32_t *arr, int lo, int hi) {
    int32_t pivot = arr[hi];
    int i = lo - 1;
    for (int j = lo; j < hi; j++) {
        if (arr[j] <= pivot) { i++; swap32(&arr[i], &arr[j]); }
    }
    swap32(&arr[i+1], &arr[hi]);
    return i + 1;
}

static void quicksort(int32_t *arr, int lo, int hi) {
    if (lo >= hi) return;
    int p = partition(arr, lo, hi);
    quicksort(arr, lo, p - 1);
    quicksort(arr, p + 1, hi);
}

/* ------------------ Binary search ------------------ */
static int bsearch32(const int32_t *arr, int n, int32_t key) {
    int L = 0, R = n - 1;
    while (L <= R) {
        int M = L + ((R - L) >> 1);
        int32_t v = arr[M];
        if (v == key) return M;
        if (v < key) L = M + 1; else R = M - 1;
    }
    return -1;
}

/* ------------------ Main battery ------------------ */
int main(void) {
    /* Size is big enough to stress caches/memory but not spam UART */
    enum { N = 128 };
    int32_t arr[N];
    int32_t orig[N];

    /* Fill with pseudo-random signed ints */
    uint32_t rng = 0xDEADBEEFu;
    for (int i = 0; i < N; i++) {
        uint32_t r = lcg_next(&rng);
        arr[i]  = (int32_t)r;
        orig[i] = arr[i];
    }

    uint64_t start = barebones_clock();

    /* Sort (quicksort) */
    quicksort(arr, 0, N - 1);

    /* Verify sorted and compute summary stats */
    int sorted_ok = 1;
    for (int i = 1; i < N; i++) if (arr[i-1] > arr[i]) { sorted_ok = 0; break; }

    /* Sum32 and GCD of absolute values */
    int32_t sum32 = 0;
    int32_t g = iabs32(arr[0]);
    for (int i = 0; i < N; i++) {
        sum32 += arr[i];
        g = gcd32(g, arr[i]);
    }

    /* CRC32 of the (sorted) array */
    uint32_t crc = crc32_words(arr, N);

    /* A few binary searches (some hits, some misses) */
    int32_t keys[10] = {
        arr[0], arr[N/2], arr[N-1], 12345, -1, 0, 777, -777, 0x7FFFFFFF, (int32_t)0x80000000u
    };
    int hits = 0;
    for (int i = 0; i < 10; i++) {
        int idx = bsearch32(arr, N, keys[i]);
        ee_printf("\nBS key %d -> idx %d", keys[i], idx);
        if (idx >= 0) hits++;
    }

    /* Extra DIV/REM stress: reduce all elements mod a prime and sum */
    int32_t modsum = 0;
    const int32_t P = 1009; /* small prime */
    for (int i = 0; i < N; i++) {
        int32_t v = arr[i] % P;  /* exercises DIV/REM on signed */
        if (v < 0) v += P;
        modsum += v;
    }

    uint64_t end = barebones_clock();
    uint32_t ticks = (uint32_t)(end - start);
    poke32(TICK_CNT_ADDR, ticks);

    /* Write results to memory */
    poke32(RESULT_ADDR + 0, (uint32_t)N);
    poke32(RESULT_ADDR + 1, crc);
    poke32(RESULT_ADDR + 2, (uint32_t)sum32);
    poke32(RESULT_ADDR + 3, (uint32_t)g);
    for (int i = 0; i < N; i++) poke32(RESULT_ADDR + 4 + i, (uint32_t)arr[i]);

    /* UART summary (kept short) */
    ee_printf("\nRV32IM Complex Test");
    ee_printf("\nN=%d sorted_ok=%d hits=%d", N, sorted_ok, hits);
    ee_printf("\nSUM32=%d  GCD=%d  CRC32=0x%x  MODSUM=%d", sum32, g, crc, modsum);
    ee_printf("\nCycles=%u\n", ticks);

    core_halt();
    return 0;
}
