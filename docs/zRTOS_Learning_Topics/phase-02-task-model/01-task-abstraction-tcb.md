# Bài 2.1 — Task Abstraction và Task Control Block

> **Phạm vi:** Task như execution context, TCB, static allocation và boundary public/internal.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không có dynamic allocation, task delete hoặc SMP trong zRTOS v1.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-task-states-lifecycle.md)

---

## Mục lục

- [1. Task không chỉ là function](#1-task-không-chỉ-là-function)
- [2. TCB là software representation](#2-tcb-là-software-representation)
- [3. Static allocation](#3-static-allocation)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Task không chỉ là function

Một function chỉ mô tả code. Một task cần thêm stack riêng, CPU context riêng và scheduling metadata. Hai task có thể chạy cùng một entry function nhưng vẫn là hai execution context khác nhau.

### Execution context

Context quyết định task tiếp tục từ đâu và với register/stack nào. Nếu thiếu stack/context, “task” chỉ là callback.

### Scheduling identity

Priority/state/list membership cho kernel biết task có được chạy hay đang chờ.

### Tại sao phần này quan trọng với RTOS?

Abstraction task đúng giúp mọi feature sau — scheduler, delay, IPC — có một object trung tâm để quản lý.

### Góc nhìn debug

Khi inspect TCB, phải phân biệt metadata logic và actual CPU frame nằm trên stack.

---

## 2. TCB là software representation

Task Control Block chứa dữ liệu kernel cần để quản lý một task. Không phải mọi register nằm trực tiếp trong TCB; saved SP thường là cầu nối tới frame trên stack.

### Core fields

`saved_sp`, stack base/size, entry, argument, priority, state là core. Ready/wait list node, timeout metadata được thêm khi feature xuất hiện.

### Không nhét peripheral state

UART/SPI handle không thuộc task kernel abstraction. Việc đó nằm application/BSP hoặc object khác.

### Tại sao phần này quan trọng với RTOS?

TCB càng rõ responsibility, port và kernel càng tách được khỏi application.

### Góc nhìn debug

Inspect `sizeof(TCB)` và alignment; field order có thể quan trọng với assembly nếu port truy cập offset trực tiếp.

---

## 3. Static allocation

zRTOS v1 chọn caller-provided TCB/stack. Kernel không gọi malloc khi tạo task.

### Ưu điểm

RAM predictable, không fragmentation, failure model rõ, hợp STM32F103 RAM nhỏ.

### Trade-off

Task count/stack size phải provision trước; lifecycle ít linh hoạt hơn dynamic RTOS.

### API ownership

Caller phải đảm bảo TCB/stack storage sống suốt lifetime task. Không dùng local array trong function rồi return.

### Tại sao phần này quan trọng với RTOS?

Static allocation buộc người học nhìn trực tiếp RAM cost của mỗi task.

### Góc nhìn debug

Xem map file/stack addresses để biết task storage nằm đâu trong SRAM.

---

## 4. Mental Model tổng hợp

```text
Application supplies:
  TCB storage
  stack storage
  entry + arg
  priority
      |
      v
zrtos_task_create_static()
      |
      v
initialized TCB
      |
      +--> saved_sp -> task stack frame
      +--> state
      +--> priority
      +--> metadata
      |
      v
scheduler / port
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- TCB và stack storage sống ít nhất bằng lifetime task.
- Mỗi task có stack riêng.
- Priority nằm trong configured range.
- Kernel core không chứa peripheral-specific fields trong TCB.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Task = function pointer”

Function pointer chỉ là một phần task.

### “TCB nên chứa toàn bộ register”

Không cần; frame trên stack + saved SP thường hiệu quả hơn.

### “Static allocation chỉ phù hợp demo”

Nhiều embedded system cố ý dùng static allocation để predictable.

---

## 7. Liên hệ trực tiếp với zRTOS

Public API dự kiến:

```c
zrtos_task_create_static(&tcb, entry, arg, stack, stack_words, priority);
```

Phase này chưa schedule; mục tiêu là biến input hợp lệ thành TCB có contract rõ.

---

## 8. Tổng kết

- Task = code + stack + CPU context + scheduling state.
- TCB giữ metadata và saved SP; register context chủ yếu nằm trên stack.
- Static allocation là design choice có chủ đích, không phải thiếu sót mặc định.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Một task khác function ở những thành phần nào?
2. TCB nên và không nên chứa loại dữ liệu nào?
3. Static allocation yêu cầu caller đảm bảo lifetime gì?
4. Saved SP liên kết TCB với CPU context thế nào?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-task-states-lifecycle.md)
