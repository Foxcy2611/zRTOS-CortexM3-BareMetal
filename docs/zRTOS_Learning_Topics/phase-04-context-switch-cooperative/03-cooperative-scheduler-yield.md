# Bài 4.3 — Cooperative Scheduler, Round-Robin và Yield

> **Phạm vi:** Scheduler policy đơn giản, task table, round-robin và yield semantics.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Chưa có SysTick preemption hoặc priority.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](02-tcb-sp-contract.md) · [Phase Index →](README.md)

---

## Mục lục

- [1. Scheduler khác context switch](#1-scheduler-khác-context-switch)
- [2. Task registry và round-robin](#2-task-registry-và-round-robin)
- [3. Yield semantics](#3-yield-semantics)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Scheduler khác context switch

Scheduler quyết định **ai chạy tiếp**. PendSV thực hiện **chuyển CPU**. Hai trách nhiệm này phải tách để policy có thể thay đổi mà assembly port không đổi.

### Policy

Cooperative phase dùng round-robin đơn giản qua task table/index.

### Mechanism

PendSV chỉ save current, gọi/select next, restore selected.

### Tại sao phần này quan trọng với RTOS?

Tách policy/mechanism là kiến trúc lõi giúp zRTOS mở rộng priority scheduler.

### Góc nhìn debug

Trace selected TCB sequence riêng với context-switch counter.

---

## 2. Task registry và round-robin

Trước ready lists, `task_table[]` là data structure học tập tốt: ít abstraction, dễ thấy policy.

### Cursor/index

Scheduler nhớ vị trí lần trước để chọn task kế tiếp.

### Runnability

Phase này task chủ yếu READY/RUNNING; BLOCKED chưa xuất hiện.

### Tại sao phần này quan trọng với RTOS?

Không nên học intrusive list cùng lúc với first scheduler.

### Góc nhìn debug

Print/observe selected index A→B→C→A.

---

## 3. Yield semantics

`zrtos_yield()` không block current. Nó chỉ request PendSV/scheduler reevaluation.

### Single task

Nếu chỉ một runnable task, yield có thể chọn lại chính nó. PendSV vẫn có thể chạy nhưng externally không đổi task.

### Fairness cooperative

Nếu task quên yield, task khác cùng/lower policy không chạy. Đây là limitation cố ý của cooperative phase.

### Tại sao phần này quan trọng với RTOS?

Hiểu yield trước preemption giúp phân biệt voluntary scheduling event và blocking.

### Góc nhìn debug

Test 3 task yield và một task không yield để quan sát limitation.

---

## 4. Mental Model tổng hợp

```text
Task A RUNNING
    |
    | zrtos_yield()
    v
PendSV pending
    |
    v
save A
    |
    v
scheduler cursor: A -> B
    |
    v
restore B
    |
    v
Task B RUNNING
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- Yield không remove task khỏi runnable set.
- Scheduler luôn trả về runnable TCB hợp lệ.
- Exactly one task RUNNING sau selection.
- Round-robin sequence deterministic với cùng runnable set.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “yield = block”

Yield chỉ nhường lượt; task vẫn runnable.

### “Round-robin đã là preemptive”

Chưa; task phải tự yield.

### “PendSV nên chứa round-robin index”

Policy nên nằm scheduler module.

---

## 7. Liên hệ trực tiếp với zRTOS

Phase 4 kết thúc khi zRTOS chạy 3 task cooperative và PendSV không hard-code A/B. Phase 5 chỉ thay event/policy bằng SysTick + fixed priority.

---

## 8. Tổng kết

- Scheduler chọn; PendSV chuyển.
- Simple task table giúp isolate scheduler policy trước optimization.
- Yield giữ task runnable; block thì loại task khỏi runnable set.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Scheduler và PendSV khác nhau thế nào?
2. Yield khác block ở đâu?
3. Tại sao task_table hợp lý cho phase học đầu?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](02-tcb-sp-contract.md) · [Phase Index →](README.md)
