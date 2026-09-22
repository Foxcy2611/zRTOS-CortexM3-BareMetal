# -----------------------------------------------------------------------------
# File: arm-none-eabi-toolchain.cmake
# Role: Cấu hình bộ công cụ biên dịch chéo (cross-toolchain) GNU Arm Embedded được 
# sử dụng để xây dựng firmware zRTOS cho các mục tiêu ARM Cortex-M.

# Tệp này chỉ chọn các công cụ xây dựng. Các cờ CPU và tùy chọn cảnh báo/tối ưu hóa 
# được định nghĩa riêng trong tệp compiler_options.cmake.
# -----------------------------------------------------------------------------
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# GNU Arm Embedded toolchain
find_program(ARM_GCC
    arm-none-eabi-gcc
    REQUIRED
)

find_program(ARM_AR
    arm-none-eabi-ar
    REQUIRED
)

find_program(ARM_OBJCOPY
    arm-none-eabi-objcopy
    REQUIRED
)

find_program(ARM_OBJDUMP
    arm-none-eabi-objdump
    REQUIRED
)

find_program(ARM_SIZE
    arm-none-eabi-size
    REQUIRED
)

# Compilers
set(CMAKE_C_COMPILER   "${ARM_GCC}")
set(CMAKE_ASM_COMPILER "${ARM_GCC}")

# Binutils
set(CMAKE_AR      "${ARM_AR}")
set(CMAKE_OBJCOPY "${ARM_OBJCOPY}")
set(CMAKE_OBJDUMP "${ARM_OBJDUMP}")
set(CMAKE_SIZE    "${ARM_SIZE}")