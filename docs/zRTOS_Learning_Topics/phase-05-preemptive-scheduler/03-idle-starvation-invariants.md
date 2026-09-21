# Bài 5.3 — Idle Task, Starvation, Fairness và Scheduler Invariants

> **Phạm vi:** Idle task, starvation trade-off, fairness và scheduler correctness conditions.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không tickless idle/power manager.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](02-fixed-priority-round-robin.md) · [Phase Index →](README.md)

---

## Mục lục

- [1. Idle task](#1-idle-task)
- [2. Starvation và fairness](#2-starvation-và-fairness)
- [3. Scheduler invariants](#3-scheduler-invariants)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Idle task

Idle có priority thấp nhất và luôn runnable. Nó bảo đảm scheduler không gặp trạng thái “không có task để restore”.

### Idle body

Có thể đơn giản increment counter, call hook hoặc `__WFI()` khi safe. Không nên chứa business logic cần deadline.

### Internal task

Kernel có thể tự tạo idle task để application không phải quản lý invariant này.

### Tại sao phần này quan trọng với RTOS?

Idle giúp scheduler total function: runtime selection luôn có result.

### Góc nhìn debug

Observe idle counter chỉ tăng khi app tasks không runnable.

---

## 2. Starvation và fairness

Fixed priority có thể starve Low nếu High luôn READY. Đây không tự động là scheduler bug.

### Fairness cục bộ

Same-priority round-robin tạo fairness trong group.

### Realtime intent

RTOS ưu tiên deadline/latency chứ không tối ưu fairness desktop-style.

### Tại sao phần này quan trọng với RTOS?

Hiểu trade-off tránh cố “sửa” fixed-priority thành policy mơ hồ.

### Góc nhìn debug

Tạo High busy task không block và quan sát Low starvation như expected property.

---

## 3. Scheduler invariants

Scheduler đúng không chỉ là chọn “có vẻ hợp lý”. Cần invariant kiểm được sau mỗi selection.

### Exactly one RUNNING

current_tcb và state phải đồng nhất.

### Never NULL

Idle đảm bảo candidate.

### Highest ready

Selected priority không thấp hơn bất kỳ runnable task nào.

### Tại sao phần này quan trọng với RTOS?

Invariant biến scheduler policy thành testable contract.

### Góc nhìn debug

Add asserts around select_next và tests nhiều combination ready states.

---

## 4. Mental Model tổng hợp

```text
No app READY
    |
    v
Idle RUNNING

App task wakes
    |
    v
scheduler reevaluate
    |
    v
higher-priority app RUNNING

If High never blocks:
Low may starve by design
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- Idle luôn runnable và priority thấp nhất.
- Scheduler runtime không trả NULL.
- Exactly one task RUNNING.
- Selected task là highest-priority runnable candidate.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Idle chạy là lỗi”

Idle là normal no-work state.

### “Starvation luôn là bug”

Có thể là expected fixed-priority consequence.

### “Priority càng cao càng tốt”

Misassigned priority có thể làm system kém responsive.

---

## 7. Liên hệ trực tiếp với zRTOS

Idle counter về sau có thể trở thành CPU idle metric Phase 10, nhưng core idle semantics phải đúng trước.

---

## 8. Tổng kết

- Idle là fallback runnable task bắt buộc trong design.
- Starvation là possible consequence của priority model.
- Scheduler correctness được mô tả bằng invariant cụ thể.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Tại sao cần idle task?
2. Starvation khi nào là expected?
3. Nêu ba scheduler invariant có thể assert/test.

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](02-fixed-priority-round-robin.md) · [Phase Index →](README.md)
