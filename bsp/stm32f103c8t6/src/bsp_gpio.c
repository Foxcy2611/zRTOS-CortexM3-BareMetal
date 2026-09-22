#include "bsp_gpio.h"

#include "stm32f10x.h"
#include "stm32f10x_gpio.h"
#include "stm32f10x_rcc.h"

#include <stddef.h>

// -------------------- HELPER -------------------- //
static GPIO_TypeDef *bsp_gpio_get_port(bsp_gpio_port_t port){
    switch(port){
        case BSP_GPIO_PORT_A: return GPIOA;
        case BSP_GPIO_PORT_B: return GPIOB;
        case BSP_GPIO_PORT_C: return GPIOC;
        default:              return NULL;
    }
}

static void bsp_gpio_enable_clock(bsp_gpio_port_t port){
    switch(port){
        case BSP_GPIO_PORT_A:
            RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);
            break;

        case BSP_GPIO_PORT_B:
            RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOB, ENABLE);
            break;

        case BSP_GPIO_PORT_C:
            RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOC, ENABLE);
            break;

        default:
            break;
    }
}
void bsp_gpio_configure(const bsp_gpio_config_t *config){
    GPIO_InitTypeDef gpio;
    GPIO_TypeDef *port;

    port = bsp_gpio_get_port(config->port);

    if(port == NULL){
        return;
    }

    bsp_gpio_enable_clock(config->port);

    gpio.GPIO_Pin = config->pin;
    gpio.GPIO_Mode = (GPIOMode_TypeDef)config->mode;
    gpio.GPIO_Speed = (GPIOMode_TypeDef)config->speed;
    GPIO_Init(port, &gpio);
}

void bsp_gpio_write(
    bsp_gpio_port_t port,
    bsp_gpio_pin_t pin,
    bsp_gpio_state_t state
){
    GPIO_TypeDef *port_gpio = bsp_gpio_get_port(port);

    if(port_gpio == NULL) return;

    GPIO_WriteBit(port_gpio, (uint16_t)pin, (BitAction)state);
}

bsp_gpio_state_t bsp_gpio_read(
    bsp_gpio_port_t port,
    bsp_gpio_pin_t pin
){
    GPIO_TypeDef *port_gpio = bsp_gpio_get_port(port);

    if(port_gpio == NULL) BSP_GPIO_LOW;

    return GPIO_ReadInputDataBit(port_gpio, (uint16_t)pin)
        ? BSP_GPIO_HIGH 
        : BSP_GPIO_LOW;
}

void bsp_gpio_toggle(
    bsp_gpio_port_t port,
    bsp_gpio_pin_t pin
){
    GPIO_TypeDef *port_gpio = bsp_gpio_get_port(port);

    if (port_gpio == NULL){
        return;
    }

    if (GPIO_ReadOutputDataBit(port_gpio, (uint16_t)pin) != Bit_RESET){
        GPIO_ResetBits(port_gpio, (uint16_t)pin);
    } else {
        GPIO_SetBits(port_gpio, (uint16_t)pin);
    }
}