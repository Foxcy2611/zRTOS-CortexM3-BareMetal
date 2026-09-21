# Bài 6.3 — Tick Wraparound và Delayed Structures

> **Phạm vi:** uint32 tick wraparound, deadline comparison và trade-off O(N) scan vs delayed list.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không tickless idle hoặc timer wheel.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](02-blocked-state-delay.md) · [Phase Index →](README.md)

---

## Mục lục

- [1. Tick counter chắc chắn wrap](#1-tick-counter-chắc-chắn-wrap)
- [2. Signed-difference comparison](#2-signed-difference-comparison)
- [3. Delayed structure trade-off](#3-delayed-structure-trade-off)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Tick counter chắc chắn wrap

`uint32_t` tick là modulo counter. Overflow không phải exceptional event; kernel phải thiết kế comparison đúng ngay từ đầu.

### Unsigned compare trap

`now >= deadline` có thể sai khi deadline nằm sau wrap.

### Modulo time

Thay vì xem tick là số tuyệt đối vô hạn, xem nó là position trên vòng modulo.

### Tại sao phần này quan trọng với RTOS?

Wrap bug có thể chỉ xuất hiện sau nhiều ngày/tuần, rất nguy hiểm nếu không test chủ động.

### Góc nhìn debug

Force tick gần UINT32_MAX trong test thay vì chờ thật.

---

## 2. Signed-difference comparison

Một pattern phổ biến dùng signed interpretation của `now - deadline` trong cửa sổ timeout giới hạn nhỏ hơn nửa modulo range.

### Bound

Method này có assumption về maximum interval; phải document max delay/timeout.

### Consistency

Delay và finite IPC timeout phải dùng cùng timing helper để tránh semantics khác nhau.

### Tại sao phần này quan trọng với RTOS?

Common helper giảm duplicate wrap bugs.

### Góc nhìn debug

Test deadline trước, đúng và sau wrap.

---

## 3. Delayed structure trade-off

V1 có thể scan task_table mỗi tick để tìm DELAY task. Complexity O(number_of_tasks) nhưng code dễ audit.

### Khi scan hợp lý

STM32F103 portfolio kernel với số task nhỏ ưu tiên clarity.

### Khi cần optimize

Nhiều task/tick rate cao có thể dùng sorted delayed list hoặc cấu trúc khác; đó là future optimization.

### Tại sao phần này quan trọng với RTOS?

Không premature optimize trước khi correctness/test hoàn chỉnh.

### Góc nhìn debug

Measure tick handler cost nếu muốn evidence thay vì đoán.

---

## 4. Mental Model tổng hợp

```text
tick sequence:
FFFFFFFD
FFFFFFFE
FFFFFFFF
00000000
00000001

deadline comparison
 phải đúng xuyên điểm wrap

V1:
for task in task_table
  if BLOCKED/DELAY and deadline_reached:
      make_ready(task)
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- Timing helper wrap-safe được dùng nhất quán.
- Maximum supported delay/timeout được định nghĩa.
- Tick handler không wake task chưa tới deadline.
- Complexity O(N) nếu giữ scan phải ghi known limitation.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “uint32 overflow làm tick reset sai”

Modulo overflow là behavior chuẩn.

### “Cần 64-bit tick để tránh mọi vấn đề”

Chỉ trì hoãn wrap; comparison semantics vẫn cần design.

### “Sorted list bắt buộc để gọi là RTOS”

Không cho scope nhỏ; correctness trước optimization.

---

## 7. Liên hệ trực tiếp với zRTOS

zRTOS v1 có thể giữ linear delayed scan, nhưng test wraparound là bắt buộc trước Phase 9 finite timeout.

---

## 8. Tổng kết

- Tick overflow là expected behavior, không phải rare fault.
- Wrap-safe compare cần explicit interval bound.
- O(N) delayed scan là acceptable v1 limitation nếu được document.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Tại sao unsigned `now >= deadline` có thể sai?
2. Signed-difference compare có assumption gì?
3. Khi nào nên thay O(N) scan bằng delayed list?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](02-blocked-state-delay.md) · [Phase Index →](README.md)
