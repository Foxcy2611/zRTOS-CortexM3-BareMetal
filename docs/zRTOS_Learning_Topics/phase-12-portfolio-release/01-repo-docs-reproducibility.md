# Bài 12.1 — Repository Architecture, Documentation và Reproducibility

> **Phạm vi:** Đóng zRTOS thành repository có module boundaries, docs hierarchy và clean-clone build.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không yêu cầu CI/CD cloud hoặc package manager.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-git-release-cv.md)

---

## Mục lục

- [1. Repository là một phần của sản phẩm kỹ thuật](#1-repository-là-một-phần-của-sản-phẩm-kỹ-thuật)
- [2. Documentation hierarchy](#2-documentation-hierarchy)
- [3. Reproducible build](#3-reproducible-build)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Repository là một phần của sản phẩm kỹ thuật

Kernel source tốt nhưng repository khó đọc, khó build hoặc lẫn trách nhiệm sẽ làm reviewer khó đánh giá. Tree của repo phải phản ánh architecture thật.

### Module boundaries

`kernel/` giữ logic RTOS; `port/` giữ Cortex-M3 specifics; `bsp/` giữ STM32 peripheral; `include/` là public API.

### Không tạo file rỗng để làm đẹp

Module chỉ xuất hiện khi có responsibility và implementation thật.

### Tests và examples

Tests chứng minh behavior; examples chứng minh cách dùng API.

### Tại sao phần này quan trọng với RTOS?

Repository layout là architecture hiển thị cho người ngoài.

### Góc nhìn debug

Search include dependencies: nếu kernel include SPL/BSP, boundary đã bị phá.

---

## 2. Documentation hierarchy

Mỗi loại tài liệu có nhiệm vụ riêng. README không nên biến thành giáo trình 2000 dòng; chapter learning và subsystem docs được tách.

### README

Giới thiệu zRTOS, architecture, scope, build/use overview.

### ROADMAP / learning topics

Trình bày lộ trình học và mental model.

### Subsystem docs

Giải sâu WHAT / WHY / HOW / TRADE-OFF cho scheduler, context switch, IPC, timing, testing.

### Source comments

Giải local constraint và lý do một đoạn implementation khó hiểu.

### Tại sao phần này quan trọng với RTOS?

Tách scope làm tài liệu dễ đọc và ít trùng lặp.

### Góc nhìn debug

Review một claim trong docs rồi trace tới source/test backing.

---

## 3. Reproducible build

Một reviewer clone repository vào folder sạch phải có thể configure/build theo prerequisite đã document.

### Không absolute path

Toolchain/config không chứa đường dẫn riêng máy cá nhân.

### Không hidden generated dependency

`build/`, object file hoặc file IDE local không được là điều kiện ngầm để build pass.

### Clean build khác incremental

Release phải thử build từ zero, không chỉ build directory đã tích lũy cache.

### Tại sao phần này quan trọng với RTOS?

Reproducibility phân biệt personal workspace với project có thể chia sẻ.

### Góc nhìn debug

Copy/clone repo sang thư mục mới và làm đúng hướng dẫn README như một người lạ.

---

## 4. Mental Model tổng hợp

```text
README / learning / subsystem docs
             |
             v
clear module architecture
             |
source tree + CMake
             |
clean clone
             |
configure / build / test
             |
reproducible zRTOS release
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- Kernel không phụ thuộc SPL/BSP.
- Docs claim khớp implementation/test.
- Clean checkout không cần hidden local file.
- Generated artifacts không trở thành source dependency.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “README càng dài càng chuyên nghiệp”

README là front door; deep knowledge nên link sang docs.

### “Build máy mình pass là đủ”

Portfolio repo cần reproducibility.

### “Nhiều folder/file làm repo mạnh”

Responsibility và boundary mới tạo giá trị.

---

## 7. Liên hệ trực tiếp với zRTOS

Phase 12.1 là lúc freeze tree zRTOS v1 và kiểm thử từ góc nhìn reviewer: clone → đọc README → build → xem tests/examples → đọc docs.

---

## 8. Tổng kết

- Repo structure phải khớp dependency architecture.
- Docs tốt có hierarchy và source of truth rõ.
- Clean-clone build là release gate.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. README, learning topics và subsystem docs khác nhau thế nào?
2. Clean-clone build phát hiện những vấn đề gì?
3. Repo tree phản ánh kiến trúc kernel/port/BSP ra sao?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-git-release-cv.md)
