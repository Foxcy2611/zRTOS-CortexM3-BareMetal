#ifndef ZRTOS_BSP_UART_H
#define ZRTOS_BSP_UART_H

#include <stddef.h>
#include <stdint.h>

void bsp_uart_init(uint32_t baudrate);

void bsp_uart_write_byte(uint8_t byte);

void bsp_uart_write(
    const uint8_t *data,
    size_t length
);

void bsp_uart_write_string(
    const char *string
);

#endif /* ZRTOS_BSP_UART_H */
