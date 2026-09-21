# Bài 3.1 — Kernel Bootstrap và Current Task

> **Phạm vi:** Trạng thái kernel trước khi scheduler chạy, initialization order, current task và điều kiện an toàn trước SVC.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Chưa context switch giữa nhiều task; chỉ bootstrap first task.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-svc-first-task-flow.md)

---

## Mục lục

- [1. Pre-start kernel state](#1-pre-start-kernel-state)
- [2. Chọn first task](#2-chọn-first-task)
- [3. Interrupt ordering hazard](#3-interrupt-ordering-hazard)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Pre-start kernel state

Sau `zrtos_init()` kernel đã có data structure nhưng chưa task nào thực sự chạy dưới zRTOS. Task được tạo có thể ở READY, nhưng CPU vẫn đang thực thi bootstrap code trong `main()`.

### Init khác Start

Tách `zrtos_init()` và `zrtos_start()` làm lifecycle rõ. Init chuẩn bị lists/state/config; Start chọn first task, setup port và chuyển execution.

### Scheduler running flag

Một flag runtime giúp ISR/API biết scheduler đã bootstrap xong chưa. Flag không nên set sớm khi PSP/current_tcb còn chưa hợp lệ.

### Tại sao phần này quan trọng với RTOS?

Nhiều lỗi first-task không nằm ở assembly mà nằm ở initialization order.

### Góc nhìn debug

Break ngay trước SVC và verify current_tcb, state, saved_sp, scheduler flag và interrupt mask.

---

## 2. Chọn first task

Kernel cần một selected TCB hợp lệ trước khi SVC restore. Selection có thể dùng policy scheduler thật hoặc temporary highest-ready policy, nhưng contract phải thống nhất.

### current_tcb

`zrtos_current_tcb` là pointer trung tâm port dùng để lấy saved SP. Nó không được NULL tại SVC bootstrap.

### State transition

Selected task chuyển READY→RUNNING ở thời điểm scheduler sở hữu nó. Cần thống nhất transition xảy ra trước hay trong bootstrap function.

### Tại sao phần này quan trọng với RTOS?

Port không nên biết cách tìm task; nó chỉ nhận current_tcb đã được kernel quyết định.

### Góc nhìn debug

Inspect selected priority/state và confirm nó thuộc runnable set.

---

## 3. Interrupt ordering hazard

Nếu SysTick/PendSV hoặc kernel-aware IRQ fire trước khi bootstrap hoàn tất, handler có thể dereference current_tcb hoặc PSP chưa hợp lệ.

### Critical bootstrap window

Kernel thường giữ scheduling interrupt chưa active hoặc masked cho tới khi first context sẵn sàng.

### Mark running đúng lúc

Scheduler-running flag chỉ nên visible khi exception path có thể safely operate.

### Tại sao phần này quan trọng với RTOS?

Boot race thường hiếm, khiến reset đôi lúc lỗi và rất khó debug nếu không có explicit ordering.

### Góc nhìn debug

Cố tình đặt breakpoint giữa các bootstrap bước và xem interrupt nào đang enabled/pending.

---

## 4. Mental Model tổng hợp

```text
reset
  |
  v
main()
  |
  v
zrtos_init()
  |
  +--> init lists/config
  +--> scheduler_running = false
  |
create READY tasks
  |
  v
zrtos_start()
  |
  +--> select first task
  +--> current_tcb = selected
  +--> prepare safe bootstrap window
  +--> SVC
  v
first task runtime
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- current_tcb hợp lệ trước khi SVC handler sử dụng.
- Selected first task thuộc runnable set và có saved_sp hợp lệ.
- Kernel-aware scheduling interrupt không được chạy trên state bootstrap chưa hoàn tất.
- zrtos_start() chỉ được gọi một lần trong zRTOS v1.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “zrtos_start chỉ bật SysTick”

Start còn phải bootstrap execution context.

### “Task READY nghĩa CPU đã có PSP task”

READY chỉ là logical state trước selection.

### “Interrupt enable càng sớm càng tốt”

Có thể tạo race với bootstrap state.

---

## 7. Liên hệ trực tiếp với zRTOS

`zrtos_start()` là bridge giữa static kernel data và CPU task runtime. Sau chapter này, Phase 3.2 mới đi vào SVC restore assembly.

---

## 8. Tổng kết

- Kernel có pre-start state riêng; READY task chưa đồng nghĩa scheduler đã chạy.
- First-task selection là scheduler responsibility, SVC chỉ restore selected task.
- Initialization order là một phần của kernel correctness.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Tại sao cần tách init và start?
2. current_tcb phải hợp lệ ở thời điểm nào?
3. Điều gì có thể xảy ra nếu PendSV fire quá sớm?
4. READY task khác RUNNING first task thế nào?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-svc-first-task-flow.md)
