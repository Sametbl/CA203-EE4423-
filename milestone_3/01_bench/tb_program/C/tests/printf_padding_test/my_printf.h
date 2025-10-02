#ifndef MY_PRINTF_H
#define MY_PRINTF_H

#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>

/* =========================================================================
 *  Minimal standalone ee_printf header
 *  - Supports basic formatted printing to UART or custom sink
 *  - Default UART TX register: 0x70000000
 *  - Float support can be toggled via EEPRINTF_HAS_FLOAT
 * ========================================================================= */

#ifdef __cplusplus
extern "C" {
#endif

/* =========================================================================
 *  Configuration Macros
 * ========================================================================= */

/* Define UART TX register if not already defined */
#ifndef UART_TX_ADDR
#define UART_TX_ADDR ((volatile uint8_t *)0x70000000u)
#endif

/* Enable/disable floating point printing support */
#ifndef EEPRINTF_HAS_FLOAT
#define EEPRINTF_HAS_FLOAT 0
#endif

/* If you want to override the UART output, define EE_PUTC(c) */
#ifndef EE_PUTC
#define EE_PUTC(c) uart_send_char((c))
#endif

/* =========================================================================
 *  Public API
 * ========================================================================= */

/**
 * @brief Sends a single character via UART.
 * 
 * You can override this function by redefining EE_PUTC in your project.
 */
void uart_send_char(char c);

/**
 * @brief Formatted output function, similar to printf().
 * 
 * Supports basic format specifiers: %c, %s, %d, %i, %u, %x, %X, %o, %p.
 * Optionally supports %f, %e, %E, %g, %G if EEPRINTF_HAS_FLOAT = 1.
 * 
 * @param fmt   The format string
 * @param ...   Arguments matching the format specifiers
 * @return int  Number of characters printed
 */
int ee_printf(const char *fmt, ...);

#ifdef __cplusplus
}
#endif

#endif /* EE_PRINTF_H */
