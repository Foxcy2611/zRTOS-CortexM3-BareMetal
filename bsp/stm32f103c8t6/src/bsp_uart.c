#include "bsp_uart.h"

#include "bsp_gpio.h"

#include "stm32f10x_rcc.h"
#include "stm32f10x_usart.h"

void bsp_uart_init(uint32_t baudrate){
    const bsp_gpio_config_t tx_pin = {
        .port   = BSP_GPIO_PORT_A,
        .pin    = BSP_GPIO_PIN_9,
        .speed  = BSP_GPIO_SPEED_50MHZ,
        .mode   = BSP_GPIO_MODE_AF_PP
    };
    
    bsp_gpio_configure(&tx_pin);

    USART_InitTypeDef usart;
    RCC_APB2PeriphClockCmd(RCC_APB2Periph_USART1, ENABLE);

    usart.USART_BaudRate = baudrate;
    usart.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
    usart.USART_Mode = USART_Mode_Rx | USART_Mode_Tx;
    usart.USART_Parity = USART_Parity_No;
    usart.USART_StopBits = USART_StopBits_1;
    usart.USART_WordLength = USART_WordLength_8b;
    USART_Init(USART1, &usart);

    USART_Cmd(USART1, ENABLE);
}

void bsp_uart_write_byte(uint8_t byte){
    while(USART_GetFlagStatus(USART1, USART_FLAG_TXE) == RESET);

    USART_SendData(USART1, (uint16_t)byte);
}

void bsp_uart_write(
    const uint8_t *data,
    size_t length
){
    if (data == NULL){
        return;
    }

    for (size_t i = 0; i < length; ++i){
        bsp_uart_write_byte(data[i]);
    }
}

void bsp_uart_write_string(
    const char *string
){
    if(string == NULL){
        return;
    }

    while(*string != '\0'){
        bsp_uart_write_byte((uint8_t)*string);
        ++string;
    }
}