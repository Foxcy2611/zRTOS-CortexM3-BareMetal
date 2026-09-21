# Bài 10.1 — Kernel Assert và Invariants

> **Phạm vi:** Invariant-driven kernel design, assert framework, fail-fast behavior và phân biệt internal bug với API error.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không formal verification hoặc safety certification.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-stack-runtime-diagnostics.md)

---

## Mục lục

- [1. Invariant là contract executable](#1-invariant-là-contract-executable)
- [2. Assert framework](#2-assert-framework)
- [3. API error khác internal assert](#3-api-error-khác-internal-assert)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Invariant là contract executable

Kernel correctness dựa trên những điều luôn phải đúng: current_tcb state RUNNING, BLOCKED task không nằm ready list, semaphore count trong range, queue count không vượt capacity. Viết invariant trước làm implementation bớt mơ hồ.

### Precondition

Điều phải đúng trước operation. Ví dụ `zrtos_delay()` chỉ hợp lệ từ current task đang RUNNING.

### Postcondition

Điều phải đúng sau transition. Ví dụ task blocked đã rời ready list và có block reason hợp lệ.

### Tại sao phần này quan trọng với RTOS?

Invariant biến reasoning thành điều có thể test/assert.

### Góc nhìn debug

Đặt assert gần transition để fail ở nơi phá contract, không phải vài nghìn instruction sau.

---

## 2. Assert framework

`ZRTOS_ASSERT(expr)` trong debug build nên đi tới hook có file/line/reason hoặc breakpoint rõ ràng.

### Fail-fast

Scheduler corruption mà vẫn tiếp tục chạy thường làm lỗi lan sang list, stack hoặc IPC khác.

### Configurable policy

Debug có thể halt; policy release về sau có thể log/reset/watchdog, nhưng v1 ưu tiên khả năng debug.

### Tại sao phần này quan trọng với RTOS?

Kernel bug hay fault ở nơi xa nguyên nhân nếu không fail-fast.

### Góc nhìn debug

Cố tình double-insert list item hoặc vi phạm state transition để verify hook.

---

## 3. API error khác internal assert

Không phải mọi lỗi đều assert. TIMEOUT, queue full với NO_WAIT hay invalid user argument có thể là runtime/API condition hợp lệ.

### Recoverable condition

Return status để caller xử lý.

### Impossible internal state

Ví dụ current_tcb NULL khi scheduler running hoặc duplicate list membership nên assert.

### Tại sao phần này quan trọng với RTOS?

Nếu assert mọi thứ, API khó dùng; nếu return error cho corruption, kernel có thể tiếp tục với state hỏng.

### Góc nhìn debug

Với mỗi error path, hỏi: caller hợp lệ có thể gặp condition này không?

---

## 4. Mental Model tổng hợp

```text
kernel operation
   |
check preconditions
   |
state mutation
   |
check postconditions
   |
continue

recoverable runtime condition -> return status
impossible internal state     -> assert hook
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- Assert không thay thế recoverable API status.
- Transition quan trọng có pre/post-condition rõ.
- Assert path không tiếp tục scheduling trên state đã corrupt.
- Reason/file/line đủ để debugger định vị lỗi.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Assert chỉ để check NULL”

Trong kernel, structural/state invariant mới là giá trị lớn nhất.

### “Mọi invalid call đều assert”

Public API có nhiều lỗi hợp lệ nên return status.

### “Release bỏ assert nên invariant không quan trọng”

Invariant vẫn là design contract dù instrumentation configurable.

---

## 7. Liên hệ trực tiếp với zRTOS

`docs/` nên ghi invariant của task/list/scheduler/IPC. Các invariant đó trở thành nguồn chung cho `ZRTOS_ASSERT()` và regression tests.

---

## 8. Tổng kết

- Assert nên xuất phát từ invariant đã document.
- Assert là executable design contract.
- Recoverable API condition và kernel corruption là hai lớp khác nhau.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Invariant khác input validation thế nào?
2. Khi nào nên assert thay vì return error?
3. Nêu bốn invariant zRTOS có thể kiểm tự động.

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-stack-runtime-diagnostics.md)
