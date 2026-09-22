# -----------------------------------------------------------------------------
# File: compiler_options.cmake
# Vai trò:
#   Khai báo các tùy chọn compile/link chung cho zRTOS trên ARM Cortex-M3.
#
# File này quản lý:
#   - Kiến trúc CPU và instruction set.
#   - Warning của compiler.
#   - Tối ưu hóa theo Debug/Release.
#   - Tách function/data section để linker có thể loại bỏ code không dùng.
#
# File này không quản lý:
#   - Cross-compiler/toolchain.
#   - Linker script.
#   - Source của kernel/BSP/port.
#   - Việc tạo firmware ELF/HEX/BIN.
# -----------------------------------------------------------------------------

add_library(zrtos_compiler_options INTERFACE)

# -----------------------------------------------------------------------------
# Kiến trúc CPU
# -----------------------------------------------------------------------------

target_compile_options(zrtos_compiler_options INTERFACE
    $<$<COMPILE_LANGUAGE:C>:
        -mcpu=cortex-m3
        -mthumb
    >

    $<$<COMPILE_LANGUAGE:ASM>:
        -mcpu=cortex-m3
        -mthumb
    >
)

target_link_options(zrtos_compiler_options INTERFACE
    -mcpu=cortex-m3
    -mthumb
)

# -----------------------------------------------------------------------------
# Quy tắc compile C
# -----------------------------------------------------------------------------

target_compile_options(zrtos_compiler_options INTERFACE
    $<$<COMPILE_LANGUAGE:C>:
        -ffreestanding          # Báo GCC đây là env Bare-Metal
        -ffunction-sections     # Mỗi function đc đưa vào 1 section riêng
        
        -fdata-sections         # Tương tự nhưng cho global/static data
        -fno-common             # Bắt các lỗi khai báo/định nghĩa ko rõ

        -Wall                   # Bật nhóm warning phổ biến
        -Wextra                 # Bật thêm warning
        -Wpedantic              # Cảnh báo code ko tuân thủ C 
        -Wshadow                # Cảnh báo Variable bên trong che Vari ngoài
        -Wundef                 # Cảnh báo khi dùng macro chưa define trong #if
        -Wformat=2              # Kiểm tra mạnh hơn các format string như printf()
        -Wdouble-promotion      # Cảnh báo float -> double
    >
)

# -----------------------------------------------------------------------------
# Tối ưu hóa theo cấu hình build
# -----------------------------------------------------------------------------

target_compile_options(zrtos_compiler_options INTERFACE
    $<$<CONFIG:Debug>:-Og>          # -Og: Có tối ưu nhưng vẫn ưu tiên khả năng debug
    $<$<CONFIG:Debug>:-g3>          # -g3: Sinh debug information đầy đủ cho GDB

    $<$<CONFIG:Release>:-Os>

    $<$<CONFIG:RelWithDebInfo>:-Os>
    $<$<CONFIG:RelWithDebInfo>:-g3>
)

# Release không cần assert chuẩn của C library.
target_compile_definitions(zrtos_compiler_options INTERFACE
    $<$<CONFIG:Release>:NDEBUG>     # Thường vô hiệu hóa assert() chuẩn trong Release
)

# -----------------------------------------------------------------------------
# Linker options chung
# -----------------------------------------------------------------------------

target_link_options(zrtos_compiler_options INTERFACE
    -Wl,--gc-sections       # Bảo linker bỏ function/data section không được sử dụng
)