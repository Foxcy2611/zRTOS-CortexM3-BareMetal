# -----------------------------------------------------------------------------
# File: examples/CMakeLists.txt
# Vai trò:
#   Tạo các firmware demo dùng để kiểm chứng từng milestone của zRTOS.
#
# Mỗi example là một firmware độc lập và được build thành ELF/HEX/BIN riêng.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Phase 0 - BSP smoke test
# Chỉ kiểm tra startup, linker, clock, GPIO và UART.
# Chưa sử dụng zRTOS kernel.
# -----------------------------------------------------------------------------

zrtos_add_firmware(
    NAME zrtos_bsp_smoke

    SOURCES
        0_bsp_smoke/main.c

    LIBRARIES
        zrtos_bsp_stm32f103c8t6
)

# -----------------------------------------------------------------------------
# Phase 3 - Chạy task đầu tiên bằng SVC + PSP
# -----------------------------------------------------------------------------

if(ZRTOS_ENABLE_KERNEL)

zrtos_add_firmware(
    NAME zrtos_first_task

    SOURCES
        01_first_task/main.c

    LIBRARIES
        zrtos_kernel
        zrtos_port_cortex_m3
        zrtos_bsp_stm32f103c8t6
)

# -----------------------------------------------------------------------------
# Phase 4 - Context switch / cooperative scheduler
# -----------------------------------------------------------------------------

zrtos_add_firmware(
    NAME zrtos_context_switch

    SOURCES
        02_context_switch/main.c

    LIBRARIES
        zrtos_kernel
        zrtos_port_cortex_m3
        zrtos_bsp_stm32f103c8t6
)

# -----------------------------------------------------------------------------
# Phase 5+ - Preemptive scheduler demo
# -----------------------------------------------------------------------------

zrtos_add_firmware(
    NAME zrtos_scheduler_demo

    SOURCES
        03_scheduler/main.c

    LIBRARIES
        zrtos_kernel
        zrtos_port_cortex_m3
        zrtos_bsp_stm32f103c8t6
)

endif()
