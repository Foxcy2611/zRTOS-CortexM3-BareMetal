# Bài 2.3 — Initial Task Stack và Context Contract

> **Phạm vi:** Dựng initial hardware/software frame cho task mới, stack alignment và task return trap.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không bàn stack watermark/canary; thuộc Phase 10.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Bài trước](02-task-states-lifecycle.md) · [Phase Index →](README.md)

---

## Mục lục

- [1. Vấn đề task chưa từng chạy](#1-vấn-đề-task-chưa-từng-chạy)
- [2. Initial hardware frame](#2-initial-hardware-frame)
- [3. Initial software frame và saved SP](#3-initial-software-frame-và-saved-sp)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Vấn đề task chưa từng chạy

Task đã bị preempt có frame do hardware + PendSV tạo. Task mới chưa chạy nên không có frame tự nhiên. Kernel phải dựng một frame giả có cùng restore contract.

### Một restore path cho cả task mới và task cũ

Nếu initial frame giống saved frame, SVC/PendSV không cần branch “new task” đặc biệt.

### Stack grows downward

Task creation bắt đầu từ top stack, align rồi reserve/push frame theo layout đã định.

### Tại sao phần này quan trọng với RTOS?

Initial stack là nơi kiến thức exception architecture biến thành data structure thực.

### Góc nhìn debug

Dump stack ngay sau create trước khi start scheduler; đây là test trắng đơn giản nhưng cực quan trọng.

---

## 2. Initial hardware frame

Kernel chuẩn bị các slot mà CPU sẽ hardware-pop khi exception return.

### xPSR

Set Thumb bit cần thiết; nếu xPSR sai, exception return có thể fault.

### PC

Trỏ task entry; cần alignment/address hợp lệ theo Thumb semantics.

### R0

Chứa `arg`, vì đây là first function argument theo AAPCS.

### LR

Trỏ explicit task-return trap thay vì giá trị rác.

```text
+----------------+
| xPSR           |
| PC = entry     |
| LR = exit_trap |
| R12            |
| R3             |
| R2             |
| R1             |
| R0 = arg       |
+----------------+
```

### Tại sao phần này quan trọng với RTOS?

Hardware return path chỉ biết frame này; kernel không thể sửa sau khi đã `BX EXC_RETURN`.

### Góc nhìn debug

So sánh từng word expected/actual trong Memory View.

---

## 3. Initial software frame và saved SP

R4-R11 được reserve dưới hardware frame. `tcb->saved_sp` trỏ đầu software frame để SVC/PendSV restore thống nhất.

### Debug pattern

Đặt pattern dễ nhận cho R4-R11 giúp kiểm restore bằng debugger.

### Alignment

Stack top phải align theo ABI trước khi dựng frame. Không dựa vào array address “có vẻ chia hết cho 4” rồi kết luận đủ.

### Boundary

Saved SP phải nằm trong region task stack; assert boundary có thể thêm sớm.

```text
high address
+----------------+
| hardware frame |
+----------------+
| R11 ... R4     |
+----------------+ <- saved_sp
low address
```

### Tại sao phần này quan trọng với RTOS?

Saved SP là contract xuyên task_create, SVC và PendSV.

### Góc nhìn debug

Kiểm `saved_sp % alignment`, stack low/high và exact slot mapping.

---

## 4. Mental Model tổng hợp

```text
caller provides stack[]
      |
      v
align stack_top
      |
      v
build hardware frame
  xPSR/PC/LR/R0...
      |
      v
build software frame
  R4-R11
      |
      v
tcb->saved_sp = frame bottom
      |
      v
task is READY but not yet running
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- Initial frame format tương thích PendSV/SVC restore.
- saved_sp aligned và nằm trong stack task.
- PC trỏ task entry hợp lệ; xPSR có Thumb state.
- Task return đi vào explicit trap.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Task chưa chạy nên chưa cần context”

Muốn restore task lần đầu thì phải có context giả.

### “LR có thể để 0”

Sẽ biến task return thành fault khó chẩn đoán.

### “Alignment chỉ liên quan performance”

ABI alignment có thể là correctness requirement.

---

## 7. Liên hệ trực tiếp với zRTOS

Kết thúc Phase 2, `zrtos_task_create_static()` phải tạo được TCB + stack frame hoàn chỉnh nhưng chưa cần chạy scheduler. Phase 3 chỉ việc chọn task và restore frame này qua SVC.

---

## 8. Tổng kết

- Task mới phải có artificial context cùng format task đã bị switch.
- xPSR/PC/R0/LR là bốn field initial hardware frame có semantics đặc biệt.
- Initial software frame hoàn thiện full context mà port restore được.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Tại sao initial task phải fake exception frame?
2. R0, PC, xPSR và LR được init thế nào?
3. saved_sp nên trỏ vào vị trí nào?
4. Tại sao task return trap quan trọng?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Bài trước](02-task-states-lifecycle.md) · [Phase Index →](README.md)
