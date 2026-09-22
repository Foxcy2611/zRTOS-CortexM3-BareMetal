#ifndef ZRTOS_BSP_GPIO_H
#define ZRTOS_BSP_GPIO_H

#include <stdint.h>
#include <stdbool.h>

typedef enum {
    BSP_GPIO_PORT_A,
    BSP_GPIO_PORT_B,
    BSP_GPIO_PORT_C
} bsp_gpio_port_t;

typedef enum {
    BSP_GPIO_PIN_0  = (1U << 0),
    BSP_GPIO_PIN_1  = (1U << 1),
    BSP_GPIO_PIN_2  = (1U << 2),
    BSP_GPIO_PIN_3  = (1U << 3),
    BSP_GPIO_PIN_4  = (1U << 4),
    BSP_GPIO_PIN_5  = (1U << 5),
    BSP_GPIO_PIN_6  = (1U << 6),
    BSP_GPIO_PIN_7  = (1U << 7),
    BSP_GPIO_PIN_8  = (1U << 8),
    BSP_GPIO_PIN_9  = (1U << 9),
    BSP_GPIO_PIN_10 = (1U << 10),
    BSP_GPIO_PIN_11 = (1U << 11),
    BSP_GPIO_PIN_12 = (1U << 12),
    BSP_GPIO_PIN_13 = (1U << 13),
    BSP_GPIO_PIN_14 = (1U << 14),
    BSP_GPIO_PIN_15 = (1U << 15)
} bsp_gpio_pin_t;

typedef enum {
    BSP_GPIO_MODE_ANALOG         = 0x00,
    BSP_GPIO_MODE_INPUT_FLOATING = 0x04,
    BSP_GPIO_MODE_INPUT_PULLDOWN = 0x28,
    BSP_GPIO_MODE_INPUT_PULLUP   = 0x48,

    BSP_GPIO_MODE_OUTPUT_OD      = 0x14,
    BSP_GPIO_MODE_OUTPUT_PP      = 0x10,

    BSP_GPIO_MODE_AF_OD          = 0x1C,
    BSP_GPIO_MODE_AF_PP          = 0x18
} bsp_gpio_mode_t;

typedef enum {
    BSP_GPIO_SPEED_10MHZ = 0x01,
    BSP_GPIO_SPEED_2MHZ  = 0x02,
    BSP_GPIO_SPEED_50MHZ = 0x03
} bsp_gpio_speed_t;

typedef enum {
    BSP_GPIO_LOW = 0,
    BSP_GPIO_HIGH
} bsp_gpio_state_t;


// ------ CONFIG GPIO ------ //
typedef struct {
    bsp_gpio_port_t  port;

    bsp_gpio_pin_t   pin;
    bsp_gpio_mode_t  mode;
    bsp_gpio_speed_t speed;
} bsp_gpio_config_t;

// Cấu hình 1 GPIO
void bsp_gpio_configure(const bsp_gpio_config_t *config);

// Ghi 1 bit vào 1 chân
void bsp_gpio_write(
    bsp_gpio_port_t port,
    bsp_gpio_pin_t pin,
    bsp_gpio_state_t state
);

bsp_gpio_state_t bsp_gpio_read(
    bsp_gpio_port_t port,
    bsp_gpio_pin_t pin
);

void bsp_gpio_toggle(
    bsp_gpio_port_t port,
    bsp_gpio_pin_t pin
);

#endif /* ZRTOS_BSP_GPIO_H */