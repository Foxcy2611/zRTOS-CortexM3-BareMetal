#include <stdint.h>

#include "bsp_gpio.h"

static void delay_loop(volatile uint32_t count){
    while (count--){
        __asm volatile ("nop");
    }
}

int main(){
    const bsp_gpio_config_t led = {
        .port   = BSP_GPIO_PORT_C,

        .pin    = BSP_GPIO_PIN_13,
        .mode   = BSP_GPIO_MODE_OUTPUT_PP,
        .speed  = BSP_GPIO_SPEED_50MHZ
    };

    bsp_gpio_configure(&led);

    while(1){
        bsp_gpio_toggle(led.port, led.pin);
        delay_loop(500000U);
    }
}