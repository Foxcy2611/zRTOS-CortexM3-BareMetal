# Libraries

Thư mục này chỉ chứa mã nguồn và tài liệu được nhập từ bên thứ ba. Code do
zRTOS phát triển phải nằm trong module sở hữu tương ứng (`kernel/`, `port/`,
`bsp/` hoặc `examples/`).

## Thành phần

```text
libraries/
├── documentation/
│   ├── CMSIS/
│   └── STM32F10x_StdPeriph_Driver/
├── CMSIS/
│   └── CM3/
│       ├── CoreSupport/
│       └── DeviceSupport/ST/STM32F10x/
└── STM32F10x_StdPeriph_Driver/
    ├── inc/
    ├── src/
    └── templates/
```

- `CMSIS/` chứa CMSIS-Core và device support cho STM32F10x.
- `STM32F10x_StdPeriph_Driver/` chứa STM32F10x Standard Peripheral Library
  (SPL) V3.5.0.
- `documentation/` chứa license, release notes và tài liệu đi kèm, được phân
  nhóm theo dependency để giữ khả năng truy vết nguồn gốc.
- `templates/` lưu nguyên các project template tham khảo của ST. Các file trong
  đây không phải source đang hoạt động và không được đưa tự động vào firmware.

File `system_stm32f10x.c` chuẩn được lấy trực tiếp từ
`CMSIS/CM3/DeviceSupport/ST/STM32F10x/`; không duy trì thêm bản sao ở root của
`libraries/`.

## Ranh giới tích hợp

- Cấu hình SPL dành cho target hiện tại nằm tại
  `bsp/stm32f103c8t6/include/stm32f10x_conf.h`.
- Handler `SVC`, `PendSV` và `SysTick` của kernel thuộc `port/cortex_m3/`, không
  lấy từ project template của ST.
- BSP có thể phụ thuộc CMSIS/SPL; `kernel/` không được include SPL.
- CMake phải chọn rõ source SPL thực sự dùng, không glob toàn bộ `src/` mặc định.

Thông tin phiên bản và license được tổng hợp tại
[`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md). Copyright/header gốc của
vendor phải được giữ nguyên. Không sửa nội dung các file trong `documentation/`.
