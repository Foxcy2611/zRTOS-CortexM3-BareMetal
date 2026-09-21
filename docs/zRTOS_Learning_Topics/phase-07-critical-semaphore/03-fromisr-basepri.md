# Bài 7.3 — FromISR API, BASEPRI và Deferred Preemption

> **Phạm vi:** ISR-safe semaphore operation, deferred scheduling và ý tưởng BASEPRI/kernel-aware ISR priority.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** zRTOS v1 có thể vẫn dùng PRIMASK; BASEPRI được học để hiểu thiết kế mở rộng.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](02-semaphore-wait-lists.md) · [Phase Index →](README.md)

---

## Mục lục

- [1. ISR không được block](#1-isr-không-được-block)
- [2. Wake task từ ISR](#2-wake-task-từ-isr)
- [3. BASEPRI concept](#3-basepri-concept)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. ISR không được block

ISR không phải task được scheduler quản lý bằng TCB riêng để sleep. Vì vậy API FromISR chỉ được thực hiện operation hoàn thành ngay.

### No wait

Nếu resource không sẵn sàng cho operation cần wait, ISR phải return status/overflow policy thay vì block.

### No task-context assumption

FromISR path phải cẩn thận nếu scheduler chưa running hoặc current_tcb chưa valid trong bootstrap.

### Tại sao phần này quan trọng với RTOS?

Tách API context tránh đem semantics task blocking vào exception context.

### Góc nhìn debug

Assert hoặc document API nào legal từ ISR.

---

## 2. Wake task từ ISR

ISR có thể give semaphore/send queue làm BLOCKED task READY. Nếu task mới wake có priority cao hơn current, kernel request PendSV.

### Deferred switch

ISR không tự nhảy vào task giữa hardware handling. PendSV chạy sau khi IRQ hoàn tất theo priority rules.

### Latency

High task có thể bắt đầu gần ngay sau ISR return thay vì đợi tick sau.

```text
IRQ
 |
 +--> handle hardware
 +--> give_from_isr()
       |
       +--> wake High
       +--> pend PendSV
 |
 v
IRQ return
 |
 v
PendSV
 |
 v
High task
```

### Tại sao phần này quan trọng với RTOS?

Đây là bridge giữa peripheral events và preemptive scheduler.

### Góc nhìn debug

Trace IRQ→PendSV→High task với EXTI/UART event.

---

## 3. BASEPRI concept

PRIMASK mask gần toàn bộ configurable interrupts. BASEPRI cho phép mask interrupts từ một priority threshold, để rất high-priority IRQ vẫn chạy.

### Kernel-aware ISR

Nếu kernel dùng BASEPRI, chỉ ISR trong priority range cho phép mới được gọi kernel API; high-critical ISR ngoài mask có thể phải hoàn toàn kernel-independent.

### Trade-off

BASEPRI giảm worst-case interrupt latency nhưng làm priority configuration phức tạp hơn.

### Tại sao phần này quan trọng với RTOS?

Hiểu BASEPRI giúp đọc FreeRTOS/Cortex-M production ports sau này mà không xem macros như magic.

### Góc nhìn debug

Lab read/write BASEPRI và observe interrupt masking nếu cần, nhưng không buộc migrate v1 ngay.

---

## 4. Mental Model tổng hợp

```text
task context API:
 may block
 may schedule

ISR API:
 never block
 mutate minimal kernel state
 optionally wake task
 pend PendSV
 return ISR

critical masking:
 PRIMASK (simple v1)
 BASEPRI (priority-threshold design)
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- FromISR API không bao giờ block.
- Wake higher-priority task từ ISR request scheduling phù hợp.
- Context switch thật được deferred tới PendSV.
- Interrupt masking policy phải nhất quán với API legality.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “FromISR chỉ là wrapper nhanh hơn”

Nó có restrictions khác fundamentally.

### “Wake High từ ISR phải switch ngay trong ISR”

Deferred PendSV mới là design mong muốn.

### “BASEPRI luôn cần ngay từ đầu”

Không; có thể học và để future nếu PRIMASK đủ scope.

---

## 7. Liên hệ trực tiếp với zRTOS

Phase 11 UART RX queue sẽ là integration demo cho toàn flow ISR→FromISR→wake→PendSV→task.

---

## 8. Tổng kết

- FromISR là semantics riêng, không chỉ suffix tên hàm.
- ISR wake chỉ request deferred switch; PendSV thực hiện switch.
- BASEPRI là refinement của critical masking, không bắt buộc cho first portfolio version.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Vì sao ISR không được block?
2. Flow wake High task từ ISR là gì?
3. BASEPRI khác PRIMASK ở mức ý tưởng thế nào?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](02-semaphore-wait-lists.md) · [Phase Index →](README.md)
