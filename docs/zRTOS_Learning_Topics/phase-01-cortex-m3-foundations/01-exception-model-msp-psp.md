# Bài 1.1 — Exception Model, Thread/Handler Mode, MSP và PSP

> **Phạm vi:** Exception model của Cortex-M3, hardware exception frame, Thread/Handler Mode và hai stack pointer MSP/PSP.
>
> Chương này trình bày **lý thuyết, mental model và các invariant thiết kế**. Không cung cấp source zRTOS hoàn chỉnh để copy nguyên khối.
>
> **Giới hạn chủ đề:** Không đi sâu toàn bộ NVIC, exception priority encoding hoặc instruction set ARMv7-M ngoài phần cần cho RTOS.
>
> **Nguyên tắc bố cục:** `##` chỉ dành cho các khối kiến thức lớn; `###/####` dùng cho concept chi tiết. Mục tiêu là hiểu cơ chế trước, implementation sau.
>
> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-svc-exc-return.md)

---

## Mục lục

- [1. Thread Mode và Handler Mode](#1-thread-mode-và-handler-mode)
- [2. Hardware Exception Entry](#2-hardware-exception-entry)
- [3. MSP và PSP](#3-msp-và-psp)
- [4. Mental Model tổng hợp](#4-mental-model-tổng-hợp)
- [5. Các invariant cần giữ](#5-các-invariant-cần-giữ)
- [6. Các hiểu nhầm thường gặp](#6-các-hiểu-nhầm-thường-gặp)
- [7. Liên hệ trực tiếp với zRTOS](#7-liên-hệ-trực-tiếp-với-zrtos)
- [8. Tổng kết](#8-tổng-kết)
- [9. Câu hỏi tự kiểm tra](#9-câu-hỏi-tự-kiểm-tra)
- [10. Tài liệu tham khảo](#10-tài-liệu-tham-khảo)

---

## 1. Thread Mode và Handler Mode

Cortex-M3 không chạy mọi code trong cùng một execution mode. Sau reset, CPU chạy Thread Mode; khi exception hoặc interrupt xảy ra, CPU chuyển sang Handler Mode. Đây là separation đầu tiên cần hiểu trước khi viết RTOS vì task và handler không dùng cùng semantics stack/context.

### Thread Mode

Thread Mode là nơi code application hoặc task chạy. Thread Mode có thể dùng MSP hoặc PSP. zRTOS sẽ cố ý cho task chạy bằng PSP để mỗi task có stack riêng và TCB có thể quản lý saved stack pointer độc lập.

### Handler Mode

Handler Mode dùng khi xử lý SVC, PendSV, SysTick và peripheral IRQ. Trên Cortex-M3, Handler Mode dùng MSP. Nhờ vậy handler không cần dùng stack của task đang bị preempt.

### Tại sao phần này quan trọng với RTOS?

Context switching thực chất dựa trên việc CPU tự chuyển mode và tự stack một phần context trước khi handler code của zRTOS chạy.

### Góc nhìn debug

Khi break trong handler, đọc `IPSR`, `CONTROL`, `MSP`, `PSP`. Đừng chỉ nhìn PC; cần xác nhận CPU đang ở mode/stack nào.

---

## 2. Hardware Exception Entry

Exception entry không giống một `BL` function call. CPU tự thực hiện một chuỗi thao tác kiến trúc: chọn stack đang active, push một frame cố định, đổi mode và nạp vector handler.

### Hardware-saved registers

Frame chuẩn chứa `R0-R3`, `R12`, `LR`, `PC`, `xPSR`. Đây là phần context mà zRTOS **không cần save lại lần hai** trong PendSV.

### PC và xPSR

`PC` xác định nơi Thread context sẽ resume. `xPSR` giữ trạng thái CPU cần thiết; đặc biệt Thumb state phải hợp lệ. Initial task frame ở Phase 2 phải giả lập chính xác hai field này.

### LR trong frame và LR trong handler

LR được hardware stack là LR của code bị ngắt. LR mà handler đang nhìn thấy có thể là EXC_RETURN. Hai khái niệm cùng tên register nhưng đóng vai trò khác nhau ở hai thời điểm.

```text
high address
+-------+
| xPSR  |
| PC    |
| LR    |
| R12   |
| R3    |
| R2    |
| R1    |
| R0    |
+-------+ <- SP sau hardware stacking
low address
```

### Tại sao phần này quan trọng với RTOS?

Hardware frame chính là nửa đầu của full task context. Nếu không hiểu frame này, initial task stack và PendSV restore sẽ chỉ là copy assembly mù.

### Góc nhìn debug

Trong một lab exception, lấy stack pointer đã dùng lúc exception entry và đọc 8 word. So sánh stacked PC với disassembly để xác nhận mental model.

---

## 3. MSP và PSP

Cortex-M3 cung cấp hai stack pointer vật lý: Main Stack Pointer và Process Stack Pointer. Đây không phải hai biến C mà là hai register stack riêng.

### MSP

MSP được nạp từ vector table sau reset và là stack mặc định. Handler Mode luôn sử dụng MSP, nên zRTOS dành MSP cho exception/interrupt/kernel handler stack.

### PSP

PSP có thể được Thread Mode dùng. zRTOS gán PSP cho task để mỗi task có thể sở hữu stack độc lập; saved PSP của task được lưu trong TCB khi task không chạy.

### Tại sao không để task dùng MSP

Nếu task và handler chia sẻ MSP, task stack ownership và context switch khó reason hơn. Dùng PSP làm task context rõ ràng: `TCB -> saved PSP -> task stack`.

### Tại sao phần này quan trọng với RTOS?

Việc phân tách MSP/PSP cho phép kernel save/restore task bằng cách đổi PSP trong khi exception stack của handler vẫn ổn định.

### Góc nhìn debug

Quan sát MSP trước và trong handler; quan sát PSP khi task chạy. Nếu PSP ngoài vùng stack task, đó là lỗi context nghiêm trọng.

---

## 4. Mental Model tổng hợp

```text
Task chạy Thread Mode bằng PSP
        |
        | exception entry
        v
CPU push R0-R3,R12,LR,PC,xPSR lên PSP
        |
        v
CPU chuyển Handler Mode
Handler chạy bằng MSP
        |
        | handler/RTOS xử lý
        v
exception return
        |
        v
CPU pop hardware frame
        |
        v
Thread Mode tiếp tục bằng PSP
```

Mental model này nên được dùng như một sơ đồ suy nghĩ khi đọc source hoặc debug. Nếu hành vi thực tế không khớp mô hình, hãy xác định layer đang phá contract thay vì sửa ngẫu nhiên ở application.

---

## 5. Các invariant cần giữ

- Handler Mode dùng MSP; task zRTOS chạy Thread Mode bằng PSP.
- Hardware exception frame là một phần task context và không được save trùng tùy tiện.
- PSP của task phải luôn nằm trong vùng stack do task sở hữu.
- Initial task frame về sau phải có layout tương thích exception-return hardware.

Invariant là **design contract có thể kiểm tra được**, không chỉ là ghi chú. Về sau nhiều invariant trong các chapter này sẽ trở thành `ZRTOS_ASSERT()` hoặc regression test.

---

## 6. Các hiểu nhầm thường gặp

### “Exception chỉ là function call do hardware gọi”

Sai mental model. Exception có hardware stacking, mode transition và exception return semantics riêng.

### “PSP thay thế MSP khi bật RTOS”

Không. PSP dành cho Thread Mode task; MSP vẫn phục vụ handler.

### “PendSV phải save cả R0-R3”

Cortex-M3 đã stack nhóm đó khi exception entry.

---

## 7. Liên hệ trực tiếp với zRTOS

Các phase sau dùng trực tiếp contract:

```text
task context
 = hardware frame do Cortex-M3 định nghĩa
 + R4-R11 do zRTOS save
 + PSP được lưu trong TCB
```

Phase 2 sẽ dựng một frame giả cho task mới. Phase 3 dùng SVC để restore frame đó. Phase 4 dùng PendSV save/restore cùng format cho task đã chạy.

---

## 8. Tổng kết

- Task và exception handler là hai execution context khác nhau; zRTOS dựa vào sự tách biệt Thread/Handler Mode.
- Cortex-M3 tự lưu hardware frame gồm 8 word; đây là phần context bắt buộc của mọi task bị exception ngắt.
- zRTOS dùng PSP cho task và MSP cho handler; TCB saved SP thực chất đại diện PSP của task.
- Mental model và invariant của chapter quan trọng hơn việc nhớ tên API.
- Nếu một implementation chạy được nhưng phá invariant, đó vẫn là implementation sai.

---

## 9. Câu hỏi tự kiểm tra

1. Thread Mode và Handler Mode khác nhau ở đâu đối với RTOS?
2. Hardware tự push những register nào khi exception entry?
3. Tại sao zRTOS chọn PSP cho task?
4. LR trong hardware frame và LR trong handler có thể mang ý nghĩa khác nhau thế nào?

> Nếu chưa trả lời được các câu trên bằng lời của mình mà không nhìn source, nên đọc lại chapter trước khi sang bài tiếp theo.

---

## 10. Tài liệu tham khảo

- Armv7-M Architecture Reference Manual.
- ARM Cortex-M3 Devices Generic User Guide.
- CMSIS-Core documentation.

---

> **Điều hướng:** [← Phase Index](README.md) · [Bài tiếp →](02-svc-exc-return.md)
