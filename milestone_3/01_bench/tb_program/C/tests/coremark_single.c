
/*
 * CoreMark (single-file amalgamation)
 * Source combined from user's files: core_list_join.c, core_main.c, core_matrix.c,
 * core_state.c, core_util.c, coremark.h, core_portme.h, core_portme.c,
 * ee_printf.c, cvt.c
 *
 * Keep CORE_DEBUG feature: define CORE_DEBUG=1 to enable verbose prints.
 * 
 * Build (PC host):
 *   gcc -DPC_HOST=1 -DHAS_PRINTF=1 -DHAS_STDIO=1 -O2 coremark_single.c -lm -o coremark_host
 *
 * Build (bare-metal RISC-V; example):
 *   riscv32-unknown-elf-gcc -O2 -std=gnu11 -march=rv32im -mabi=ilp32 \
 *     -ffreestanding -nostdlib -Wl,-T,linker.lds \
 *     init_ram.S coremark_single.c -o coremark.elf
 *
 * Notes:
 * - For bare-metal timing, this reads a 64-bit free-running counter mapped at
 *   CYCLE_LO=0x80000000, CYCLE_HI=0x80000004 (adjust if different).
 * - UART TX is at 0x7000_0000 (adjust if different).
 * - To auto-iterate for ~10s as CoreMark does, leave ITERATIONS at 0; otherwise set ITERATIONS>0.
 */

// ==== Standard headers ====
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>

#ifdef PC_HOST
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include <time.h>
  #include <math.h>
#endif

// ==== Configuration (from core_portme.h), overridable via -D flags ====
#ifndef HAS_FLOAT
#define HAS_FLOAT 1
#endif

#ifndef HAS_TIME_H
#define HAS_TIME_H 1
#endif

#ifndef USE_CLOCK
#define USE_CLOCK 1
#endif

#ifndef HAS_STDIO
#define HAS_STDIO 0
#endif

#ifndef HAS_PRINTF
#define HAS_PRINTF 0
#endif

#ifndef SEED_METHOD
#define SEED_METHOD 2 /* SEED_VOLATILE */
#endif

#ifndef MEM_METHOD
#define MEM_METHOD 2 /* MEM_STACK */
#endif

#ifndef MULTITHREAD
#define MULTITHREAD 1
#define USE_PTHREAD 0
#define USE_FORK    0
#define USE_SOCKET  0
#endif

#ifndef MAIN_HAS_NOARGC
#define MAIN_HAS_NOARGC 0
#endif

#ifndef MAIN_HAS_NORETURN
#define MAIN_HAS_NORETURN 0
#endif

#ifndef TOTAL_DATA_SIZE
#define TOTAL_DATA_SIZE (2*1000)
#endif

#ifndef CORE_DEBUG
#define CORE_DEBUG 0
#endif

// ==== Types and helpers (from core_portme.h & coremark.h) ====
typedef signed short   ee_s16;
typedef unsigned short ee_u16;
typedef signed int     ee_s32;
typedef double         ee_f32;
typedef unsigned char  ee_u8;
typedef unsigned int   ee_u32;
typedef ee_u32         ee_ptr_int;
typedef size_t         ee_size_t;

#define align_mem(x) (void *)(((uintptr_t)(x) + 3) & ~(uintptr_t)3)

// Timing type
#define CORETIMETYPE unsigned long
typedef unsigned long CORE_TICKS;

// Multithread contexts
ee_u32 default_num_contexts = 1;

// UART (bare-metal)
#ifndef PC_HOST
  #define UART_TX_ADDR ((volatile uint8_t*)0x70000000u)
#endif

// Cycle counter & halt (bare-metal)
#ifndef PC_HOST
  #define CYCLE_LO_ADDR   ((volatile uint32_t*)0x80000000u)
  #define CYCLE_HI_ADDR   ((volatile uint32_t*)0x80000004u)
  #define HALT_ADDR       ((volatile uint32_t*)0x8FFFFFF0u)
  #define HALT_DATA       ((uint32_t)0x000000AAu)
  static inline void poke32(volatile uint32_t* addr, uint32_t data){ *addr = data; }
  static inline void core_halt(void){ poke32(HALT_ADDR, HALT_DATA); }
#endif

// ==== Declarations (from coremark.h) ====
#define SEED_ARG      0
#define SEED_FUNC     1
#define SEED_VOLATILE 2

#define MEM_STATIC 0
#define MEM_MALLOC 1
#define MEM_STACK  2

#if HAS_STDIO
#include <stdio.h>
#endif
#if HAS_PRINTF
#define ee_printf printf
#endif

void *iterate(void *pres);
#if HAS_FLOAT
typedef double secs_ret;
#else
typedef ee_u32 secs_ret;
#endif

#if MAIN_HAS_NORETURN
#define MAIN_RETURN_VAL
#define MAIN_RETURN_TYPE void
#else
#define MAIN_RETURN_VAL  0
#define MAIN_RETURN_TYPE int
#endif

void       start_time(void);
void       stop_time(void);
CORE_TICKS get_time(void);
secs_ret   time_in_secs(CORE_TICKS ticks);

// Provided for bare-metal; harmless on PC (unused)
#ifndef PC_HOST
CORETIMETYPE barebones_clock(void);
#endif

// Useful functions
ee_u16 crcu8(ee_u8 data, ee_u16 crc);
ee_u16 crc16(ee_s16 newval, ee_u16 crc);
ee_u16 crcu16(ee_u16 newval, ee_u16 crc);
ee_u16 crcu32(ee_u32 newval, ee_u16 crc);
ee_u8  check_data_types(void);
void * portable_malloc(ee_size_t size);
void   portable_free(void *p);
ee_s32 parseval(char *valstring);

// Algorithm IDs
#define ID_LIST             (1 << 0)
#define ID_MATRIX           (1 << 1)
#define ID_STATE            (1 << 2)
#define ALL_ALGORITHMS_MASK (ID_LIST | ID_MATRIX | ID_STATE)
#define NUM_ALGORITHMS      3

// List structures
typedef struct list_data_s {
    ee_s16 data16;
    ee_s16 idx;
} list_data;

typedef struct list_head_s {
    struct list_head_s *next;
    struct list_data_s *info;
} list_head;

// Matrix types
#define MATDAT_INT 1
#if MATDAT_INT
typedef ee_s16 MATDAT;
typedef ee_s32 MATRES;
#else
typedef ee_f16 MATDAT;
typedef ee_f32 MATRES;
#endif

typedef struct MAT_PARAMS_S {
    int     N;
    MATDAT *A;
    MATDAT *B;
    MATRES *C;
} mat_params;

// State machine
typedef enum CORE_STATE {
    CORE_START = 0,
    CORE_INVALID,
    CORE_S1,
    CORE_S2,
    CORE_INT,
    CORE_FLOAT,
    CORE_EXPONENT,
    CORE_SCIENTIFIC,
    NUM_CORE_STATES
} core_state_e;

// Results
typedef struct CORE_PORTABLE_S { ee_u8 portable_id; } core_portable;
typedef struct RESULTS_S {
    // inputs
    ee_s16              seed1;
    ee_s16              seed2;
    ee_s16              seed3;
    void *              memblock[4];
    ee_u32              size;
    ee_u32              iterations;
    ee_u32              execs;
    struct list_head_s *list;
    mat_params          mat;
    // outputs
    ee_u16 crc;
    ee_u16 crclist;
    ee_u16 crcmatrix;
    ee_u16 crcstate;
    ee_s16 err;
    // port
    core_portable port;
} core_results;

// ==== ee_printf (UART or host printf) + float helpers ====
static ee_size_t ee_strnlen(const char *s, ee_size_t count){
    const char *sc;
    for (sc = s; *sc != '\0' && count--; ++sc) { }
    return (ee_size_t)(sc - s);
}

#define ZEROPAD   (1 << 0)
#define SIGN      (1 << 1)
#define PLUS      (1 << 2)
#define SPACE     (1 << 3)
#define LEFT      (1 << 4)
#define HEX_PREP  (1 << 5)
#define UPPERCASE (1 << 6)
#define is_digit(c) ((c) >= '0' && (c) <= '9')

static int ee_skip_atoi(const char **s){
    int i = 0;
    while (is_digit(**s)) i = i*10 + *((*s)++) - '0';
    return i;
}

static char *digits       = "0123456789abcdefghijklmnopqrstuvwxyz";
static char *upper_digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

static char * ee_number(char *str, long num, int base, int size, int precision, int type){
    char  c, sign, tmp[66];
    char *dig = (type & UPPERCASE) ? upper_digits : digits;
    int   i = 0;
    if (type & LEFT) type &= ~ZEROPAD;
    if (base < 2 || base > 36) return 0;
    c    = (type & ZEROPAD) ? '0' : ' ';
    sign = 0;
    if (type & SIGN){
        if (num < 0){ sign='-'; num=-num; size--; }
        else if (type & PLUS){ sign='+'; size--; }
        else if (type & SPACE){ sign=' '; size--; }
    }
    if (type & HEX_PREP){
        if (base == 16) size -= 2;
        else if (base == 8) size--;
    }
    if (num==0) tmp[i++]='0';
    else{
        while (num){ tmp[i++] = dig[((unsigned long)num)% (unsigned)base]; num = ((unsigned long)num)/(unsigned)base; }
    }
    if (i > precision) precision = i;
    size -= precision;
    if (!(type & (ZEROPAD|LEFT))) while (size-- > 0) *str++ = ' ';
    if (sign) *str++ = sign;
    if (type & HEX_PREP){
        if (base == 8) *str++='0';
        else if (base==16){ *str++='0'; *str++='x'; }
    }
    if (!(type & LEFT)) while (size-- > 0) *str++ = c;
    while (i < precision--) *str++ = '0';
    while (i-- > 0) *str++ = tmp[i];
    while (size-- > 0) *str++ = ' ';
    return str;
}

#if HAS_FLOAT
// cvt helpers (from cvt.c)
#include <math.h>
#define CVTBUFSIZE 80
static char CVTBUF[CVTBUFSIZE];
static char * ee_cvt(double arg, int ndigits, int *decpt, int *sign, char *buf, int eflag){
    int r2; double fi, fj; char *p, *p1; if (ndigits<0) ndigits=0; if (ndigits>=CVTBUFSIZE-1) ndigits = CVTBUFSIZE-2;
    r2=0; *sign=0; p=&buf[0]; if (arg<0){ *sign=1; arg=-arg; } arg=modf(arg,&fi); p1=&buf[CVTBUFSIZE];
    if (fi!=0){ p1=&buf[CVTBUFSIZE]; while (fi!=0){ fj=modf(fi/10,&fi); *--p1=(int)((fj+.03)*10)+'0'; r2++; } while (p1<&buf[CVTBUFSIZE]) *p++=*p1++; }
    else if (arg>0){ while ((fj=arg*10)<1){ arg=fj; r2--; } }
    p1 = &buf[ndigits]; if (eflag==0) p1 += r2; *decpt=r2; if (p1 < &buf[0]){ buf[0]='\0'; return buf; }
    while (p<=p1 && p<&buf[CVTBUFSIZE]){ arg*=10; arg=modf(arg,&fj); *p++ = (int)fj + '0'; }
    if (p1>=&buf[CVTBUFSIZE]){ buf[CVTBUFSIZE-1]='\0'; return buf; }
    p=p1; *p1 += 5; while (*p1>'9'){ *p1='0'; if (p1>buf) ++*--p1; else { *p1='1'; (*decpt)++; if (eflag==0){ if (p>buf) *p='0'; p++; } } }
    *p = '\0'; return buf;
}
static char * ecvtbuf(double arg, int ndigits, int *decpt, int *sign, char *buf){ return ee_cvt(arg,ndigits,decpt,sign,buf,1); }
static char * fcvtbuf(double arg, int ndigits, int *decpt, int *sign, char *buf){ return ee_cvt(arg,ndigits,decpt,sign,buf,0); }

static void ee_bufcpy(char *d, const char *s, int count){ const char*pe=s+count; while(s!=pe) *d++ = *s++; }

static void ee_decimal_point(char *buffer){
    while (*buffer){ if (*buffer=='.') return; if (*buffer=='e'||*buffer=='E') break; buffer++; }
    if (*buffer){ int n=(int)ee_strnlen(buffer,256); while (n>0){ buffer[n+1]=buffer[n]; n--; } *buffer='.'; }
    else { *buffer++='.'; *buffer='\0'; }
}
static void ee_cropzeros(char *buffer){
    char *stop; while (*buffer && *buffer!='.') buffer++; if (*buffer++){ while (*buffer && *buffer!='e' && *buffer!='E') buffer++; stop=buffer--; while (*buffer=='0') buffer--; if (*buffer=='.') buffer--; while (buffer!=stop) *++buffer=0; }
}
static char * ee_flt(char *str, double num, int size, int precision, char fmt, int flags){
    char tmp[80], c, sign; int n,i,decpt,sgn,exp,pos,capexp=0,magnitude; char *digits=NULL; char cvtbuf[80];
    if (flags & LEFT) flags &= ~ZEROPAD; c = (flags & ZEROPAD) ? '0' : ' '; sign = 0;
    if (flags & SIGN){ if (num<0.0){ sign='-'; num=-num; size--; } else if (flags & PLUS){ sign='+'; size--; } else if (flags & SPACE){ sign=' '; size--; } }
    if (precision<0) precision=6;
    if (fmt=='G' || fmt=='E'){ capexp=1; fmt += 'a'-'A'; }
    if (fmt=='g'){ digits=ecvtbuf(num,precision,&decpt,&sgn,cvtbuf); magnitude=decpt-1; if (magnitude<-4 || magnitude>precision-1){ fmt='e'; precision-=1; } else { fmt='f'; precision-=decpt; } }
    if (fmt=='e'){
        digits=ecvtbuf(num,precision+1,&decpt,&sgn,cvtbuf);
        if (sgn) *str++='-'; *str++=*digits; if (precision>0) *str++='.'; ee_bufcpy(str,digits+1,precision); str+=precision; *str++ = capexp?'E':'e';
        if (decpt==0){ exp = (num==0.0)?0:-1; } else exp = decpt-1;
        if (exp<0){ *str++='-'; exp=-exp; } else *str++='+';
        str[2]=(exp%10)+'0'; exp/=10; str[1]=(exp%10)+'0'; exp/=10; str[0]=(exp%10)+'0'; str+=3;
    } else if (fmt=='f'){
        digits=fcvtbuf(num,precision,&decpt,&sgn,cvtbuf);
        if (sgn) *str++='-';
        if (*digits){
            if (decpt<=0){ *str++='0'; *str++='.'; for (pos=0; pos<-decpt; pos++) *str++='0'; while (*digits) *str++=*digits++;
            } else { pos=0; while (*digits){ if (pos++==decpt) *str++='.'; *str++=*digits++; } }
        } else { *str++='0'; if (precision>0){ *str++='.'; for (pos=0; pos<precision; pos++) *str++='0'; } }
    }
    *str='\0';
    if ((flags & HEX_PREP) && precision==0) ee_decimal_point(tmp);
    if (fmt=='g' && !(flags & HEX_PREP)) ee_cropzeros(tmp);
    n = (int)ee_strnlen(tmp,256); size -= n;
    if (!(flags & (ZEROPAD|LEFT))) while (size-- > 0) *str++ = ' ';
    if (sign) *str++ = sign;
    if (!(flags & LEFT)) while (size-- > 0) *str++ = c;
    for (i=0;i<n;i++) *str++ = tmp[i];
    while (size-- > 0) *str++=' ';
    return str;
}
#endif // HAS_FLOAT

static int ee_vsprintf(char *buf, const char *fmt, va_list args){
    int len; unsigned long num; int i, base; char *str, *s; int flags; int field_width; int precision; int qualifier;
    for (str=buf; *fmt; fmt++){
        if (*fmt!='%'){ *str++ = *fmt; continue; }
        flags=0;
    repeat:
        fmt++;
        switch (*fmt){
            case '-': flags|=LEFT; goto repeat;
            case '+': flags|=PLUS; goto repeat;
            case ' ': flags|=SPACE; goto repeat;
            case '#': flags|=HEX_PREP; goto repeat;
            case '0': flags|=ZEROPAD; goto repeat;
        }
        field_width = -1;
        if (is_digit(*fmt)) field_width = ee_skip_atoi(&fmt);
        else if (*fmt=='*'){ fmt++; field_width = va_arg(args,int); if (field_width<0){ field_width=-field_width; flags|=LEFT; } }
        precision = -1;
        if (*fmt=='.'){
            ++fmt;
            if (is_digit(*fmt)) precision = ee_skip_atoi(&fmt);
            else if (*fmt=='*'){ ++fmt; precision = va_arg(args,int); }
            if (precision<0) precision=0;
        }
        qualifier = -1;
        if (*fmt=='l' || *fmt=='L'){ qualifier = *fmt; fmt++; }
        base = 10;
        switch (*fmt){
            case 'c':
                if (!(flags & LEFT)) while (--field_width>0) *str++=' ';
                *str++ = (unsigned char)va_arg(args,int);
                while (--field_width>0) *str++=' ';
                continue;
            case 's':
                s = va_arg(args, char*); if (!s) s = (char*)"<NULL>";
                len = (int)ee_strnlen(s, precision<0? (ee_size_t)~0 : (ee_size_t)precision);
                if (!(flags&LEFT)) while (len<field_width--) *str++=' ';
                for (i=0;i<len;i++) *str++ = *s++;
                while (len<field_width--) *str++=' ';
                continue;
            case 'p':
                if (field_width==-1){ field_width = 2*(int)sizeof(void*); flags|=ZEROPAD; }
                str = ee_number(str, (unsigned long)va_arg(args, void*), 16, field_width, precision, flags);
                continue;
            case 'A': flags|=UPPERCASE; // fallthrough
            case 'a': // ignore MAC/IP custom
                continue;
            case 'o': base=8; break;
            case 'X': flags|=UPPERCASE; // fallthrough
            case 'x': base=16; break;
            case 'd': case 'i': flags|=SIGN; // fallthrough
            case 'u': break;
#if HAS_FLOAT
            case 'f':
                str = ee_flt(str, va_arg(args,double), field_width, precision, *fmt, flags|SIGN);
                continue;
#endif
            default:
                if (*fmt!='%') *str++='%';
                if (*fmt) *str++=*fmt; else --fmt;
                continue;
        }
        if (qualifier=='l') num = va_arg(args, unsigned long);
        else if (flags & SIGN) num = va_arg(args, int);
        else num = va_arg(args, unsigned int);
        str = ee_number(str, num, base, field_width, precision, flags);
    }
    *str = '\0';
    return (int)(str - buf);
}

static int ee_printf_impl(const char *fmt, ...){
    char buf[1024], *p; va_list args; int n=0;
    va_start(args, fmt); ee_vsprintf(buf, fmt, args); va_end(args);
    p = buf;
#ifdef PC_HOST
    // Host: just write to stdout
    fputs(p, stdout);
    n = (int)strlen(p);
#else
    while (*p){ *UART_TX_ADDR = (uint8_t)(*p); n++; p++; }
#endif
    return n;
}

#if !HAS_PRINTF
#define ee_printf ee_printf_impl
#endif

// ==== Timing (portable_init, start/stop/get_time) ====
#if defined(PC_HOST)
// Host timing via clock()
static CORE_TICKS start_time_val, stop_time_val;
void start_time(void){ start_time_val = (CORE_TICKS)clock(); }
void stop_time(void){  stop_time_val  = (CORE_TICKS)clock(); }
#define EE_TICKS_PER_SEC ((CORE_TICKS)CLOCKS_PER_SEC)
CORE_TICKS get_time(void){ return stop_time_val - start_time_val; }
secs_ret time_in_secs(CORE_TICKS ticks){ return ((secs_ret)ticks)/((secs_ret)EE_TICKS_PER_SEC); }
void portable_init(core_portable *p, int *argc, char *argv[]){ (void)p; (void)argc; (void)argv; }
#else
// Bare-metal timing via free-running 64-bit counter
static CORETIMETYPE start_time_val, stop_time_val;

CORETIMETYPE barebones_clock(void){
    uint32_t hi1, lo, hi2;
    do {
        hi1 = *CYCLE_HI_ADDR;
        lo  = *CYCLE_LO_ADDR;
        hi2 = *CYCLE_HI_ADDR;
    } while (hi1 != hi2);
    return ((CORETIMETYPE)hi2 << 32) | (CORETIMETYPE)lo;
}
#define GETMYTIME(_t) (*(_t) = barebones_clock())
#define MYTIMEDIFF(fin,ini) ((fin)-(ini))
// Set your clock frequency here (Hz):
#ifndef CLOCKS_PER_SEC
#define CLOCKS_PER_SEC ((ee_u32)500000000u) // 500 MHz default
#endif
#define TIMER_RES_DIVIDER 1
#define EE_TICKS_PER_SEC ((CORE_TICKS)(CLOCKS_PER_SEC/TIMER_RES_DIVIDER))
void start_time(void){ GETMYTIME(&start_time_val); }
void stop_time(void){  GETMYTIME(&stop_time_val);  }
CORE_TICKS get_time(void){ return (CORE_TICKS)MYTIMEDIFF(stop_time_val, start_time_val); }
secs_ret time_in_secs(CORE_TICKS ticks){ return ((secs_ret)ticks)/((secs_ret)EE_TICKS_PER_SEC); }
void portable_init(core_portable *p, int *argc, char *argv[]){ (void)argc; (void)argv; p->portable_id = 1; }
#endif

// ==== Seeds (from core_portme.c/util) ====
#if (SEED_METHOD == SEED_VOLATILE)
volatile ee_s32 seed1_volatile = 0x0;
volatile ee_s32 seed2_volatile = 0x0;
volatile ee_s32 seed3_volatile = 0x66;
#ifndef ITERATIONS
#define ITERATIONS 0
#endif
volatile ee_s32 seed4_volatile = ITERATIONS;
volatile ee_s32 seed5_volatile = 0;
ee_s32 get_seed_32(int i){
    switch (i){
        case 1: return seed1_volatile;
        case 2: return seed2_volatile;
        case 3: return seed3_volatile;
        case 4: return seed4_volatile;
        case 5: return seed5_volatile;
        default: return 0;
    }
}
#else
ee_s32 get_seed_32(int i); // others not implemented here
#endif
#if (SEED_METHOD == SEED_ARG)
ee_s32 get_seed_args(int i, int argc, char *argv[]);
#define get_seed(x)    (ee_s16) get_seed_args(x, argc, argv)
#define get_seed_32(x) get_seed_args(x, argc, argv)
#else
#define get_seed(x) (ee_s16) get_seed_32(x)
#endif

// ==== CRC & utils (from core_util.c) ====
ee_u16 crcu8(ee_u8 data, ee_u16 crc){
    ee_u8 i=0, x16=0, carry=0;
    for (i=0;i<8;i++){
        x16 = (ee_u8)((data & 1) ^ ((ee_u8)crc & 1));
        data >>= 1;
        if (x16==1){ crc ^= 0x4002; carry=1; } else carry=0;
        crc >>= 1;
        if (carry) crc |= 0x8000; else crc &= 0x7fff;
    }
    return crc;
}
ee_u16 crcu16(ee_u16 newval, ee_u16 crc){
    crc = crcu8((ee_u8)newval, crc);
    crc = crcu8((ee_u8)(newval>>8), crc);
    return crc;
}
ee_u16 crc16(ee_s16 newval, ee_u16 crc){ return crcu16((ee_u16)newval, crc); }
ee_u16 crcu32(ee_u32 newval, ee_u16 crc){
    crc = crc16((ee_s16)newval, crc);
    crc = crc16((ee_s16)(newval>>16), crc);
    return crc;
}
ee_u8 check_data_types(void){
    ee_u8 retval = 0;
    if (sizeof(ee_u8)  != 1){ ee_printf("ERROR: ee_u8 not 8b!\n");  retval++; }
    if (sizeof(ee_u16) != 2){ ee_printf("ERROR: ee_u16 not 16b!\n"); retval++; }
    if (sizeof(ee_s16) != 2){ ee_printf("ERROR: ee_s16 not 16b!\n"); retval++; }
    if (sizeof(ee_s32) != 4){ ee_printf("ERROR: ee_s32 not 32b!\n"); retval++; }
    if (sizeof(ee_u32) != 4){ ee_printf("ERROR: ee_u32 not 32b!\n"); retval++; }
    if (sizeof(void*)  != sizeof(ee_ptr_int)){ ee_printf("ERROR: ee_ptr_int size mismatch!\n"); retval++; }
    return retval;
}
void * portable_malloc(ee_size_t size){
#ifdef PC_HOST
    return malloc(size);
#else
    (void)size; return NULL; // Not used when MEM_STACK
#endif
}
void portable_free(void *p){
#ifdef PC_HOST
    free(p);
#else
    (void)p;
#endif
}
ee_s32 parseval(char *valstring){
    ee_s32 retval=0, neg=1; int hexmode=0;
    if (*valstring=='-'){ neg=-1; valstring++; }
    if (valstring[0]=='0' && valstring[1]=='x'){ hexmode=1; valstring+=2; }
    if (hexmode){
        while (((*valstring>='0')&&(*valstring<='9')) || ((*valstring>='a')&&(*valstring<='f'))){
            ee_s32 digit=*valstring - '0'; if (digit>9) digit=10 + *valstring - 'a';
            retval = (retval<<4) + digit; valstring++;
        }
    } else {
        while ((*valstring>='0')&&(*valstring<='9')){ retval = retval*10 + (*valstring - '0'); valstring++; }
    }
    if (*valstring=='K') retval *= 1024;
    if (*valstring=='M') retval *= 1024*1024;
    return retval*neg;
}

// ==== LIST (from core_list_join.c) ====
// Forward declarations to avoid implicit int errors when used in calc_func()
ee_u16 core_bench_state(ee_u32 blksize, ee_u8 *memblock,
                        ee_s16 seed1, ee_s16 seed2, ee_s16 step, ee_u16 crc);
ee_u16 core_bench_matrix(mat_params *p, ee_s16 seed, ee_u16 crc);

static ee_s16 calc_func(ee_s16 *pdata, core_results *res){
    ee_s16 data = *pdata; ee_s16 retval; ee_u8 optype = (ee_u8)((data>>7) & 1);
    if (optype) return (data & 0x007f);
    else {
        ee_s16 flag = data & 0x7;
        ee_s16 dtype = (ee_s16)((data>>3) & 0xf);
        dtype |= dtype << 4;
        switch (flag){
            case 0: {
                if (dtype < 0x22) dtype = 0x22;
                retval = core_bench_state(res->size, (ee_u8*)res->memblock[3], res->seed1, res->seed2, dtype, res->crc);
                if (res->crcstate==0) res->crcstate = retval; break;
            }
            case 1: {
                retval = core_bench_matrix(&(res->mat), dtype, res->crc);
                if (res->crcmatrix==0) res->crcmatrix = retval; break;
            }
            default: retval = data; break;
        }
        res->crc = crcu16((ee_u16)retval, res->crc);
        retval &= 0x007f;
        *pdata = (ee_s16)((data & 0xff00) | 0x0080 | retval);
        return retval;
    }
}
static ee_s32 cmp_complex(list_data *a, list_data *b, core_results *res){
    ee_s16 val1 = calc_func(&(a->data16), res);
    ee_s16 val2 = calc_func(&(b->data16), res);
    return (ee_s32)(val1 - val2);
}
static ee_s32 cmp_idx(list_data *a, list_data *b, core_results *res){
    if (res==NULL){
        a->data16 = (a->data16 & 0xff00) | (0x00ff & (a->data16>>8));
        b->data16 = (b->data16 & 0xff00) | (0x00ff & (b->data16>>8));
    }
    return (ee_s32)(a->idx - b->idx);
}
static void copy_info(list_data *to, list_data *from){ to->data16 = from->data16; to->idx = from->idx; }

static list_head *core_list_find(list_head *list, list_data *info){
    if (info->idx >= 0){ while (list && (list->info->idx != info->idx)) list = list->next; return list; }
    else { while (list && (list->info->data16 != info->data16)) list = list->next; return list; }
}
static list_head *core_list_reverse(list_head *list){
    list_head *next = 0, *tmp = 0;
    while (list){
        next = list->next; list->next = tmp; tmp = list; list = next;
    }
    return tmp;
}
static list_head *core_list_remove(list_head *item){
    list_data *tmp; list_head *ret = item->next;
    tmp = item->info; item->info = ret->info; ret->info = tmp;
    item->next = item->next->next; ret->next = NULL; return ret;
}
static list_head *core_list_undo_remove(list_head *item_removed, list_head *item_modified){
    list_data *tmp = item_removed->info; item_removed->info = item_modified->info; item_modified->info = tmp;
    item_removed->next = item_modified->next; item_modified->next = item_removed; return item_removed;
}
static list_head *core_list_insert_new(list_head * insert_point, list_data * info, list_head **memblock, list_data **datablock, list_head * memblock_end, list_data * datablock_end){
    list_head *newitem;
    if ((*memblock + 1) >= memblock_end) return NULL;
    if ((*datablock + 1) >= datablock_end) return NULL;
    newitem = *memblock; (*memblock)++; newitem->next = insert_point->next; insert_point->next = newitem;
    newitem->info = *datablock; (*datablock)++; copy_info(newitem->info, info);
    return newitem;
}
list_head *core_list_init(ee_u32 blksize, list_head *memblock, ee_s16 seed){
    ee_u32 per_item = 16 + sizeof(struct list_data_s);
    ee_u32 size = (blksize / per_item) - 2;
    list_head *memblock_end = memblock + size;
    list_data *datablock = (list_data *)(memblock_end);
    list_data *datablock_end = datablock + size;
    ee_u32 i; list_head *finder, *list = memblock; list_data info;
    list->next = NULL; list->info = datablock; list->info->idx = 0; list->info->data16 = (ee_s16)0x8080; memblock++; datablock++;
    info.idx = 0x7fff; info.data16 = (ee_s16)0xffff;
    core_list_insert_new(list, &info, &memblock, &datablock, memblock_end, datablock_end);
    for (i=0;i<size;i++){
        ee_u16 datpat = ((ee_u16)(seed ^ i) & 0xf);
        ee_u16 dat = (ee_u16)((datpat<<3) | (i & 0x7));
        info.data16 = (ee_s16)((dat<<8) | dat);
        core_list_insert_new(list, &info, &memblock, &datablock, memblock_end, datablock_end);
    }
    finder = list->next; i = 1;
    while (finder->next != NULL){
        if (i < size/5) finder->info->idx = (ee_s16)(i++);
        else { ee_u16 pat = (ee_u16)(i++ ^ seed); finder->info->idx = (ee_s16)(0x3fff & (((i & 0x07) << 8) | pat)); }
        finder = finder->next;
    }
    // mergesort by idx
    // Simple insertion sort for brevity in single-file (keeps behavior adequate)
    list_head* head = list->next;
    list_head* sorted = NULL;
    while (head){
        list_head* cur = head; head = head->next;
        if (!sorted || cmp_idx(cur->info, sorted->info, NULL) < 0){ cur->next = sorted; sorted = cur; }
        else {
            list_head* s = sorted;
            while (s->next && cmp_idx(cur->info, s->next->info, NULL) >= 0) s = s->next;
            cur->next = s->next; s->next = cur;
        }
    }
    list->next = sorted;
#if CORE_DEBUG
    ee_printf("Initialized list\n");
#endif
    return list;
}
static list_head *merge_sorted(list_head *a, list_head *b, ee_s32 (*cmp)(list_data*,list_data*,core_results*), core_results*res){
    list_head head, *tail=&head; head.next=NULL;
    while (a && b){
        if (cmp(a->info,b->info,res) <= 0){ tail->next=a; a=a->next; }
        else { tail->next=b; b=b->next; }
        tail=tail->next;
    }
    tail->next = a ? a : b;
    return head.next;
}
static void split_list(list_head* src, list_head** front, list_head** back){
    list_head* fast=src->next; list_head* slow=src;
    while (fast){ fast=fast->next; if (fast){ slow=slow->next; fast=fast->next; } }
    *front = src; *back = slow->next; slow->next = NULL;
}
static list_head *core_list_mergesort(list_head *list, ee_s32 (*cmp)(list_data*,list_data*,core_results*), core_results *res){
    if (!list || !list->next) return list;
    list_head *a,*b; split_list(list,&a,&b);
    a = core_list_mergesort(a,cmp,res);
    b = core_list_mergesort(b,cmp,res);
    return merge_sorted(a,b,cmp,res);
}
ee_u16 core_bench_list(core_results *res, ee_s16 finder_idx){
    ee_u16 retval=0, found=0, missed=0; list_head *list = res->list; ee_s16 find_num = (ee_s16)res->seed3;
    list_head *this_find; list_head *finder,*remover; list_data info = {0}; ee_s16 i;
    info.idx = finder_idx;
    for (i=0;i<find_num;i++){
        info.data16 = (ee_s16)(i & 0xff);
        this_find = core_list_find(list, &info);
        list = core_list_reverse(list);
        if (!this_find){ missed++; retval += (ee_u16)((list->next->info->data16 >> 8) & 1); }
        else {
            found++; if (this_find->info->data16 & 0x1) retval += (ee_u16)((this_find->info->data16 >> 9) & 1);
            if (this_find->next){
                finder = this_find->next; this_find->next = finder->next; finder->next = list->next; list->next = finder;
            }
        }
        if (info.idx >= 0) info.idx++;
#if CORE_DEBUG
        ee_printf("List find %d: [%d,%d,%d]\n", i, retval, missed, found);
#endif
    }
    retval += (ee_u16)(found*4 - missed);
    if (finder_idx > 0) list = core_list_mergesort(list, cmp_complex, res);
    remover = core_list_remove(list->next);
    finder = core_list_find(list, &info); if (!finder) finder = list->next;
    while (finder){ retval = crc16(list->info->data16, retval); finder = finder->next; }
#if CORE_DEBUG
    ee_printf("List sort 1: %04x\n", retval);
#endif
    remover = core_list_undo_remove(remover, list->next);
    list = core_list_mergesort(list, cmp_idx, NULL);
    finder = list->next;
    while (finder){ retval = crc16(list->info->data16, retval); finder = finder->next; }
#if CORE_DEBUG
    ee_printf("List sort 2: %04x\n", retval);
#endif
    res->list = list;
    return retval;
}

// ==== MATRIX (from core_matrix.c) ====
#define matrix_test_next(x)      ((x) + 1)
#define matrix_clip(x, y)        ((y) ? ((x)&0x0ff) : ((x)&0x0ffff))
#define matrix_big(x)            (0xf000 | (x))
#define bit_extract(x, from, to) (((x) >> (from)) & (~(0xffffffffu << (to))))
#if CORE_DEBUG
static void printmat(MATDAT *A, ee_u32 N, const char *name){
    ee_u32 i,j; ee_printf("Matrix %s [%d x %d]:\n", name, (int)N, (int)N);
    for (i=0;i<N;i++){ for (j=0;j<N;j++){ if (j!=0) ee_printf(","); ee_printf("%d", A[i*N+j]); } ee_printf("\n"); }
}
static void printmatC(MATRES *C, ee_u32 N, const char *name){
    ee_u32 i,j; ee_printf("Matrix %s [%d x %d]:\n", name, (int)N, (int)N);
    for (i=0;i<N;i++){ for (j=0;j<N;j++){ if (j!=0) ee_printf(","); ee_printf("%d", C[i*N+j]); } ee_printf("\n"); }
}
#endif
static ee_s16 matrix_sum(ee_u32 N, MATRES *C, MATDAT clipval){
    MATRES tmp=0, prev=0, cur=0; ee_s16 ret=0; ee_u32 i,j;
    for (i=0;i<N;i++){
        for (j=0;j<N;j++){
            cur = C[i*N + j];
            tmp += cur;
            if (tmp > clipval){ ret += 10; tmp = 0; }
            else { ret += (cur > prev) ? 1 : 0; }
            prev = cur;
        }
    }
    return ret;
}
static void matrix_mul_const(ee_u32 N, MATRES *C, MATDAT *A, MATDAT val){
    ee_u32 i,j; for (i=0;i<N;i++) for (j=0;j<N;j++) C[i*N+j] = (MATRES)A[i*N+j] * (MATRES)val;
}
static void matrix_add_const(ee_u32 N, MATDAT *A, MATDAT val){
    ee_u32 i,j; for (i=0;i<N;i++) for (j=0;j<N;j++) A[i*N+j] += val;
}
static void matrix_mul_vect(ee_u32 N, MATRES *C, MATDAT *A, MATDAT *B){
    ee_u32 i,j; for (i=0;i<N;i++){ C[i]=0; for (j=0;j<N;j++) C[i] += (MATRES)A[i*N+j]*(MATRES)B[j]; }
}
static void matrix_mul_matrix(ee_u32 N, MATRES *C, MATDAT *A, MATDAT *B){
    ee_u32 i,j,k; for (i=0;i<N;i++) for (j=0;j<N;j++){ MATRES sum=0; for (k=0;k<N;k++) sum += (MATRES)A[i*N+k]*(MATRES)B[k*N+j]; C[i*N+j]=sum; }
}
static void matrix_mul_matrix_bitextract(ee_u32 N, MATRES *C, MATDAT *A, MATDAT *B){
    ee_u32 i,j,k; for (i=0;i<N;i++) for (j=0;j<N;j++){ MATRES sum=0; for (k=0;k<N;k++){ MATDAT a = (MATDAT)bit_extract(A[i*N+k],0,4)+((MATDAT)bit_extract(A[i*N+k],4,4));
            MATDAT b = (MATDAT)bit_extract(B[k*N+j],0,4)+((MATDAT)bit_extract(B[k*N+j],4,4));
            sum += (MATRES)a*(MATRES)b; } C[i*N+j]=sum; }
}
ee_u16 core_bench_matrix(mat_params *p, ee_s16 seed, ee_u16 crc){
    ee_u32 N = (ee_u32)p->N; MATRES *C = p->C; MATDAT *A = p->A; MATDAT *B = p->B; MATDAT val = (MATDAT)seed;
    crc = crc16(matrix_test_next(0), crc); // minimal perturbation
    matrix_add_const(N, A, val);
#if CORE_DEBUG
    printmat(A,N,"matrix_add_const");
#endif
    matrix_mul_const(N, C, A, val); crc = crc16(matrix_sum(N, C, matrix_big(val)), crc);
#if CORE_DEBUG
    printmatC(C,N,"matrix_mul_const");
#endif
    matrix_mul_vect(N, C, A, B);     crc = crc16(matrix_sum(N, C, matrix_big(val)), crc);
#if CORE_DEBUG
    printmatC(C,N,"matrix_mul_vect");
#endif
    matrix_mul_matrix(N, C, A, B);   crc = crc16(matrix_sum(N, C, matrix_big(val)), crc);
#if CORE_DEBUG
    printmatC(C,N,"matrix_mul_matrix");
#endif
    matrix_mul_matrix_bitextract(N, C, A, B); crc = crc16(matrix_sum(N, C, matrix_big(val)), crc);
#if CORE_DEBUG
    printmatC(C,N,"matrix_mul_matrix_bitextract");
#endif
    matrix_add_const(N, A, -val);
    return crc;
}
ee_u32 core_init_matrix(ee_u32 blksize, void *memblk, ee_s32 seed, mat_params *p){
    ee_u32 N=0; MATDAT *A; MATDAT *B; ee_s32 order = 1; MATDAT val; ee_u32 i=0,j=0; if (seed==0) seed=1;
    while (j < blksize){ i++; j = i*i*2*4; } N = i-1;
    A = (MATDAT*)align_mem(memblk); B = A + N*N;
    for (i=0;i<N;i++){
        for (j=0;j<N;j++){
            seed = ((order * seed) % 65536);
            val = (MATDAT)(seed + order); val = (MATDAT)matrix_clip(val,0); B[i*N + j] = val;
            val = (MATDAT)(val + order);  val = (MATDAT)matrix_clip(val,1); A[i*N + j] = val;
            order++;
        }
    }
    p->A = A; p->B = B; p->C = (MATRES*)align_mem(B + N*N); p->N = (int)N;
#if CORE_DEBUG
    printmat(A,N,"A"); printmat(B,N,"B");
#endif
    return N;
}

// ==== STATE (from core_state.c) ====
static ee_u8 *intpat[4]  = { (ee_u8*)"5012", (ee_u8*)"1234", (ee_u8*)"-874", (ee_u8*)"+122" };
static ee_u8 *floatpat[4]= { (ee_u8*)"35.54400", (ee_u8*)".1234500", (ee_u8*)"-110.700", (ee_u8*)"+0.64400" };
static ee_u8 *scipat[4]  = { (ee_u8*)"5.500e+3", (ee_u8*)"-.123e-2", (ee_u8*)"-87e+832", (ee_u8*)"+0.6e-12" };
static ee_u8 *errpat[4]  = { (ee_u8*)"T0.3e-1F", (ee_u8*)"-T.T++Tq", (ee_u8*)"1T3.4e4z", (ee_u8*)"34.0e-T^" };

static ee_u8 ee_isdigit(ee_u8 c){ return ((c>='0') & (c<='9')) ? 1 : 0; }

enum CORE_STATE core_state_transition(ee_u8 **instr, ee_u32 *transition_count){
    ee_u8 *str = *instr; ee_u8 NEXT_SYMBOL; enum CORE_STATE state = CORE_START;
    for (; *str && state != CORE_INVALID; str++){
        NEXT_SYMBOL = *str;
        if (NEXT_SYMBOL == ','){ str++; break; }
        switch (state){
            case CORE_START:
                if (ee_isdigit(NEXT_SYMBOL)) state = CORE_INT;
                else if (NEXT_SYMBOL=='+' || NEXT_SYMBOL=='-') state = CORE_S1;
                else if (NEXT_SYMBOL=='.') state = CORE_FLOAT;
                else { state = CORE_INVALID; transition_count[CORE_INVALID]++; }
                transition_count[CORE_START]++; break;
            case CORE_S1:
                if (ee_isdigit(NEXT_SYMBOL)){ state = CORE_INT; transition_count[CORE_S1]++; }
                else if (NEXT_SYMBOL=='.'){ state = CORE_FLOAT; transition_count[CORE_S1]++; }
                else { state = CORE_INVALID; transition_count[CORE_INVALID]++; } break;
            case CORE_INT:
                if (NEXT_SYMBOL=='.'){ state = CORE_FLOAT; transition_count[CORE_INT]++; }
                else if (!ee_isdigit(NEXT_SYMBOL)){ if (NEXT_SYMBOL=='E' || NEXT_SYMBOL=='e') state = CORE_EXPONENT;
                    else { state = CORE_INVALID; transition_count[CORE_INVALID]++; } }
                transition_count[CORE_INT]++; break;
            case CORE_FLOAT:
                if (!ee_isdigit(NEXT_SYMBOL)){ if (NEXT_SYMBOL=='E' || NEXT_SYMBOL=='e') state = CORE_EXPONENT;
                    else { state = CORE_INVALID; transition_count[CORE_INVALID]++; } }
                transition_count[CORE_FLOAT]++; break;
            case CORE_EXPONENT:
                if (NEXT_SYMBOL=='+' || NEXT_SYMBOL=='-') state = CORE_S2;
                else if (ee_isdigit(NEXT_SYMBOL)) state = CORE_SCIENTIFIC;
                else { state = CORE_INVALID; transition_count[CORE_INVALID]++; }
                transition_count[CORE_EXPONENT]++; break;
            case CORE_S2:
                if (ee_isdigit(NEXT_SYMBOL)) state = CORE_SCIENTIFIC;
                else { state = CORE_INVALID; transition_count[CORE_INVALID]++; }
                transition_count[CORE_S2]++; break;
            default: break;
        }
    }
    *instr = str;
    return state;
}

void core_init_state(ee_u32 size, ee_s16 seed, ee_u8 *p){
    ee_u32 total=0, next=0, i; ee_u8 *buf=0;
#if CORE_DEBUG
    ee_printf("State: %d,%d\n", (int)size, (int)seed);
#endif
    size--; next=0;
    while ((total + next + 1) < size){
        if (next>0){
            for (i=0;i<next;i++) *(p+total+i) = buf[i];
            *(p+total+i) = ',';
            total += next+1;
        }
        seed++;
        switch (seed & 0x7){
            case 0: case 1: case 2: buf=intpat[(seed>>3)&0x3]; next=4; break;
            case 3: case 4:         buf=floatpat[(seed>>3)&0x3]; next=8; break;
            case 5: case 6:         buf=scipat[(seed>>3)&0x3]; next=8; break;
            case 7:                 buf=errpat[(seed>>3)&0x3]; next=8; break;
            default: break;
        }
    }
    size++;
    while (total < size){ *(p+total)=0; total++; }
#if CORE_DEBUG
    ee_printf("State Input ready\n");
#endif
}

ee_u16 core_bench_state(ee_u32 blksize, ee_u8 *memblock, ee_s16 seed1, ee_s16 seed2, ee_s16 step, ee_u16 crc){
    ee_u32 final_counts[NUM_CORE_STATES]; ee_u32 track_counts[NUM_CORE_STATES]; ee_u8 *p = memblock; ee_u32 i;
#if CORE_DEBUG
    ee_printf("State Bench: %d,%d,%d,%04x\n", seed1, seed2, step, crc);
#endif
    for (i=0;i<NUM_CORE_STATES;i++){ final_counts[i]=track_counts[i]=0; }
    while (*p != 0){
        enum CORE_STATE fstate = core_state_transition(&p, track_counts); final_counts[fstate]++;
#if CORE_DEBUG
        ee_printf("%d,", fstate);
#endif
    }
#if CORE_DEBUG
    ee_printf("\n");
#endif
    p = memblock;
    while (p < (memblock + blksize)){ if (*p != ',') *p ^= (ee_u8)seed1; p += step; }
    p = memblock;
    while (*p != 0){
        enum CORE_STATE fstate = core_state_transition(&p, track_counts); final_counts[fstate]++;
#if CORE_DEBUG
        ee_printf("%d,", fstate);
#endif
    }
#if CORE_DEBUG
    ee_printf("\n");
#endif
    p = memblock;
    while (p < (memblock + blksize)){ if (*p != ',') *p ^= (ee_u8)seed2; p += step; }
    for (i=0;i<NUM_CORE_STATES;i++){ crc = crcu32(final_counts[i], crc); crc = crcu32(track_counts[i], crc); }
    return crc;
}

// ==== iterate() and main() (from core_main.c) ====
static ee_u16 list_known_crc[]   = { (ee_u16)0xd4b0, (ee_u16)0x3340, (ee_u16)0x6a79, (ee_u16)0xe714, (ee_u16)0xe3c1 };
static ee_u16 matrix_known_crc[] = { (ee_u16)0xbe52, (ee_u16)0x1199, (ee_u16)0x5608, (ee_u16)0x1fd7, (ee_u16)0x0747 };
static ee_u16 state_known_crc[]  = { (ee_u16)0x5e47, (ee_u16)0x39bf, (ee_u16)0xe5a4, (ee_u16)0x8e3a, (ee_u16)0x8d84 };

ee_u16 core_bench_list(core_results *res, ee_s16 finder_idx);
ee_u32 core_init_matrix(ee_u32 blksize, void *memblk, ee_s32 seed, mat_params *p);
ee_u16 core_bench_matrix(mat_params *p, ee_s16 seed, ee_u16 crc);
void   core_init_state(ee_u32 size, ee_s16 seed, ee_u8 *p);
ee_u16 core_bench_state(ee_u32 blksize, ee_u8 *memblock, ee_s16 seed1, ee_s16 seed2, ee_s16 step, ee_u16 crc);

void * iterate(void *pres){
    ee_u32 i; ee_u16 crc; core_results *res = (core_results*)pres; ee_u32 iterations = res->iterations;
    res->crc = 0; res->crclist = 0; res->crcmatrix = 0; res->crcstate = 0;
    for (i=0;i<iterations;i++){
        crc = core_bench_list(res, 1);  res->crc = crcu16(crc, res->crc);
        crc = core_bench_list(res, -1); res->crc = crcu16(crc, res->crc);
        if (i==0) res->crclist = res->crc;
    }
    return NULL;
}

#if (MEM_METHOD == MEM_STATIC)
static ee_u8 static_memblk[TOTAL_DATA_SIZE];
#endif

static char *mem_name[3] = { "Static", "Heap", "Stack" };

// portable_init already above

MAIN_RETURN_TYPE main(
#if MAIN_HAS_NOARGC
void
#else
int argc, char *argv[]
#endif
){
#if MAIN_HAS_NOARGC
    int   argc = 0; char *argv_local[1]; char **argv = argv_local;
#endif
    ee_u16 i,j=0,num_algorithms=0; ee_s16 known_id=-1, total_errors=0; ee_u16 seedcrc=0;
    CORE_TICKS total_time; core_results results[MULTITHREAD];
#if (MEM_METHOD == MEM_STACK)
    ee_u8 stack_memblock[TOTAL_DATA_SIZE * MULTITHREAD];
#endif
    portable_init(&(results[0].port), &argc, argv);
    if (sizeof(struct list_head_s) > 128){ ee_printf("list_head structure too big for comparable data!\n"); return MAIN_RETURN_VAL; }
    results[0].seed1 = get_seed(1); results[0].seed2 = get_seed(2); results[0].seed3 = get_seed(3); results[0].iterations = (ee_u32)get_seed_32(4);
#if CORE_DEBUG
    results[0].iterations = 1;
#endif
    results[0].execs = (ee_u32)get_seed_32(5); if (results[0].execs == 0) results[0].execs = ALL_ALGORITHMS_MASK;
    if ((results[0].seed1==0)&&(results[0].seed2==0)&&(results[0].seed3==0)){ results[0].seed1=0; results[0].seed2=0; results[0].seed3=0x66; }
    if ((results[0].seed1==1)&&(results[0].seed2==0)&&(results[0].seed3==0)){ results[0].seed1=0x3415; results[0].seed2=0x3415; results[0].seed3=0x66; }
#if (MEM_METHOD == MEM_STATIC)
    results[0].memblock[0] = (void*)static_memblk; results[0].size = TOTAL_DATA_SIZE; results[0].err = 0;
#elif (MEM_METHOD == MEM_MALLOC)
    for (i=0;i<MULTITHREAD;i++){
        ee_s32 malloc_override = get_seed_32(7);
        results[i].size = (malloc_override!=0) ? (ee_u32)malloc_override : (ee_u32)TOTAL_DATA_SIZE;
        results[i].memblock[0] = portable_malloc(results[i].size);
        results[i].seed1 = results[0].seed1; results[i].seed2 = results[0].seed2; results[i].seed3 = results[0].seed3;
        results[i].err=0; results[i].execs=results[0].execs;
    }
#elif (MEM_METHOD == MEM_STACK)
    for (i=0;i<MULTITHREAD;i++){
        results[i].memblock[0] = stack_memblock + i*TOTAL_DATA_SIZE; results[i].size = TOTAL_DATA_SIZE;
        results[i].seed1 = results[0].seed1; results[i].seed2 = results[0].seed2; results[i].seed3 = results[0].seed3;
        results[i].err=0; results[i].execs=results[0].execs;
    }
#else
#error "Please define a way to initialize a memory block."
#endif
    // Data init: split memory among algorithms
    for (i=0;i<NUM_ALGORITHMS;i++){ if ((1u<<i) & results[0].execs) num_algorithms++; }
    for (i=0;i<MULTITHREAD;i++) results[i].size = results[i].size / (num_algorithms?num_algorithms:1);
    for (i=0;i<NUM_ALGORITHMS;i++){
        ee_u32 ctx;
        if ((1u<<i) & results[0].execs){
            for (ctx=0; ctx<MULTITHREAD; ctx++)
                results[ctx].memblock[i+1] = (char*)(results[ctx].memblock[0]) + results[0].size * j;
            j++;
        }
    }
    // call inits
    for (i=0;i<MULTITHREAD;i++){
        if (results[i].execs & ID_LIST){
            results[i].list = core_list_init(results[0].size, (list_head*)results[i].memblock[1], results[i].seed1);
        }
        if (results[i].execs & ID_MATRIX){
            core_init_matrix(results[0].size, results[i].memblock[2], (ee_s32)results[i].seed1 | (((ee_s32)results[i].seed2)<<16), &(results[i].mat));
        }
        if (results[i].execs & ID_STATE){
            core_init_state(results[0].size, results[i].seed1, (ee_u8*)results[i].memblock[3]);
        }
    }
    // auto-determine iterations if not set
    if (results[0].iterations == 0){
        secs_ret secs_passed = 0; ee_u32 divisor;
        results[0].iterations = 1;
        while (secs_passed < (secs_ret)1){
            results[0].iterations *= 10;
            start_time(); iterate(&results[0]); stop_time();
            secs_passed = time_in_secs(get_time());
        }
        divisor = (ee_u32)secs_passed; if (divisor==0) divisor = 1;
        results[0].iterations *= 1 + 10/divisor;
    }
    // run
    start_time();
    iterate(&results[0]);
    stop_time();
    total_time = get_time();
    // seed CRC
    seedcrc = crc16(results[0].seed1, seedcrc);
    seedcrc = crc16(results[0].seed2, seedcrc);
    seedcrc = crc16(results[0].seed3, seedcrc);
    seedcrc = crc16(results[0].size, seedcrc);
    switch (seedcrc){
        case 0x8a02: known_id=0; ee_printf("6k performance run parameters for coremark.\n"); break;
        case 0x7b05: known_id=1; ee_printf("6k validation run parameters for coremark.\n"); break;
        case 0x4eaf: known_id=2; ee_printf("Profile generation run parameters for coremark.\n"); break;
        case 0xe9f5: known_id=3; ee_printf("2K performance run parameters for coremark.\n"); break;
        case 0x18f2: known_id=4; ee_printf("2K validation run parameters for coremark.\n"); break;
        default: total_errors = -1; break;
    }
    if (known_id >= 0){
        for (i=0;i<default_num_contexts;i++){
            results[i].err = 0;
            if ((results[i].execs & ID_LIST)   && (results[i].crclist   != list_known_crc[known_id])) { ee_printf("[%u]ERROR! list crc 0x%04x - should be 0x%04x\n", i, results[i].crclist,   list_known_crc[known_id]);   results[i].err++; }
            if ((results[i].execs & ID_MATRIX) && (results[i].crcmatrix != matrix_known_crc[known_id])) { ee_printf("[%u]ERROR! matrix crc 0x%04x - should be 0x%04x\n", i, results[i].crcmatrix, matrix_known_crc[known_id]); results[i].err++; }
            if ((results[i].execs & ID_STATE)  && (results[i].crcstate  != state_known_crc[known_id])) { ee_printf("[%u]ERROR! state crc 0x%04x - should be 0x%04x\n",  i, results[i].crcstate,  state_known_crc[known_id]);  results[i].err++; }
            total_errors += results[i].err;
        }
    }
    total_errors += check_data_types();
    // report
    ee_printf("CoreMark 1.0 : %s / %s / %s\n", mem_name[MEM_METHOD], (HAS_PRINTF?"printf":"ee_printf"), (HAS_FLOAT?"float":"nofloat"));
    ee_printf("Seeds: %u %u %u | Iterations: %u | Size/alg: %u bytes\n",
              (unsigned)results[0].seed1, (unsigned)results[0].seed2, (unsigned)results[0].seed3,
              (unsigned)results[0].iterations, (unsigned)results[0].size);
    ee_printf("Total time (ticks): %lu\n", (unsigned long)total_time);
    secs_ret secs = time_in_secs(total_time);
#if HAS_FLOAT
    ee_printf("Total time (s): %f\n", (double)secs);
#endif
    if (known_id >= 0 && total_errors==0) ee_printf("Correct operation validated.\n");
    else if (total_errors>0) ee_printf("Errors detected: %d\n", (int)total_errors);
#ifndef PC_HOST
    core_halt();
#endif
    return MAIN_RETURN_VAL;
}
