# Bài 12.3 — zRTOS v1 Scope, Known Limits và Future Direction

> **Phạm vi:** Definition of done cho portfolio-grade v1, giới hạn có chủ đích và hướng mở rộng sau release.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Production-grade/certification không phải requirement của zRTOS v1.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](02-git-release-cv.md) · [Phase Index →](README.md)

---

## Mục lục

- [1. Freeze scope để hoàn thành](#1-freeze-scope-để-hoàn-thành)
- [2. Known limitations là design decision](#2-known-limitations-là-design-decision)
- [3. Future direction sau v1](#3-future-direction-sau-v1)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Freeze scope để hoàn thành

Solo project rất dễ thêm feature vô hạn rồi không bao giờ release. zRTOS v1 cần definition of done rõ.

### Core v1

Task/TCB, SVC/PendSV, preemptive scheduler, lists, delay, critical, semaphore, queue, FromISR, mutex PI, finite timeout, diagnostics, tests, full demo.

### Không cần clone FreeRTOS feature list

Software timer, event group, tickless idle, dynamic heap, nhiều architecture port không bắt buộc cho v1.

### Tại sao phần này quan trọng với RTOS?

Một v1 hoàn chỉnh tốt hơn một project ‘sắp xong’ vô hạn.

### Góc nhìn debug

Dùng checklist feature/test/docs trước tag.

---

## 2. Known limitations là design decision

Giới hạn có thể gồm Cortex-M3-only, static lifecycle, fixed priority, O(N) delay scan, limited PI nesting — tùy implementation cuối.

### Không che limitation

Reviewer thấy bạn biết guarantee nào có/không.

### Version-specific

Khi feature thay đổi, limitation phải update theo release.

### Trade-off

Một limitation có thể là lựa chọn để giữ code audit-able và phù hợp STM32F103 scope.

### Tại sao phần này quan trọng với RTOS?

Engineering maturity thể hiện ở việc biết scope, không phải cố claim mọi thứ.

### Góc nhìn debug

Cross-check `known_limitations.md` với source và tests.

---

## 3. Future direction sau v1

Sau release mới mở v1.x/v2 cho feature mới: event flags, task notification, software timers, optimized delayed lists, tickless idle, memory pool hoặc Cortex-M4 port.

### Second CPU port

Port sang STM32F4/Cortex-M4 mà `kernel/` ít đổi là proof mạnh cho architecture separation.

### Production-like hardening

Static analysis, MISRA-oriented cleanup, broader coverage và latency benchmark có thể là journey riêng.

### Không đồng nghĩa production-grade

Production-grade còn phụ thuộc validation, domain requirement và có thể certification; vượt scope solo v1.

### Tại sao phần này quan trọng với RTOS?

Future roadmap có giá trị hơn khi core v1 đã có release stable.

### Góc nhìn debug

Mỗi feature future phải gắn learning objective hoặc measured problem rõ.

---

## 4. Mental Model tổng hợp

```text
zRTOS v1
  |
complete + tested + documented
  |
  v
release
  |
  +--> maintain v1
  |
  +--> future:
       events / timers
       tickless
       optimized timing
       Cortex-M4 port
       deeper analysis/testing

production-grade != requirement v1
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- v1 có definition of done rõ.
- Known limitations khớp release source.
- Future feature không trì hoãn release core vô hạn.
- Không claim production-grade khi chưa có evidence tương ứng.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Không production-grade nghĩa project yếu”

Portfolio-grade RTOS sâu vẫn là solo project rất mạnh.

### “RTOS phải có mọi API FreeRTOS”

Core scheduling/blocking/IPC correctness quan trọng hơn feature count.

### “Port thứ hai chỉ là copy BSP”

Portability proof kiểm kernel/CPU/board separation thật.

---

## 7. Liên hệ trực tiếp với zRTOS

Đây là điểm kết thúc curriculum zRTOS v1. Bộ chapter có thể tiếp tục dùng như design reference và tài liệu ôn phỏng vấn sau khi code hoàn thành.

---

## 8. Tổng kết

- Definition of done bảo vệ project khỏi feature creep.
- Limitation rõ làm guarantee đáng tin hơn.
- Portfolio-grade v1 là điểm kết thúc hợp lý; future là project phase mới.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Definition of done zRTOS v1 gồm những nhóm feature nào?
2. Known limitations giúp project đáng tin hơn thế nào?
3. Những feature nào hợp lý để để sau v1?
4. Port Cortex-M4 kiểm chứng điều gì về architecture?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](02-git-release-cv.md) · [Phase Index →](README.md)
