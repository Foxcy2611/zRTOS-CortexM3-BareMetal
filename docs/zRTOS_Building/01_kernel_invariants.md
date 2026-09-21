# 01 — Kernel Invariants

Invariant là điều kiện phải luôn đúng nếu kernel đang ở trạng thái hợp lệ.

Các invariant dưới đây là contract thiết kế, không phải mô tả implementation tạm thời.

---

## Task invariants

### TASK-01 — Single running task

Tại một thời điểm chỉ có tối đa một task ở state `RUNNING`.

### TASK-02 — Idle availability

Idle task luôn có khả năng chạy và không được block.

### TASK-03 — No normal return

Task entry không được return bình thường. Nếu return, execution phải đi vào task-return trap.

### TASK-04 — Static lifetime

TCB và stack của task phải còn hợp lệ suốt lifetime của task.

---

## Ready-list invariants

### READY-01

Một task `READY` không phải current RUNNING task phải nằm đúng một ready list tương ứng với effective priority.

### READY-02

Task `BLOCKED` không được xuất hiện trong ready list.

### READY-03

Idle priority được reserve và không cấp cho user task.

---

## Blocking invariants

### BLOCK-01

Task bị block không được scheduler chọn.

### BLOCK-02

Một timed event wait có thể có:

- một event item trong wait list;
- một state item trong delayed list.

Nhưng completion chỉ được xảy ra đúng một lần.

### BLOCK-03

Event completion và timeout completion phải đi qua một completion path thống nhất hoặc behavior tương đương bảo đảm exactly-once wake.

---

## Context invariants

### CTX-01

Saved PSP của task phải đúng alignment yêu cầu của Cortex-M/AAPCS.

### CTX-02

Saved PSP phải nằm trong vùng stack của task.

### CTX-03

`tcb->sp` phải có layout/offset đúng với contract của assembly port.

### CTX-04

Task chạy Thread mode bằng PSP; exception handler chạy bằng MSP theo thiết kế v1.

### CTX-05

Chỉ có một strong definition cho mỗi core handler mà zRTOS sở hữu.

---

## Scheduler invariants

### SCHED-01

Scheduler luôn chọn READY task có effective priority cao nhất.

### SCHED-02

Các task cùng priority phải được phục vụ theo round-robin/FIFO policy đã định nghĩa.

### SCHED-03

Scheduler policy không phụ thuộc vào peripheral STM32.

---

## IPC invariants

### IPC-01

Semaphore count luôn trong khoảng `0..max_count`.

### IPC-02

Queue count luôn trong khoảng `0..capacity`.

### IPC-03

Mutex có tối đa một owner.

### IPC-04

Chỉ owner được unlock mutex.

### IPC-05

ISR API không được block.

---

## Priority inheritance invariants

### PI-01

`effective_priority >= base_priority` theo quy ước số priority lớn hơn là ưu tiên cao hơn.

### PI-02

Effective priority của mutex owner phải phản ánh waiter priority cao nhất cần thiết theo model v1.

### PI-03

Sau unlock hoặc waiter timeout, effective priority phải được tính lại từ base priority và các mutex còn giữ.

---

## Critical-section invariants

### CRIT-01

Mọi thay đổi trên shared kernel state giữa task/ISR phải được bảo vệ bởi critical section hoặc cơ chế đồng bộ tương đương.

### CRIT-02

Critical section phải restore interrupt mask về trạng thái trước khi enter.

### CRIT-03

Critical section phải ngắn; không gọi code ngoại vi hoặc thao tác blocking bên trong.
