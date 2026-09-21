# Bài 5.2 — Fixed Priority và Same-Priority Round-Robin

> **Phạm vi:** Priority model, highest-ready selection và round-robin trong cùng priority.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không dynamic priority/EDF; priority inheritance thuộc Phase 9.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](01-systick-preemption.md) · [Bài tiếp →](03-idle-starvation-invariants.md)

---

## Mục lục

- [1. Fixed-priority policy](#1-fixed-priority-policy)
- [2. Same-priority round-robin](#2-same-priority-round-robin)
- [3. Wake higher-priority task](#3-wake-higher-priority-task)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Fixed-priority policy

Mỗi task có priority cố định/base. Scheduler luôn ưu tiên runnable task có priority cao nhất.

### Priority direction

Project phải quy định rõ số lớn hơn hay nhỏ hơn là priority cao hơn và dùng nhất quán toàn code/docs/tests.

### Determinism

Nếu High READY, Low không được chạy. Đây là predictable rule quan trọng cho realtime reasoning.

### Tại sao phần này quan trọng với RTOS?

Fixed priority đủ mạnh cho portfolio kernel và dễ giải thích/test.

### Góc nhìn debug

Trace ready set và selected task khi High wake.

---

## 2. Same-priority round-robin

Nhiều task cùng priority chia CPU theo round-robin khi scheduling event xảy ra.

### Cursor per priority

Mỗi priority group cần vị trí selection để không luôn chọn head.

### Time slicing

SysTick có thể tạo scheduling point; yield cũng có thể advance round-robin.

### Tại sao phần này quan trọng với RTOS?

Kết hợp priority determinism với fairness cục bộ.

### Góc nhìn debug

A/B same priority, log switch order qua nhiều ticks.

---

## 3. Wake higher-priority task

Khi BLOCKED High trở READY do tick/IPC, current Low không nên tiếp tục tới tick xa tiếp theo nếu policy yêu cầu immediate preemption.

### Task context wake

Caller có thể request PendSV sau state change.

### ISR wake

FromISR path chỉ pend PendSV; switch sau ISR return.

### Tại sao phần này quan trọng với RTOS?

Preemption response time phụ thuộc kernel request scheduling đúng lúc state thay đổi.

### Góc nhìn debug

Create event waking High while Low runs and verify next task is High.

---

## 4. Mental Model tổng hợp

```text
Ready:
P3 -> H1 H2
P2 -> M
P1 -> L
P0 -> Idle

scheduler:
find highest non-empty priority
       |
       v
round-robin within that list/group
       |
       v
selected TCB
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- Selected task thuộc highest runnable priority.
- Same-priority tasks advance theo round-robin policy.
- Priority range/direction thống nhất.
- Wake higher-priority task dẫn tới scheduling request phù hợp.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Round-robin làm mọi task công bằng”

Không giữa priority khác nhau.

### “Priority cao luôn chạy”

Không nếu BLOCKED.

### “Business importance = priority”

Priority nên dựa timing/latency requirement.

---

## 7. Liên hệ trực tiếp với zRTOS

Phase 6 sẽ chuyển representation runnable set từ task-table scan sang `ready_lists[priority]` nhưng policy không đổi.

---

## 8. Tổng kết

- Highest-priority runnable task luôn thắng.
- Round-robin chỉ áp dụng trong cùng priority group.
- Mọi event làm runnable set thay đổi có thể cần scheduler reevaluation.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Fixed priority cho determinism gì?
2. Round-robin nằm ở scope nào?
3. Khi High task wake từ ISR, flow scheduling ra sao?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](01-systick-preemption.md) · [Bài tiếp →](03-idle-starvation-invariants.md)
