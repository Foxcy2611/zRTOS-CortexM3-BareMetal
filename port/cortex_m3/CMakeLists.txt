# -----------------------------------------------------------------------------
# File: port/cortex_m3/CMakeLists.txt
# Vai trò:
#   Build phần port của zRTOS dành riêng cho ARM Cortex-M3.
#
# Port xử lý các cơ chế phụ thuộc CPU như SVC, PendSV, PSP/MSP,
# context switch và interrupt control.
#
# Port chỉ phụ thuộc CMSIS, không phụ thuộc BSP hoặc STM32 SPL.
# -----------------------------------------------------------------------------

add_library(zrtos_port_cortex_m3 STATIC
    # zrtos_port.c
    # zrtos_portasm.S
)

target_include_directories(zrtos_port_cortex_m3
    PUBLIC
        "${CMAKE_CURRENT_SOURCE_DIR}"
)

target_link_libraries(zrtos_port_cortex_m3
    PRIVATE
        zrtos_cmsis
        zrtos_compiler_options
)