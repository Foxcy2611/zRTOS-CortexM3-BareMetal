# -----------------------------------------------------------------------------
# File: bsp/CMakeLists.txt
# Vai trò:
#   Build Board Support Package cho STM32F103C8T6.
#
# BSP quản lý peripheral và cấu hình phần cứng của board.
# BSP được phép sử dụng CMSIS và STM32 SPL.
# -----------------------------------------------------------------------------

add_library(zrtos_bsp_stm32f103c8t6 STATIC
    stm32f103c8t6/src/bsp_gpio.c
    stm32f103c8t6/src/bsp_uart.c
)

target_include_directories(zrtos_bsp_stm32f103c8t6
    PUBLIC
        "${CMAKE_CURRENT_SOURCE_DIR}/stm32f103c8t6/inc"
)

target_compile_definitions(zrtos_bsp_stm32f103c8t6
    PUBLIC
        USE_STDPERIPH_DRIVER
)

target_link_libraries(zrtos_bsp_stm32f103c8t6
    PUBLIC
        zrtos_spl
        zrtos_cmsis

    PRIVATE
        zrtos_compiler_options
)

# Startup code và linker script dùng khi tạo firmware executable.
set(ZRTOS_STARTUP_SOURCE
    "${CMAKE_CURRENT_SOURCE_DIR}/startup_code/startup_f103c8t6.S"
    PARENT_SCOPE
)

set(ZRTOS_LINKER_SCRIPT
    "${CMAKE_CURRENT_SOURCE_DIR}/linker_script/linker_f103c8t6.ld"
    PARENT_SCOPE
)