#include <stdint.h>
#define BARE_METAL 1

#ifdef BARE_METAL
    #include "my_printf.h"
    #define print ee_printf

    // MMIO addresses (your setup)
    #define CYCLE_LO_ADDR   ((volatile uint32_t*)0x80000000)
    #define CYCLE_HI_ADDR   ((volatile uint32_t*)0x80000004)
    #define TICK_CNT_ADDR   ((volatile uint32_t*)0x60000000)
    #define HALT_ADDR       ((volatile uint32_t*)0x8FFFFFF0)
    #define HALT_DATA       ((uint32_t)0x000000AA)
    #define RESULT_ADDR     ((volatile int32_t*)0x00004000)

    static inline void poke32(volatile int32_t* addr, int32_t data){ *addr = data; }
    static inline void core_halt(void){ *(volatile uint32_t*)HALT_ADDR = HALT_DATA; }
    static inline uint64_t read_cycles(void){
      uint32_t hi1, lo, hi2;
      do { hi1 = *CYCLE_HI_ADDR; lo = *CYCLE_LO_ADDR; hi2 = *CYCLE_HI_ADDR; } while (hi1 != hi2);
      return ((uint64_t)hi2 << 32) | lo;
    }
#else
#include <stdio.h>
    #define print printf

    // Simple stubs so the same code runs on PC
    static uint32_t fake_mem[1<<12];
    #define RESULT_ADDR     ((volatile int32_t*)&fake_mem[16])
    #define TICK_CNT_ADDR   (&fake_mem[2])
    static inline void poke32(volatile int32_t* addr, int32_t data){ *addr = data; }
    static inline void core_halt(void){ (void)0; }
    static inline uint64_t read_cycles(void){ return 0; }
#endif

/* --------------------------
   Build-time options (simple)
   -------------------------- */

// Choose one case from the table (0..NCASES-1)
#ifndef CASE_ID
  #define CASE_ID 2
#endif

// Set to 1 to print A and B before computing
#ifndef PRINT_INPUTS
  #define PRINT_INPUTS 1
#endif

// Set to 1 to print C after computing
#ifndef PRINT_OUTPUT
  #define PRINT_OUTPUT 1
#endif

/* --------------------------
   Size table
   Each row is {R, K, C}
   -------------------------- */
typedef struct {
  int R;
  int K;
  int C;
} mm_case_t;

static const mm_case_t CASES[] = {
  { 4,  4,  4},
  { 8,  8,  8},
  {16, 16, 16},
  {32, 32, 32},
};
#define NCASES ((int)(sizeof(CASES)/sizeof(CASES[0])))

/* --------------------------
   Small, clear helper code
   -------------------------- */

// Fill A and B with small integers so results are stable and not too big
static void fill_A(int32_t* A, int R, int K){
  for (int r = 0; r < R; ++r){
    for (int k = 0; k < K; ++k){
      A[r*K + k] = (int32_t)(r - k);
    }
  }
}

static void fill_B(int32_t* B, int K, int C){
  for (int k = 0; k < K; ++k){
    for (int c = 0; c < C; ++c){
      B[k*C + c] = (int32_t)(k + c);
    }
  }
}


// Plain triple-loop matmul: C = A * B
static void matmul(const int32_t* A, const int32_t* B, int32_t* C, int R, int K, int Cc){
  for (int r = 0; r < R; ++r){
    for (int c = 0; c < Cc; ++c){
      int64_t sum = 0; // 64-bit to be safe
      for (int k = 0; k < K; ++k){
        sum += (int64_t)A[r*K + k] * (int64_t)B[k*Cc + c];
      }
      C[r*Cc + c] = (int32_t)sum; // store low 32 bits
    }
  }
}

// Simple matrix printer
static void print_matrix(const char* title, const int32_t* M, int rows, int cols, int stride){
  print("\n%s", title);
  for (int r = 0; r < rows; ++r){
    print("\n");
    for (int c = 0; c < cols; ++c){
      print("%d", M[r*stride + c]);
      if (c < cols - 1) print("\t");
    }
  }
  print("\n");
}

// Simple checksum so you can compare results quickly
static uint32_t checksum(const int32_t* M, int rows, int cols, int stride){
  uint32_t s = 0;
  for (int r = 0; r < rows; ++r){
    for (int c = 0; c < cols; ++c){
      s = s ^ (uint32_t)M[r*stride + c];   // xor
      s = s * 2654435761u;                 // mix a bit
    }
  }
  return s;
}

/* --------------------------
   Main
   -------------------------- */
int main(void){
  if (CASE_ID < 0 || CASE_ID >= NCASES){
    print("\nInvalid CASE_ID=%d (valid 0..%d).", CASE_ID, NCASES-1);
    core_halt(); return 0;
  }

  const mm_case_t cfg = CASES[CASE_ID];
  const int R  = cfg.R;
  const int K  = cfg.K;
  const int Cc = cfg.C;

  // Static buffers so we do not use stack too much
  static int32_t A[32*32];
  static int32_t B[32*32];
  static int32_t C[32*32];

  // Quick bounds check (so beginners do not get memory bugs silently)
  if (R*K > 32*32 || K*Cc > 32*32 || R*Cc > 32*32){
    print("\nSelected size is too big for the built-in buffers.");
    print("\nPick a smaller CASE_ID or increase the buffer sizes.");
    core_halt();
    return 0;
  }

  // 1) Build inputs
  fill_A(A, R, K);
  fill_B(B, K, Cc);

  // 2) Print inputs first (as you asked)
#if PRINT_INPUTS
  print("\n[INPUTS] A is %dx%d, B is %dx%d", R, K, K, Cc);
  print_matrix("Matrix A:", A, R, K, K);
  print_matrix("Matrix B:", B, K, Cc, Cc);
#endif

  // 3) Compute and time
  uint64_t t0 = read_cycles();
  matmul(A, B, C, R, K, Cc);
  uint64_t t1 = read_cycles();
  uint32_t ticks = (uint32_t)(t1 - t0);

  // 4) Optional: print output
#if PRINT_OUTPUT
  print_matrix("Matrix C = A * B:", C, R, Cc, Cc);
#endif

  // 5) Show a simple checksum so you can compare across runs/cores
  uint32_t sig = checksum(C, R, Cc, Cc);
  print("\nCASE_ID=%d  size %dx%d * %dx%d  ticks=%u  checksum=0x%08X",
        CASE_ID, R, K, K, Cc, ticks, sig);

  // 6) Store a small header to RESULT_ADDR for your testbench:
  // RESULT_ADDR[0]=R, [1]=K, [2]=C, [3]=checksum
  poke32(RESULT_ADDR + 0, R);
  poke32(RESULT_ADDR + 1, K);
  poke32(RESULT_ADDR + 2, Cc);
  poke32(RESULT_ADDR + 3, (int32_t)sig);
  *(volatile uint32_t*)TICK_CNT_ADDR = ticks;

#ifndef BARE_METAL
  print("\n[HOST] dims=(%d,%d,%d) checksum=0x%08X\n",
        (int)*(RESULT_ADDR+0), (int)*(RESULT_ADDR+1),
        (int)*(RESULT_ADDR+2), (uint32_t)*(RESULT_ADDR+3));
#endif

  core_halt();
  return 0;
}
