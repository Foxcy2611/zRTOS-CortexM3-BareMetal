# -----------------------------------------------------------------------------
# File: kernel/CMakeLists.txt
# Vai trò:
#   Build phần kernel cốt lõi của zRTOS.
#
# Kernel chứa task, scheduler, timing, IPC và synchronization.
# Kernel không được phụ thuộc STM32 SPL hoặc BSP.
# -----------------------------------------------------------------------------

add_library(zrtos_kernel STATIC
    # zrtos_kernel.c
    # zrtos_task.c
    # zrtos_scheduler.c
    # zrtos_list.c
    # zrtos_time.c
    # zrtos_sem.c
    # zrtos_queue.c
    # zrtos_mutex.c
    # zrtos_diagnostics.c
)

target_include_directories(zrtos_kernel
    PUBLIC
        "${PROJECT_SOURCE_DIR}/include"

    PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}"
        "${CMAKE_CURRENT_SOURCE_DIR}/internal"
)

target_link_libraries(zrtos_kernel
    PRIVATE
        zrtos_port_cortex_m3
        zrtos_compiler_options
)