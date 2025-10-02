/*
 * Minimal standalone ee_printf for bare-metal targets
 * - Default UART TX MMIO at 0x70000000 (change UART_TX_ADDR if needed)
 * - Supports %c %s %d %i %u %x %X %o %p and, optionally, %f %e %g
 * - No heap / no OS required
 *
 * Toggle float support:
 *   #define EEPRINTF_HAS_FLOAT 1   // needs <math.h>
 *   #define EEPRINTF_HAS_FLOAT 0   // default: smaller, no float formats
 */

#include <stdarg.h>
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>

#ifndef EEPRINTF_HAS_FLOAT
#define EEPRINTF_HAS_FLOAT 0
#endif

#if EEPRINTF_HAS_FLOAT
  #include <math.h>   /* uses modf() */
#endif

/* ========================= MMIO UART OUTPUT ========================= */
#ifndef UART_TX_ADDR
#define UART_TX_ADDR ((volatile uint8_t *)0x70000000u)
#endif

void uart_send_char(char c) {
   fputc(c, stdout);
}

/* You can override the output sink by redefining EE_PUTC */
#ifndef EE_PUTC
#define EE_PUTC(c) uart_send_char((c))
#endif

/* ========================= CoreMark-style typedefs ========================= */
typedef unsigned int  ee_u32;
typedef unsigned long ee_ptr_int;
typedef size_t        ee_size_t;

/* ========================= Internal helpers ========================= */
#define ZEROPAD   (1u << 0) /* Pad with zero */
#define SIGN      (1u << 1) /* Signed conversion */
#define PLUS      (1u << 2) /* Show '+' */
#define SPACE     (1u << 3) /* Leading space if no sign */
#define LEFT      (1u << 4) /* Left-justify within field */
#define HEX_PREP  (1u << 5) /* Add "0x"/"0" prefix */
#define UPPERCASE (1u << 6) /* Uppercase hex */

#define is_digit(c) ((c) >= '0' && (c) <= '9')

static char *digits       = "0123456789abcdefghijklmnopqrstuvwxyz";
static char *upper_digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

static ee_size_t strnlen_s(const char *s, ee_size_t count) {
    const char *p = s;
    while (*p && count--) p++;
    return (ee_size_t)(p - s);
}

static int skip_atoi(const char **s) {
    int i = 0;
    while (is_digit(**s)) i = i * 10 + (*((*s)++) - '0');
    return i;
}

static char *number(char *str, unsigned long num, int base,
                    int size, int precision, int type) {
    char c, sign = 0, tmp[66];
    char *dig = (type & UPPERCASE) ? upper_digits : digits;
    int i = 0;

    if (type & LEFT) type &= ~ZEROPAD;
    if (base < 2 || base > 36) return str;

    c = (type & ZEROPAD) ? '0' : ' ';

    if (type & SIGN) {
        long sn = (long)num;
        if ((long)sn < 0) {
            sign = '-';
            num  = (unsigned long)(-sn);
            size--;
        } else if (type & PLUS) {
            sign = '+';
            size--;
        } else if (type & SPACE) {
            sign = ' ';
            size--;
        }
    }

    if (type & HEX_PREP) {
        if (base == 16) size -= 2;
        else if (base == 8) size -= 1;
    }

    if (num == 0) {
        tmp[i++] = '0';
    } else {
        while (num) {
            tmp[i++] = dig[num % (unsigned)base];
            num /= (unsigned)base;
        }
    }

    if (i > precision) precision = i;
    size -= precision;

    if (!(type & (ZEROPAD | LEFT))) while (size-- > 0) *str++ = ' ';
    if (sign) *str++ = sign;

    if (type & HEX_PREP) {
        if (base == 8)      *str++ = '0';
        else if (base == 16){ *str++ = '0'; *str++ = (type & UPPERCASE) ? 'X' : 'x'; }
    }

    if (!(type & LEFT)) while (size-- > 0) *str++ = c;
    while (i < precision--) *str++ = '0';
    while (i-- > 0) *str++ = tmp[i];
    while (size-- > 0) *str++ = ' ';

    return str;
}

/* Optional address helpers used by %a/%A in original CoreMark printf */
static char *eaddr(char *str, const unsigned char *addr, int size, int precision, int type) {
    (void)precision;
    const char *dig = (type & UPPERCASE) ? upper_digits : digits;
    char tmp[24]; int len = 0;
    for (int i = 0; i < 6; i++) {
        if (i) tmp[len++] = ':';
        tmp[len++] = dig[addr[i] >> 4];
        tmp[len++] = dig[addr[i] & 0x0F];
    }
    if (!(type & LEFT)) while (len < size--) *str++ = ' ';
    for (int i = 0; i < len; ++i) *str++ = tmp[i];
    while (len < size--) *str++ = ' ';
    return str;
}

static char *iaddr(char *str, const unsigned char *addr, int size, int precision, int type) {
    (void)precision; (void)type;
    char tmp[24]; int len = 0;
    for (int i = 0; i < 4; i++) {
        if (i) tmp[len++] = '.';
        int n = addr[i];
        if (n >= 100) { tmp[len++] = digits[n/100]; n %= 100; tmp[len++] = digits[n/10]; n %= 10; }
        else if (n >= 10) { tmp[len++] = digits[n/10]; n %= 10; }
        tmp[len++] = digits[n];
    }
    if (!(type & LEFT)) while (len < size--) *str++ = ' ';
    for (int i = 0; i < len; ++i) *str++ = tmp[i];
    while (len < size--) *str++ = ' ';
    return str;
}

#if EEPRINTF_HAS_FLOAT
/* -------- float formatting support (uses modf) -------- */
#define CVTBUFSIZE 80
static char *cvt(double arg, int ndigits, int *decpt, int *sign, char *buf, int eflag) {
    int r2 = 0; double fi, fj; char *p = buf, *p1;
    if (ndigits < 0) ndigits = 0;
    if (ndigits >= CVTBUFSIZE - 1) ndigits = CVTBUFSIZE - 2;
    *sign = 0;
    if (arg < 0) { *sign = 1; arg = -arg; }
    arg = modf(arg, &fi);
    p1 = buf + CVTBUFSIZE;

    if (fi != 0) {
        while (fi != 0) {
            fj = modf(fi / 10.0, &fi);
            *--p1 = (int)((fj + 0.03) * 10.0) + '0';
            r2++;
        }
        while (p1 < buf + CVTBUFSIZE) *p++ = *p1++;
    } else if (arg > 0) {
        while ((fj = arg * 10.0) < 1.0) { arg = fj; r2--; }
    }

    char *pend = buf + ndigits + (eflag ? 0 : r2);
    *decpt = r2;
    if (pend < buf) { buf[0] = '\0'; return buf; }

    while (p <= pend && p < buf + CVTBUFSIZE) {
        arg *= 10.0;
        arg = modf(arg, &fj);
        *p++ = (int)fj + '0';
    }
    if (pend >= buf + CVTBUFSIZE) { buf[CVTBUFSIZE - 1] = '\0'; return buf; }

    p = pend;
    *pend += 5;
    while (*pend > '9') {
        *pend = '0';
        if (pend > buf) ++*--pend;
        else { *pend = '1'; (*decpt)++; if (!eflag) { if (p > buf) *p = '0'; p++; } }
    }
    *p = '\0';
    return buf;
}

static char *ecvtbuf(double arg, int ndigits, int *decpt, int *sign, char *buf) {
    return cvt(arg, ndigits, decpt, sign, buf, 1);
}
static char *fcvtbuf(double arg, int ndigits, int *decpt, int *sign, char *buf) {
    return cvt(arg, ndigits, decpt, sign, buf, 0);
}

static void ee_bufcpy(char *d, const char *s, int count) {
    const char *e = s + count; while (s != e) *d++ = *s++;
}

static void parse_float(double value, char *buffer, char fmt, int precision) {
    int decpt, sign, exp, pos, capexp = 0, magnitude;
    char cvtbuf[80], *digs = NULL;

    if (fmt == 'G' || fmt == 'E') { capexp = 1; fmt += 'a' - 'A'; }
    if (fmt == 'g') {
        digs = ecvtbuf(value, precision, &decpt, &sign, cvtbuf);
        magnitude = decpt - 1;
        if (magnitude < -4 || magnitude > precision - 1) { fmt = 'e'; precision -= 1; }
        else { fmt = 'f'; precision -= decpt; }
    }

    if (fmt == 'e') {
        digs = ecvtbuf(value, precision + 1, &decpt, &sign, cvtbuf);
        if (sign) *buffer++ = '-';
        *buffer++ = *digs;
        if (precision > 0) *buffer++ = '.';
        ee_bufcpy(buffer, digs + 1, precision); buffer += precision;
        *buffer++ = capexp ? 'E' : 'e';
        exp = (decpt == 0) ? ((value == 0.0) ? 0 : -1) : (decpt - 1);
        *buffer++ = (exp < 0 ? '-' : '+'); if (exp < 0) exp = -exp;
        buffer[2] = (char)((exp % 10) + '0'); exp /= 10;
        buffer[1] = (char)((exp % 10) + '0'); exp /= 10;
        buffer[0] = (char)((exp % 10) + '0'); buffer += 3;
    } else { /* 'f' */
        digs = fcvtbuf(value, precision, &decpt, &sign, cvtbuf);
        if (sign) *buffer++ = '-';
        if (*digs) {
            if (decpt <= 0) {
                *buffer++ = '0'; *buffer++ = '.';
                for (pos = 0; pos < -decpt; pos++) *buffer++ = '0';
                while (*digs) *buffer++ = *digs++;
            } else {
                pos = 0;
                while (*digs) {
                    if (pos++ == decpt) *buffer++ = '.';
                    *buffer++ = *digs++;
                }
            }
        } else {
            *buffer++ = '0';
            if (precision > 0) { *buffer++ = '.'; for (pos = 0; pos < precision; pos++) *buffer++ = '0'; }
        }
    }
    *buffer = '\0';
}

static void decimal_point(char *b) {
    while (*b) { if (*b == '.') return; if (*b == 'e' || *b == 'E') break; b++; }
    if (*b) {
        int n = (int)strnlen_s(b, 256);
        while (n-- > 0) b[n+1] = b[n];
        *b = '.';
    } else { *b++ = '.'; *b = '\0'; }
}
static void cropzeros(char *b) {
    while (*b && *b != '.') b++;
    if (*b++) {
        char *stop;
        while (*b && *b != 'e' && *b != 'E') b++;
        stop = b--; while (*b == '0') b--; if (*b == '.') b--;
        while (b != stop) *++b = 0;
    }
}

static char *flt(char *str, double num, int size, int precision, char fmt, int flags) {
    char tmp[80], c = (flags & ZEROPAD) ? '0' : ' ', sign = 0;
    int n, i;
    if (flags & LEFT) flags &= ~ZEROPAD;
    if (flags & SIGN) {
        if (num < 0.0) { sign = '-'; num = -num; size--; }
        else if (flags & PLUS) { sign = '+'; size--; }
        else if (flags & SPACE) { sign = ' '; size--; }
    }
    if (precision < 0) precision = 6;
    parse_float(num, tmp, fmt, precision);
    if ((flags & HEX_PREP) && precision == 0) decimal_point(tmp);
    if (fmt == 'g' && !(flags & HEX_PREP)) cropzeros(tmp);
    n = (int)strnlen_s(tmp, 256);
    size -= n;
    if (!(flags & (ZEROPAD | LEFT))) while (size-- > 0) *str++ = ' ';
    if (sign) *str++ = sign;
    if (!(flags & LEFT)) while (size-- > 0) *str++ = c;
    for (i = 0; i < n; i++) *str++ = tmp[i];
    while (size-- > 0) *str++ = ' ';
    return str;
}
#endif /* EEPRINTF_HAS_FLOAT */

/* ========================= Core formatter ========================= */
static int ee_vsprintf(char *buf, const char *fmt, va_list args) {
    char *str = buf;
    for (; *fmt; ++fmt) {
        if (*fmt != '%') { *str++ = *fmt; continue; }

        int flags = 0;
    parse_flags:
        switch (*++fmt) {
            case '-': flags |= LEFT; goto parse_flags;
            case '+': flags |= PLUS; goto parse_flags;
            case ' ': flags |= SPACE; goto parse_flags;
            case '#': flags |= HEX_PREP; goto parse_flags;
            case '0': flags |= ZEROPAD; goto parse_flags;
        }

        int field_width = -1;
        if (is_digit(*fmt)) field_width = skip_atoi(&fmt);
        else if (*fmt == '*') { fmt++; field_width = va_arg(args, int); if (field_width < 0) { field_width = -field_width; flags |= LEFT; } }

        int precision = -1;
        if (*fmt == '.') {
            if (is_digit(*++fmt)) precision = skip_atoi(&fmt);
            else if (*fmt == '*') { fmt++; precision = va_arg(args, int); }
            if (precision < 0) precision = 0;
        }

        int qualifier = -1;
        if (*fmt == 'l' || *fmt == 'L') { qualifier = *fmt; ++fmt; }

        int base = 10;
        switch (*fmt) {
            case 'c': {
                if (!(flags & LEFT)) while (--field_width > 0) *str++ = ' ';
                *str++ = (unsigned char)va_arg(args, int);
                while (--field_width > 0) *str++ = ' ';
                continue;
            }
            case 's': {
                const char *s = va_arg(args, const char *);
                if (!s) s = "<NULL>";
                int len = (int)strnlen_s(s, (precision < 0) ? (ee_size_t)~0u : (ee_size_t)precision);
                if (!(flags & LEFT)) while (len < field_width--) *str++ = ' ';
                for (int i = 0; i < len; ++i) *str++ = *s++;
                while (len < field_width--) *str++ = ' ';
                continue;
            }
            case 'p': {
                if (field_width == -1) { field_width = (int)(2 * sizeof(void *)); flags |= ZEROPAD; }
                str = number(str, (unsigned long)va_arg(args, void *), 16, field_width, precision, flags);
                continue;
            }
            case 'A': flags |= UPPERCASE; /* fallthrough */
            case 'a': {
                if (qualifier == 'l')
                    str = eaddr(str, va_arg(args, unsigned char *), field_width, precision, flags);
                else
                    str = iaddr(str, va_arg(args, unsigned char *), field_width, precision, flags);
                continue;
            }
            case 'o': base = 8;  break;
            case 'X': flags |= UPPERCASE; /* fallthrough */
            case 'x': base = 16; break;
            case 'd': case 'i': flags |= SIGN; /* fallthrough */
            case 'u': break;

#if EEPRINTF_HAS_FLOAT
            case 'f': case 'e': case 'g': case 'E': case 'G': {
                str = flt(str, va_arg(args, double), field_width, precision, *fmt, flags | SIGN);
                continue;
            }
#endif
            default:
                if (*fmt != '%') *str++ = '%';
                if (*fmt) *str++ = *fmt; else --fmt;
                continue;
        }

        unsigned long num;
        if (qualifier == 'l') num = va_arg(args, unsigned long);
        else if (flags & SIGN) num = (unsigned long)va_arg(args, int);
        else num = (unsigned long)va_arg(args, unsigned int);

        str = number(str, num, base, field_width, precision, flags);
    }
    *str = '\0';
    return (int)(str - buf);
}

/* ========================= Public API ========================= */
int ee_printf(const char *fmt, ...) {
    char buf[1024];
    va_list args;
    va_start(args, fmt);
    ee_vsprintf(buf, fmt, args);
    va_end(args);

    int n = 0;
    for (char *p = buf; *p; ++p) { EE_PUTC(*p); n++; }
    return n;
}


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
  ee_printf("  %%04x: %04x\n", 0u);
  ee_printf("  %%04x: %04x\n", 1u);
  ee_printf("  %%04x: %04x\n", 0xABu);
  ee_printf("  %%04x: %04x\n", 0x1234u);
  ee_printf("  %%08x: %08x\n", 0u);
  ee_printf("  %%08x: %08x\n", 0x1u);
  ee_printf("  %%08x: %08x\n", 0xABCDu);
  ee_printf("  %%08x: %08x\n", 0x89ABCDEFu);
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
  core_halt();
  /* If core ignores HALT, just spin */
  for (;;);
  return 0;
}
