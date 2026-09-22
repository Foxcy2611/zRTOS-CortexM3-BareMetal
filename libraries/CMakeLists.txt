# -----------------------------------------------------------------------------
# File: libraries/CMakeLists.txt
# Vai trò:
#   Khai báo các thư viện third-party được sử dụng bởi zRTOS.
#
# File này quản lý:
#   - CMSIS cho ARM Cortex-M3 và STM32F10x.
#   - STM32F10x Standard Peripheral Library (SPL).
#   - Include path và device definition cần thiết cho STM32F103C8T6.
#
# File này không quản lý:
#   - BSP của project.
#   - Startup code và linker script.
#   - Kernel hoặc Cortex-M3 port của zRTOS.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Đường dẫn thư viện
# -----------------------------------------------------------------------------

set(ZRTOS_CMSIS_ROOT
    "${CMAKE_CURRENT_SOURCE_DIR}/CMSIS/CM3"
)

set(ZRTOS_CMSIS_CORE_DIR
    "${ZRTOS_CMSIS_ROOT}/CoreSupport"
)

set(ZRTOS_CMSIS_DEVICE_DIR
    "${ZRTOS_CMSIS_ROOT}/DeviceSupport/ST/STM32F10x"
)

set(ZRTOS_SPL_ROOT
    "${CMAKE_CURRENT_SOURCE_DIR}/STM32F10x_StdPeriph_Driver"
)

set(ZRTOS_SPL_INC_DIR
    "${ZRTOS_SPL_ROOT}/inc"
)

set(ZRTOS_SPL_SRC_DIR
    "${ZRTOS_SPL_ROOT}/src"
)

# -----------------------------------------------------------------------------
# CMSIS
# -----------------------------------------------------------------------------

# PUBLIC: Thuộc tính này áp dụng target hiện tại và đc truyền tiếp target kế nếu cx phụ thuộc nó
# Ví dụ b include a (a có PUBLIC), nếu c include b thì cx có thể dùng đc a

# PRIVATE: Chỉ áp dụng target hiện tại

# INTERFACE: Target này k tự dùng thứ đó, nhưng ai link tới nó sẽ được dùng
# Thường áp dụng cho các file cấu hình chung (Vdu: shared/)

set(ZRTOS_CMSIS_SOURCES
    "${ZRTOS_CMSIS_DEVICE_DIR}/system_stm32f10x.c"
)

# Phase 0 chỉ cần device startup/clock. Core intrinsics để dành cho port/kernel.
if(ZRTOS_ENABLE_KERNEL)
    list(APPEND ZRTOS_CMSIS_SOURCES
        "${ZRTOS_CMSIS_CORE_DIR}/core_cm3.c"
    )
endif()

add_library(zrtos_cmsis STATIC ${ZRTOS_CMSIS_SOURCES})

target_include_directories(zrtos_cmsis
    SYSTEM PUBLIC
        "${ZRTOS_CMSIS_CORE_DIR}"
        "${ZRTOS_CMSIS_DEVICE_DIR}"
)

# STM32F103C8T6 thuộc nhóm STM32F10x Medium Density.
target_compile_definitions(zrtos_cmsis
    PUBLIC
        STM32F10X_MD        # medium-density
)

target_link_libraries(zrtos_cmsis
    PRIVATE
        zrtos_compiler_options
)

# -----------------------------------------------------------------------------
# STM32F10x Standard Peripheral Library
# -----------------------------------------------------------------------------

add_library(zrtos_spl STATIC
    "${ZRTOS_SPL_SRC_DIR}/misc.c"
    "${ZRTOS_SPL_SRC_DIR}/stm32f10x_rcc.c"
    "${ZRTOS_SPL_SRC_DIR}/stm32f10x_gpio.c"
    "${ZRTOS_SPL_SRC_DIR}/stm32f10x_usart.c"
    "${ZRTOS_SPL_SRC_DIR}/stm32f10x_adc.c"
    "${ZRTOS_SPL_SRC_DIR}/stm32f10x_dma.c"
)

target_include_directories(zrtos_spl
    SYSTEM PUBLIC
        "${ZRTOS_SPL_INC_DIR}"

    PRIVATE
        "${PROJECT_SOURCE_DIR}/bsp/stm32f103c8t6/inc"
)

target_compile_definitions(zrtos_spl
    PRIVATE
        USE_STDPERIPH_DRIVER
)

target_link_libraries(zrtos_spl
    PUBLIC
        zrtos_cmsis

    PRIVATE
        zrtos_compiler_options
)
