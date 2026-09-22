# -----------------------------------------------------------------------------
# File: zrtos_firmware.cmake
# Vai trò:
#   Cung cấp helper để tạo một firmware STM32F103C8T6 hoàn chỉnh.
#
# Helper này nhận main.c + các lib cần dùng, startup code, linker script, 
# ELF/HEX/BIN/MAP và hiển thị kích thước firmware sau khi build.
# -----------------------------------------------------------------------------

include(CMakeParseArguments) 

# Tạo hàm riêng để khỏi lặp lại đoạn tạo file output cho từng example
function(zrtos_add_firmware) 

    set(options)
    set(oneValueArgs
        NAME
    )
    set(multiValueArgs
        SOURCES
        LIBRARIES
    )

    cmake_parse_arguments(
        ZFW
        "${options}"
        "${oneValueArgs}"
        "${multiValueArgs}"
        ${ARGN}
    )

    if(NOT ZFW_NAME)
        message(FATAL_ERROR
            "zrtos_add_firmware(): thiếu tham số NAME"
        )
    endif()

    # -------------------------------------------------------------------------
    # Tạo firmware ELF
    # -------------------------------------------------------------------------

    add_executable(${ZFW_NAME}
        ${ZFW_SOURCES}
        "${ZRTOS_STARTUP_SOURCE}"
    )

    set_target_properties(${ZFW_NAME}
        PROPERTIES
            SUFFIX ".elf"
    )

    # -------------------------------------------------------------------------
    # Các library firmware sử dụng
    # -------------------------------------------------------------------------

    target_link_libraries(${ZFW_NAME}
        PRIVATE
            zrtos_compiler_options
            ${ZFW_LIBRARIES}
    )

    # -------------------------------------------------------------------------
    # Linker script
    # -------------------------------------------------------------------------

    target_link_options(${ZFW_NAME}
        PRIVATE
            -nostartfiles
            "-T${ZRTOS_LINKER_SCRIPT}"

            "-Wl,-Map=${CMAKE_CURRENT_BINARY_DIR}/${ZFW_NAME}.map"
            "-Wl,--gc-sections"
            "-Wl,--print-memory-usage"
    )

    # -------------------------------------------------------------------------
    # Sinh HEX và BIN sau khi link ELF thành công
    # -------------------------------------------------------------------------

    add_custom_command(
        TARGET ${ZFW_NAME}
        POST_BUILD

        COMMAND
            ${CMAKE_OBJCOPY}
            -O ihex
            $<TARGET_FILE:${ZFW_NAME}>
            "${CMAKE_CURRENT_BINARY_DIR}/${ZFW_NAME}.hex"

        COMMAND
            ${CMAKE_OBJCOPY}
            -O binary
            $<TARGET_FILE:${ZFW_NAME}>
            "${CMAKE_CURRENT_BINARY_DIR}/${ZFW_NAME}.bin"

        COMMAND
            ${CMAKE_SIZE}
            $<TARGET_FILE:${ZFW_NAME}>

        COMMENT
            "Tạo HEX/BIN và kiểm tra kích thước ${ZFW_NAME}"
    )

endfunction()