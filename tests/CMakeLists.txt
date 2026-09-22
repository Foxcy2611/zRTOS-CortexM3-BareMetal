# -----------------------------------------------------------------------------
# File: tests/CMakeLists.txt
# Vai trò:
#   Quản lý các bài kiểm thử của zRTOS.
#
# Host test dùng compiler của máy tính để kiểm tra logic portable.
# +) Test chạy trên laptop
# +) Test logic thuần C, nhanh, dễ chạy
#
# Target test được build thành firmware và chạy trên STM32F103C8T6.
# +) Test chạy trên mạch
# +) STM32 chạy, test behavior thật của RTOS
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Host tests
# -----------------------------------------------------------------------------

if(NOT CMAKE_CROSSCOMPILING)

    enable_testing()

    # Ví dụ khi bắt đầu có test:
    #
    # add_executable(zrtos_test_list
    #     host/test_list.c
    #     "${PROJECT_SOURCE_DIR}/kernel/zrtos_list.c"
    # )
    #
    # target_include_directories(zrtos_test_list PRIVATE
    #     "${PROJECT_SOURCE_DIR}/kernel/internal"
    # )
    #
    # add_test(
    #     NAME zrtos_test_list
    #     COMMAND zrtos_test_list
    # )

    return()

endif()

# -----------------------------------------------------------------------------
# Target tests
# -----------------------------------------------------------------------------

# Các test phụ thuộc Cortex-M3 sẽ được thêm dần theo ROADMAP.
#
# Ví dụ:
#
# zrtos_add_firmware(
#     NAME zrtos_test_context_switch
#
#     SOURCES
#         target/context_switch/main.c
#
#     LIBRARIES
#         zrtos_kernel
#         zrtos_port_cortex_m3
#         zrtos_bsp_stm32f103c8t6
# )