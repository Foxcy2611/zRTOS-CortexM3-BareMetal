# -----------------------------------------------------------------------------
# File: CMakeLists.txt
# Vai trò:
#   Entry point của hệ thống build zRTOS.
#
# File này cấu hình project và kết nối các subsystem:
#   libraries -> port -> kernel -> BSP -> examples/tests.
#
# Chi tiết build của từng subsystem nằm trong CMakeLists.txt tương ứng.
# -----------------------------------------------------------------------------

cmake_minimum_required(VERSION 3.24)

project(
    zRTOS
    VERSION 0.1.0
    LANGUAGES C ASM
)

# -----------------------------------------------------------------------------
# Chuẩn ngôn ngữ
# -----------------------------------------------------------------------------

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

# Hữu ích cho VS Code, clangd và các tool phân tích source.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# -----------------------------------------------------------------------------
# Tùy chọn project
# -----------------------------------------------------------------------------

option(
    ZRTOS_BUILD_HOST_TESTS
    "Chỉ build các test chạy trên máy host"
    OFF
)

option(
    ZRTOS_BUILD_EXAMPLES
    "Build các firmware example của zRTOS"
    ON
)

option(
    ZRTOS_BUILD_TESTS
    "Build các bài kiểm thử của zRTOS"
    ON
)

option(
    ZRTOS_ENABLE_KERNEL
    "Build Cortex-M3 port, kernel và các example RTOS (Phase 3+)"
    OFF
)

# -----------------------------------------------------------------------------
# Compiler options dùng chung
# -----------------------------------------------------------------------------

include(
    "${PROJECT_SOURCE_DIR}/cmake/compiler_options.cmake"
)

# -----------------------------------------------------------------------------
# Host test build
#
# Host test không cần CMSIS, SPL, BSP, startup hay Cortex-M3 port.
# -----------------------------------------------------------------------------

if(ZRTOS_BUILD_HOST_TESTS)

    add_subdirectory(tests)

    return()

endif()

# -----------------------------------------------------------------------------
# Embedded firmware build
# -----------------------------------------------------------------------------

include(
    "${PROJECT_SOURCE_DIR}/cmake/zrtos_firmware.cmake"
)

# Third-party libraries
add_subdirectory(libraries)

# Phase 0 chưa có source của port/kernel; chỉ thêm các target này từ Phase 3.
if(ZRTOS_ENABLE_KERNEL)
    add_subdirectory(port/cortex_m3)
    add_subdirectory(kernel)
endif()

# STM32F103C8T6 board support
add_subdirectory(bsp)

# -----------------------------------------------------------------------------
# Examples
# -----------------------------------------------------------------------------

if(ZRTOS_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

# -----------------------------------------------------------------------------
# Tests chạy trên target
# -----------------------------------------------------------------------------

if(ZRTOS_BUILD_TESTS)
    add_subdirectory(tests)
endif()
