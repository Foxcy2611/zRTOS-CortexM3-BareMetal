# Bài 6.1 — Intrusive List và Ready Lists

> **Phạm vi:** Intrusive doubly-linked circular list, sentinel, owner/container và ready_lists theo priority.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không delayed list tối ưu; chỉ ready-list infrastructure.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-blocked-state-delay.md)

---

## Mục lục

- [1. Tại sao kernel cần list](#1-tại-sao-kernel-cần-list)
- [2. Intrusive doubly-linked circular list](#2-intrusive-doubly-linked-circular-list)
- [3. ready_lists theo priority](#3-readylists-theo-priority)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Tại sao kernel cần list

Task thường xuyên chuyển READY↔BLOCKED; scheduler cần tập runnable theo priority và IPC cần wait sets. Data structure phải hỗ trợ insert/remove thường xuyên.

### Array scan limitation

Task table scan đơn giản để học, nhưng remove/iterate theo priority không biểu diễn state tốt khi feature tăng.

### Known-node operations

Kernel thường đã có TCB pointer của task cần block/wake, nên O(1) remove rất hữu ích.

### Tại sao phần này quan trọng với RTOS?

List là infrastructure xuyên scheduler/IPC, không chỉ tối ưu.

### Góc nhìn debug

Unit-test list trước migrate scheduler.

---

## 2. Intrusive doubly-linked circular list

Node nằm trong TCB thay vì malloc wrapper. Node có next/prev, owner và container.

### Intrusive

Không dynamic allocation và từ node quay lại TCB qua owner.

### Doubly linked

Remove known item O(1) bằng reconnect prev/next.

### Circular + sentinel

End sentinel tránh NULL edge cases và round-robin cursor tự wrap.

### Container

Container giúp detect double insert và biết item thuộc list nào.

### Tại sao phần này quan trọng với RTOS?

Mỗi đặc tính có reason cụ thể; không copy structure vì “RTOS thường vậy”.

### Góc nhìn debug

Inspect sentinel links ở empty/single/multi list.

---

## 3. ready_lists theo priority

Mỗi priority có một list runnable. Scheduler scan priority cao→thấp rồi chọn next owner bằng cursor.

### ready_item trong TCB

TCB chứa node riêng cho ready membership.

### RUNNING membership

Design có thể giữ RUNNING trong ready list để runnable set bao gồm READY+RUNNING; state phân biệt current.

```text
ready_lists[P3] -> H1 <-> H2
ready_lists[P2] -> M
ready_lists[P1] -> L
ready_lists[P0] -> Idle
```

### Tại sao phần này quan trọng với RTOS?

Representation khớp trực tiếp fixed-priority policy.

### Góc nhìn debug

Assert ready_item.container == &ready_lists[priority] cho runnable task.

---

## 4. Mental Model tổng hợp

```text
TCB
 +--> ready_item(owner=TCB)
 +--> wait_item (future IPC)

READY/RUNNING:
 ready_item -> ready_lists[priority]

BLOCKED:
 ready_item detached
 optional wait_item -> object wait list
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- Một list item không đồng thời thuộc hai container.
- Detached item có container NULL.
- Sentinel không được coi là task item.
- Runnable task ready_item thuộc list đúng priority.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Linked list chỉ để nhanh hơn array”

Nó còn encode membership/invariant rõ.

### “Một node đủ cho mọi list”

Task có thể cần roles khác nhau; ready_item và wait_item nên tách.

### “Circular list không cần test edge case”

Cursor/sentinel remove vẫn có failure mode riêng.

---

## 7. Liên hệ trực tiếp với zRTOS

Sau migration, scheduler không scan task_table để chọn runnable task. `task_table[]` vẫn có thể giữ registry cho diagnostics/delay scan.

---

## 8. Tổng kết

- Kernel list giải quyết membership/state organization.
- Intrusive+doubly+circular+sentinel tối ưu cho static kernel membership operations.
- ready_lists biến scheduler policy thành data structure rõ ràng.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Tại sao intrusive list hợp static allocation?
2. Container field giúp detect lỗi gì?
3. Vì sao TCB cần ready_item và wait_item riêng?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-blocked-state-delay.md)
