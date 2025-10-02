/* test_ee_printf.c
   Purpose: Verify ee_printf() supports zero-padded hex formats (e.g., %04x)
            and print a small list of random numbers; then halt the core.

   Build (bare metal):
     riscv32-unknown-elf-gcc -O2 -ffreestanding -nostdlib -nostartfiles \
       -DBARE_METAL test_ee_printf.c -o test_ee_printf.elf

   Notes:
   - Uses '\n' newlines only (no CR).
   - Requires your my_printf.h to provide: int ee_printf(const char*, ...);
*/

#include <stdint.h>


#if defined(HOST_TEST)
/* Optional host-side sanity check:
   gcc -O2 -DHOST_TEST test_ee_printf.c -o host && ./host
*/
  #include <stdio.h>
  #include <stdarg.h>
  static int ee_printf(const char *fmt, ...) {
    va_list ap; va_start(ap, fmt);
    int n = vprintf(fmt, ap);
    va_end(ap);
    return n;
  }
#else
  #include "my_printf.h"   /* your UART printf: int ee_printf(const char*, ...); */
#endif

/* --- MMIO + halt (match your platform) --- */
#define HALT_ADDR  ((volatile uint32_t*)0x8FFFFFF0u)
#define HALT_DATA  ((uint32_t)0x000000AAu)

static inline void poke32(volatile uint32_t* addr, uint32_t data) { *addr = data; }
static inline void core_halt(void) { poke32(HALT_ADDR, HALT_DATA); }

/* --- Tiny LCG PRNG: deterministic, no libc needed --- */
static uint32_t lcg_next(uint32_t *state) {
  /* Numerical Recipes LCG */
  *state = (*state) * 1664525u + 1013904223u;
  return *state;
}

/* --- Demo prints to exercise padding/hex formats --- */
static void print_padding_demo(void) {
    ee_printf("Padding demo:\n");
    /* Exact values to verify zero-fill behavior */
    ee_printf("  %%04x: %04x \n", 0u);
    ee_printf("  %%04x: %04x \n", 1u);
    core_halt();
  ee_printf("  %%04x: %04x \n", 0xABu);
  ee_printf("  %%04x: %04x \n", 0x1234u);
  ee_printf("  %%08x: %08x \n", 0u);
  ee_printf("  %%08x: %08x \n", 0x1u);
  ee_printf("  %%08x: %08x \n", 0xABCDu);
  ee_printf("  %%08x: %08x \n", 0x89ABCDEFu);
  ee_printf("  mix: idx = %02u | val = %04x | wide=%08x\n", 7u, 0x3F2u, 0x00AA55CCu);
}

/* --- Print a short list of random numbers in several hex widths --- */
static void print_random_list(uint32_t seed, int count) {
  ee_printf("Random list (seed = 0x%08x, count = %d):\n", seed, count);
  uint32_t s = seed;
  for (int i = 0; i < count; i++) {
    uint32_t v = lcg_next(&s);
    /* show multiple format widths to verify padding */
    ee_printf("[%02u] v = %08x  |  low16 = %04x  |  low8 = %02x\n",
              (unsigned)i, v, (unsigned)(v & 0xFFFFu), (unsigned)(v & 0xFFu));
  }
}

int main(void) {
  /* 1) Show zero-padding behavior explicitly */
  print_padding_demo();

  /* 2) Print a small random list (tweak count as you like) */
  print_random_list(0x1234ABCDu, 16);

  ee_printf("Done. Halting now.\n");
  /* If core ignores HALT, just spin */
  for (;;);
  return 0;
}
