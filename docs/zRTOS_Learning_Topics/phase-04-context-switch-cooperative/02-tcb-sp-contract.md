# Bài 4.2 — TCB Stack Pointer Contract và Context Integrity

> **Phạm vi:** saved_sp contract, stack bounds, context integrity test và failure modes.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Chưa stack watermark/canary nâng cao.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](01-pendsv-save-restore.md) · [Bài tiếp →](03-cooperative-scheduler-yield.md)

---

## Mục lục

- [1. saved_sp là contract xuyên module](#1-savedsp-là-contract-xuyên-module)
- [2. Context integrity](#2-context-integrity)
- [3. Stack boundary sanity](#3-stack-boundary-sanity)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. saved_sp là contract xuyên module

Task creation, SVC và PendSV đều hiểu cùng field `saved_sp`. Đây là interface low-level giữa kernel task model và Cortex-M port.

### Format contract

saved_sp trỏ đầu software frame R4-R11, tiếp theo là hardware frame.

### Lifetime

saved_sp chỉ meaningful nếu stack storage task vẫn tồn tại và không overflow.

### Tại sao phần này quan trọng với RTOS?

Một thay đổi frame layout phải cập nhật tất cả producer/consumer của saved_sp.

### Góc nhìn debug

Dump TCB+stack sau mỗi switch và verify address range.

---

## 2. Context integrity

Correct switch nghĩa task resume với register/local/call stack chính xác. Output LED luân phiên không đủ chứng minh.

### Compiler optimization

R4-R11 có thể giữ biến sống lâu tùy optimization. Test nên dùng code khiến compiler thật sự sử dụng register.

### Call depth

Nested function calls tạo LR/local stack frame; stress test phải bao call chain, không chỉ loop phẳng.

### Tại sao phần này quan trọng với RTOS?

Context bug có thể silent data corruption thay vì immediate fault.

### Góc nhìn debug

Use counters/checksums/patterns và fail-fast assert khi mismatch.

---

## 3. Stack boundary sanity

Mỗi TCB biết stack low/high. saved_sp ngoài range là strong evidence overflow hoặc context bug.

### Early assert

Boundary check có thể bật debug build ngay Phase 4.

### Không thay overflow diagnostics

Range check chỉ detect saved pointer; Phase 10 mới thêm watermark/canary.

### Tại sao phần này quan trọng với RTOS?

Giúp phân biệt scheduler bug với stack corruption.

### Góc nhìn debug

Log task id, saved_sp, stack bounds khi assert.

---

## 4. Mental Model tổng hợp

```text
TCB
 |
 +--> stack_low
 +--> stack_high
 +--> saved_sp ----> [software frame][hardware frame]
 +--> state/priority
 |
Port:
 save -> updates saved_sp
 restore -> consumes saved_sp

Test:
 verify bounds + register/local continuity
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- saved_sp luôn thuộc stack region task.
- saved_sp luôn trỏ đúng frame format.
- Một TCB không dùng stack của task khác.
- Context integrity giữ qua số lượng switch lớn.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “A/B LED alternation chứng minh context đúng”

Không chứng minh R4-R11/call stack/local state.

### “Context bug luôn HardFault”

Có thể chỉ sai counter hoặc memory pointer.

### “saved_sp chỉ là implementation detail”

Nó là contract giữa task creation và port.

---

## 7. Liên hệ trực tiếp với zRTOS

Nên có test firmware riêng `test_context_integrity`, chạy độc lập full demo và có pattern/counter fail-fast.

---

## 8. Tổng kết

- saved_sp không chỉ là pointer; nó mang format contract.
- Context integrity test phải kiểm state dữ liệu, không chỉ thấy scheduler chuyển task.
- Stack bounds là invariant đơn giản nhưng rất giá trị.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. saved_sp contract gồm cả format nào?
2. Tại sao compiler optimization ảnh hưởng test context?
3. Stack boundary check phát hiện loại lỗi gì?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](01-pendsv-save-restore.md) · [Bài tiếp →](03-cooperative-scheduler-yield.md)
